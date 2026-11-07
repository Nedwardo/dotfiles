-- Inline hover: renders diagnostics + LSP documentation inside a bounding box
-- drawn from virtual lines below the cursor line, instead of a floating window.
--
-- Why: floating windows are drawn *over* the buffer, so hover docs hide the code
-- (and the diagnostic virtual text) underneath them. Virtual lines are part of
-- the buffer's layout, so the surrounding text is pushed down to make room and
-- nothing is ever covered. Diagnostics are rendered first (and immediately,
-- before the async LSP response arrives) so an error message can never end up
-- behind a docstring.
--
-- The documentation keeps the colouring a hover float had: the markdown is
-- highlighted with treesitter (including the languages injected into fenced code
-- blocks) and each highlight span becomes a virt_line chunk.

local M = {}

local ns = vim.api.nvim_create_namespace("inline_hover")
local extmark_id = 1

local BORDER_HL = "InlineHoverBorder"
local BOX = {
	top_left = "╭",
	top_right = "╮",
	bottom_left = "╰",
	bottom_right = "╯",
	div_left = "├",
	div_right = "┤",
	horizontal = "─",
	vertical = "│",
}
local PAD = 1 -- spaces between the box edges and the content

local function define_highlights()
	-- `FloatBorder` is what the hover float used, so the box matches it.
	vim.api.nvim_set_hl(0, BORDER_HL, { link = "FloatBorder", default = true })
end

--- Rendered state. `token` invalidates in-flight LSP responses.
local state = {
	bufnr = nil, ---@type integer?
	lnum = nil, ---@type integer? 0-indexed line carrying the extmark
	code_win = nil, ---@type integer? window the box was drawn in
	body = nil, ---@type table[]? full (uncapped) chunk lines behind the box
	inner = 0, ---@type integer inner width of the drawn box
	rows = 0, ---@type integer interior height of the drawn box
	docs_win = nil, ---@type integer? scrollable window covering the box interior
	transition = false, ---@type boolean opening/closing `docs_win` right now
	token = 0,
	cancel = nil, ---@type function?
}

---@param bufnr integer?
local function clear_buf(bufnr)
	if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	end
end

--- Close the scrollable documentation window, leaving the box in place.
function M.unfocus()
	local win = state.docs_win
	state.docs_win = nil
	if not (win and vim.api.nvim_win_is_valid(win)) then
		return
	end
	-- Closing it fires WinLeave/BufLeave/WinClosed; none of them may clear the box.
	state.transition = true
	pcall(vim.api.nvim_win_close, win, true)
	vim.schedule(function()
		state.transition = false
	end)
end

--- Remove any rendered hover and invalidate pending requests.
function M.clear()
	state.token = state.token + 1
	if state.cancel then
		pcall(state.cancel)
		state.cancel = nil
	end
	M.unfocus()
	clear_buf(state.bufnr)
	state.bufnr = nil
	state.lnum = nil
	state.code_win = nil
	state.body = nil
end

function M.is_visible()
	return state.bufnr ~= nil
end

function M.is_focused()
	return state.transition or (state.docs_win ~= nil and vim.api.nvim_win_is_valid(state.docs_win))
end

-- ### Chunk helpers ###
--
-- A "chunk line" is a list of `{ text, highlight }` pairs, i.e. exactly one
-- entry of a `virt_lines` extmark.

local DIVIDER = {}

---@param chunks table[]
---@return integer
local function chunk_width(chunks)
	local width = 0
	for _, chunk in ipairs(chunks) do
		width = width + vim.fn.strdisplaywidth(chunk[1])
	end
	return width
end

--- Merge neighbouring chunks that share a highlight, so a wrapped line does not
--- explode into one chunk per word.
---@param chunks table[]
---@return table[]
local function coalesce(chunks)
	local out = {}
	for _, chunk in ipairs(chunks) do
		local last = out[#out]
		if last and last[2] == chunk[2] then
			last[1] = last[1] .. chunk[1]
		else
			out[#out + 1] = { chunk[1], chunk[2] }
		end
	end
	return out
end

---@param word string
---@param width integer
---@return string[]
local function hard_split(word, width)
	local parts = {}
	local len = vim.fn.strchars(word)
	local i = 0
	while i < len do
		parts[#parts + 1] = vim.fn.strcharpart(word, i, width)
		i = i + width
	end
	return parts
end

--- Word-wrap a chunk line to `width`, preserving highlights and the line's
--- leading indentation on continuation lines. virt_lines never soft-wrap, so
--- anything wider than the window would simply be cut off.
---@param chunks table[]
---@param width integer
---@return table[][]
local function wrap_chunks(chunks, width)
	if chunk_width(chunks) <= width then
		return { chunks }
	end

	local indent = (chunks[1] and chunks[1][1]:match("^[ \t]*")) or ""
	local indent_width = vim.fn.strdisplaywidth(indent)
	local body_width = math.max(8, width - indent_width)

	---@type table[] { text, hl, is_space }
	local tokens = {}
	for _, chunk in ipairs(chunks) do
		for word, space in chunk[1]:gmatch("([^ \t]*)([ \t]*)") do
			if word ~= "" then
				local pieces = vim.fn.strdisplaywidth(word) > body_width and hard_split(word, body_width) or { word }
				for _, piece in ipairs(pieces) do
					tokens[#tokens + 1] = { piece, chunk[2], false }
				end
			end
			if space ~= "" then
				tokens[#tokens + 1] = { space, chunk[2], true }
			end
		end
	end

	local out, current, current_width = {}, {}, 0
	local function flush()
		while #current > 0 and current[#current][3] do
			table.remove(current)
		end
		if #current == 0 then
			return
		end
		if #out > 0 and indent ~= "" then
			table.insert(current, 1, { indent, current[1][2] })
		end
		out[#out + 1] = coalesce(current)
		current, current_width = {}, 0
	end

	for _, token in ipairs(tokens) do
		local token_width = vim.fn.strdisplaywidth(token[1])
		if #current == 0 and token[3] and #out > 0 then
			-- drop whitespace that would open a continuation line
		elseif not token[3] and #current > 0 and current_width + token_width > width then
			flush()
			current[1], current_width = token, indent_width + token_width
		else
			current[#current + 1] = token
			current_width = current_width + token_width
		end
	end
	flush()

	return out
end

-- ### Diagnostics ###

local SEVERITY_LABEL = {
	-- `DiagnosticFloating*` is what `vim.diagnostic.open_float` used.
	[vim.diagnostic.severity.ERROR] = { "Error", "DiagnosticFloatingError" },
	[vim.diagnostic.severity.WARN] = { "Warn", "DiagnosticFloatingWarn" },
	[vim.diagnostic.severity.INFO] = { "Info", "DiagnosticFloatingInfo" },
	[vim.diagnostic.severity.HINT] = { "Hint", "DiagnosticFloatingHint" },
}

--- Chunk lines for every diagnostic on `lnum`, most severe first so an error is
--- always the first thing you read.
---@param bufnr integer
---@param lnum integer 0-indexed
---@return table[][]
local function diagnostic_lines(bufnr, lnum)
	local out = {}
	local diagnostics = vim.diagnostic.get(bufnr, { lnum = lnum })
	table.sort(diagnostics, function(a, b)
		if a.severity ~= b.severity then
			return a.severity < b.severity
		end
		return (a.col or 0) < (b.col or 0)
	end)
	for _, d in ipairs(diagnostics) do
		local label, hl = unpack(SEVERITY_LABEL[d.severity] or SEVERITY_LABEL[vim.diagnostic.severity.ERROR])
		local message = d.message:gsub("\r", "")
		if d.source and d.source ~= "" then
			message = message .. " [" .. d.source .. "]"
		end
		local first = true
		for _, line in ipairs(vim.split(message, "\n", { trimempty = true })) do
			out[#out + 1] = { { (first and (label .. ": ") or "  ") .. line, hl } }
			first = false
		end
	end
	return out
end

-- ### Documentation ###

--- Drop `\r`, trim surrounding blank lines and collapse blank runs. Line
--- structure is otherwise untouched: treesitter is run on the result, so the
--- offsets have to keep matching.
---@param lines string[]
---@return string[]
local function normalize(lines)
	local out = {}
	for _, raw in ipairs(lines) do
		for _, line in ipairs(vim.split(raw:gsub("\r", ""), "\n")) do
			local blank = line:match("^%s*$") ~= nil
			if not (blank and (#out == 0 or out[#out]:match("^%s*$"))) then
				out[#out + 1] = blank and "" or line
			end
		end
	end
	while #out > 0 and out[#out] == "" do
		out[#out] = nil
	end
	return out
end

--- Highlight groups with no attributes of their own (`@spell`, `@nospell`,
--- `@conceal`, …) are semantic markers. The real highlighter stacks extmarks, so
--- they let the group underneath show through; we overwrite spans instead, so
--- they have to be skipped to keep the colour underneath.
---@type table<string, boolean>
local visible_group = setmetatable({}, {
	__index = function(cache, group)
		local attrs = vim.api.nvim_get_hl(0, { name = group, link = false })
		local visible = next(attrs) ~= nil
		cache[group] = visible
		return visible
	end,
})

--- Treesitter highlight spans for `lines`: `hl[row][byte] = group` and the
--- conceal replacements the markdown query asks for, both 0-indexed. Mirrors
--- `vim.treesitter.highlighter`: `_`-prefixed captures are internal, a capture
--- resolves to `@<capture>.<lang>` (falling back to `@<capture>`), and
--- `conceal` metadata replaces the captured text — the float got that from
--- `conceallevel = 2`, virtual lines have to do it by hand.
---@param lines string[]
---@return table<integer, table<integer, string>> hl
---@return table<integer, table<integer, string|true>> conceal
local function treesitter_highlights(lines)
	local hl, conceal = {}, {}
	local text = table.concat(lines, "\n")
	local ok, parser = pcall(vim.treesitter.get_string_parser, text, "markdown")
	if not ok or not parser then
		return hl, conceal
	end

	parser:parse(true)
	-- Pre-order traversal: injected languages come after their parent, so their
	-- spans correctly overwrite the markdown ones.
	parser:for_each_tree(function(tstree, tree)
		local lang = tree:lang()
		local query = vim.treesitter.query.get(lang, "highlights")
		if not query then
			return
		end
		for id, node, metadata in query:iter_captures(tstree:root(), text) do
			local name = query.captures[id]
			local group = "@" .. name .. "." .. lang
			local hidden = metadata.conceal or (metadata[id] and metadata[id].conceal)
			if not vim.startswith(name, "_") and (hidden or visible_group[group]) then
				local srow, scol, erow, ecol = node:range()
				for row = srow, math.min(erow, #lines - 1) do
					local row_hl = hl[row] or {}
					hl[row] = row_hl
					local from = row == srow and scol or 0
					local to = row == erow and ecol - 1 or #lines[row + 1] - 1
					if hidden then
						local row_conceal = conceal[row] or {}
						conceal[row] = row_conceal
						for byte = from, to do
							row_conceal[byte] = true
						end
						-- Replacement text (usually "") is emitted once, at the start.
						row_conceal[from] = row == srow and hidden or true
					else
						for byte = from, to do
							row_hl[byte] = group
						end
					end
				end
			end
		end
	end)

	return hl, conceal
end

--- Split one line into chunks along its highlight spans, dropping concealed text.
---@param line string
---@param row_hl table<integer, string>?
---@param row_conceal table<integer, string|true>?
---@return table[]
local function highlighted_chunks(line, row_hl, row_conceal)
	if #line == 0 then
		return {}
	end
	if not row_hl and not row_conceal then
		return { { line } }
	end
	row_hl = row_hl or {}
	local chunks = {}
	local byte = 0
	while byte < #line do
		local hidden = row_conceal and row_conceal[byte]
		if hidden then
			if type(hidden) == "string" and hidden ~= "" then
				chunks[#chunks + 1] = { hidden, row_hl[byte] }
			end
			repeat
				byte = byte + 1
			until byte >= #line or not (row_conceal and row_conceal[byte])
		else
			local group = row_hl[byte]
			local stop = byte + 1
			while stop < #line and row_hl[stop] == group and not (row_conceal and row_conceal[stop]) do
				stop = stop + 1
			end
			chunks[#chunks + 1] = { line:sub(byte + 1, stop), group }
			byte = stop
		end
	end
	return chunks
end

--- Markdown -> chunk lines. Fence delimiters are parsed (they drive the language
--- injection) but not rendered, matching the float's concealed backticks.
---@param markdown string[]
---@return table[][]
local function doc_lines(markdown)
	local lines = normalize(markdown)
	if #lines == 0 then
		return {}
	end

	local hl, conceal = treesitter_highlights(lines)
	local out = {}
	for row, line in ipairs(lines) do
		if not line:match("^%s*```") then
			out[#out + 1] = highlighted_chunks(line, hl[row - 1], conceal[row - 1])
		end
	end
	while #out > 0 and #out[#out] == 0 do
		out[#out] = nil
	end
	return out
end

-- ### Box ###

--- Usable text width of `win`, excluding number/sign columns and the box edges.
---@param win integer
---@param max_width integer
---@return integer
local function content_width(win, max_width)
	local info = vim.fn.getwininfo(win)[1]
	local avail = info and (info.width - info.textoff) or vim.api.nvim_win_get_width(win)
	return math.max(20, math.min(avail - 2 * (1 + PAD) - 1, max_width))
end

--- Frame chunk lines (and `DIVIDER` markers) in a bounding box.
---@param body table[]
---@param width integer
---@return table[][] virt_lines
---@return integer inner inner width of the box
local function draw_box(body, width)
	local inner = 0
	for _, line in ipairs(body) do
		if line ~= DIVIDER then
			inner = math.max(inner, chunk_width(line))
		end
	end
	inner = math.min(inner, width)

	local rule = string.rep(BOX.horizontal, inner + 2 * PAD)
	local pad = string.rep(" ", PAD)
	local out = { { { BOX.top_left .. rule .. BOX.top_right, BORDER_HL } } }

	for _, line in ipairs(body) do
		if line == DIVIDER then
			out[#out + 1] = { { BOX.div_left .. rule .. BOX.div_right, BORDER_HL } }
		else
			local framed = { { BOX.vertical .. pad, BORDER_HL } }
			vim.list_extend(framed, line)
			local fill = string.rep(" ", math.max(0, inner - chunk_width(line)))
			framed[#framed + 1] = { fill .. pad .. BOX.vertical, BORDER_HL }
			out[#out + 1] = framed
		end
	end

	out[#out + 1] = { { BOX.bottom_left .. rule .. BOX.bottom_right, BORDER_HL } }
	return out, inner
end

-- ### Rendering ###

---@param bufnr integer
---@param lnum integer
---@param virt_lines table[][]
local function render(bufnr, lnum, virt_lines)
	if not vim.api.nvim_buf_is_valid(bufnr) or lnum >= vim.api.nvim_buf_line_count(bufnr) then
		return
	end
	if #virt_lines == 0 then
		clear_buf(bufnr)
		state.bufnr = nil
		state.lnum = nil
		return
	end
	state.bufnr = bufnr
	state.lnum = lnum
	vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
		id = extmark_id,
		virt_lines = virt_lines,
		virt_lines_above = false,
	})
end

--- Draw `body` as a box and remember what is needed to enter it later.
---@param bufnr integer
---@param lnum integer
---@param body table[] full body; only the first `max_rows` lines are drawn
---@param width integer
---@param max_rows integer
local function render_box(bufnr, lnum, body, width, max_rows)
	local drawn = body
	if #body > max_rows then
		drawn = vim.list_slice(body, 1, max_rows - 1)
		drawn[#drawn + 1] = { { "…", BORDER_HL } }
	end
	local virt_lines, inner = draw_box(drawn, width)
	state.body = body
	state.inner = inner
	state.rows = #drawn
	state.code_win = vim.api.nvim_get_current_win()
	render(bufnr, lnum, virt_lines)
end

--- Wrap every chunk line to `width`.
---@param body table[][]
---@param width integer
---@return table[][]
local function wrap_all(body, width)
	local out = {}
	for _, line in ipairs(body) do
		if #line == 0 then
			out[#out + 1] = line
		else
			vim.list_extend(out, wrap_chunks(line, width))
		end
	end
	return out
end

-- ### Focus ###

local docs_ns = vim.api.nvim_create_namespace("inline_hover_docs")

--- Fill `buf` with the box body as real text plus matching highlights.
---@param buf integer
---@param body table[]
---@param inner integer
local function fill_docs_buf(buf, body, inner)
	local lines, spans = {}, {}
	for i, line in ipairs(body) do
		if line == DIVIDER then
			lines[i] = string.rep(BOX.horizontal, inner)
			spans[i] = { { 0, -1, BORDER_HL } }
		else
			local text, col, row_spans = "", 0, {}
			for _, chunk in ipairs(line) do
				local stop = col + #chunk[1]
				if chunk[2] then
					row_spans[#row_spans + 1] = { col, stop, chunk[2] }
				end
				text = text .. chunk[1]
				col = stop
			end
			lines[i] = text
			spans[i] = row_spans
		end
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	for row, row_spans in pairs(spans) do
		for _, span in ipairs(row_spans) do
			vim.api.nvim_buf_set_extmark(buf, docs_ns, row - 1, span[1], {
				end_col = span[2] < 0 and #lines[row] or span[2],
				hl_group = span[3],
			})
		end
	end
	vim.bo[buf].modifiable = false
end

--- Enter the box: open a scrollable window over its interior. The virtual lines
--- already reserve that screen space, so this window covers nothing but the box
--- it is drawn inside, and it holds the *uncapped* documentation.
---@return boolean entered
function M.focus()
	if state.docs_win and vim.api.nvim_win_is_valid(state.docs_win) then
		vim.api.nvim_set_current_win(state.docs_win)
		return true
	end
	local body = state.body
	if state.transition or not M.is_visible() or not body or #body == 0 then
		return false
	end
	local code_win = state.code_win
	if not (code_win and vim.api.nvim_win_is_valid(code_win)) then
		return false
	end

	-- Screen position of the boxed line. Explicit coordinates rather than
	-- `bufpos`, which is only resolved on the redraw *after* the window opens.
	local pos = vim.fn.screenpos(code_win, state.lnum + 1, 1)
	local info = vim.fn.getwininfo(code_win)[1]
	if pos.row == 0 or not info then
		return false -- the line is scrolled out of view
	end
	-- Never taller than the reserved interior, nor than the rows left on screen.
	local rows_below = info.winrow + info.height - 1 - pos.row
	local height = math.min(state.rows, rows_below - 1)
	if height < 1 then
		return false
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	fill_docs_buf(buf, body, state.inner)

	-- Entering the new window fires WinLeave/BufLeave for the code window before
	-- `docs_win` is set, which would tear down the box we are entering.
	state.transition = true
	local ok, win = pcall(vim.api.nvim_open_win, buf, true, {
		relative = "editor",
		row = pos.row - 1 + 2, -- 0-indexed, skipping the code line and top border
		col = pos.col - 1 + 1 + PAD, -- skipping the box's left edge and padding
		width = state.inner,
		height = height,
		style = "minimal",
		zindex = 60,
	})
	state.transition = false
	if not ok then
		vim.api.nvim_buf_delete(buf, { force = true })
		return false
	end
	state.docs_win = win

	-- Blend into the box interior, but make it obvious the cursor is in here.
	vim.wo[win].winhighlight = "Normal:Normal,CursorLine:CursorLine"
	vim.wo[win].cursorline = true
	vim.wo[win].wrap = false -- content is already wrapped
	vim.wo[win].scrolloff = 0 -- the global scrolloff is half a screen
	vim.wo[win].sidescrolloff = 0
	vim.wo[win].foldenable = false

	for _, lhs in ipairs({ "q", "<Esc>", "<C-c>" }) do
		vim.keymap.set("n", lhs, M.unfocus, { buffer = buf, nowait = true, silent = true })
	end
	vim.api.nvim_create_autocmd({ "WinLeave", "WinClosed" }, {
		buffer = buf,
		once = true,
		callback = function()
			vim.schedule(M.unfocus)
		end,
	})

	return true
end

---@class InlineHoverOpts
---@field max_width? integer
---@field max_height? integer maximum documentation lines drawn (scroll for the rest)
---@field docs? boolean request LSP documentation (default true)

--- Render diagnostics for the cursor line plus LSP hover docs, boxed, as virtual
--- lines below the cursor line.
---@param opts? InlineHoverOpts
function M.show(opts)
	if M.is_focused() then
		return -- the cursor is inside the documentation window
	end
	opts = opts or {}
	local win = vim.api.nvim_get_current_win()
	local bufnr = vim.api.nvim_win_get_buf(win)
	local lnum = vim.api.nvim_win_get_cursor(win)[1] - 1

	M.clear()
	local token = state.token
	local width = content_width(win, opts.max_width or 100)
	local max_height = opts.max_height or 20

	local diagnostics = wrap_all(diagnostic_lines(bufnr, lnum), width)
	if #diagnostics > 0 then
		render_box(bufnr, lnum, diagnostics, width, #diagnostics)
	end

	if opts.docs == false then
		return
	end
	if not next(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" })) then
		return
	end

	state.cancel = vim.lsp.buf_request_all(bufnr, "textDocument/hover", function(client)
		return vim.lsp.util.make_position_params(win, client.offset_encoding)
	end, function(results)
		if token ~= state.token then
			return -- cursor moved / cleared while the request was in flight
		end
		state.cancel = nil

		local markdown = {}
		for _, result in pairs(results) do
			local contents = result.result and result.result.contents
			if contents then
				vim.lsp.util.convert_input_to_markdown_lines(contents, markdown)
			end
		end

		local docs = wrap_all(doc_lines(markdown), width)
		if #docs == 0 then
			return -- keep the diagnostics-only box
		end

		local body = vim.deepcopy(diagnostics)
		if #body > 0 then
			body[#body + 1] = DIVIDER
		end
		vim.list_extend(body, docs)
		render_box(bufnr, lnum, body, width, #body - #docs + max_height)
	end)
end

--- Hover key: show the box, then enter it when pressed again — the same
--- show/focus rhythm `vim.lsp.buf.hover` has.
---@param opts? InlineHoverOpts
function M.hover(opts)
	if M.is_visible() then
		if M.focus() then
			return
		end
	end
	M.show(opts)
end

--- Autocmds: keep the box alive while the cursor stays on its line.
function M.setup()
	define_highlights()
	local augroup = vim.api.nvim_create_augroup("InlineHover", { clear = true })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = augroup,
		callback = function()
			define_highlights()
			for group in pairs(visible_group) do
				visible_group[group] = nil
			end
		end,
	})

	vim.api.nvim_create_autocmd("CursorMoved", {
		group = augroup,
		callback = function()
			if not M.is_visible() or M.is_focused() then
				return
			end
			-- `vim.diagnostic.jump` moves the cursor and then renders, so a
			-- trailing CursorMoved must not wipe a box for the current line.
			if state.bufnr ~= vim.api.nvim_get_current_buf() then
				M.clear()
			elseif vim.api.nvim_win_get_cursor(0)[1] - 1 ~= state.lnum then
				M.clear()
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "WinLeave", "TextChanged" }, {
		group = augroup,
		callback = function()
			-- Entering the documentation window leaves the code window; that must
			-- not tear down the box the window is drawn inside.
			if M.is_focused() then
				return
			end
			M.clear()
		end,
	})
end

return M
