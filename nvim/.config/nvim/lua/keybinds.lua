local map = vim.keymap.set
local group = require("which-key").add
local notify = require("notify")

local function on_hover(callback)
	vim.api.nvim_create_autocmd("CursorHold", {
		callback = callback,
	})
end

local function with_cmp(fn)
	return function(fallback)
		local ok, cmp = pcall(require, "cmp")
		if ok and cmp.visible() then
			fn(cmp, fallback)
		elseif fallback then
			fallback()
		end
	end
end

-- ###############
-- ### Default ###
-- ###############
map("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
map("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
map("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
map("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')
-- Bind Esc to: Close floating windows/neo-tree, or turn off highlighting, or close file tree
map("n", "<Esc>", function()
	local closed_float = false
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_config(win).relative ~= "" then
			vim.api.nvim_win_close(win, false)
			closed_float = true
		end
	end
	if closed_float then
		return
	end

	vim.cmd("nohlsearch")
	vim.cmd(":DiffviewClose")
end, { noremap = true, silent = true })

map("n", "<leader><leader>x", "<cmd>source %<CR>", { desc = "Execute the current file" })
map("n", "<leader>?", "<cmd>:Telescope keymaps<CR>", { desc = "Show keymaps" })
map("n", "<leader>q", "<cmd>:wqa<CR>", { desc = "Quits vim" })

-- ###############
-- ### Windows ###
-- ###############
map("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
map("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
map("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
map("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

-- ###########
-- ### Git ###
-- ###########
group({ "<leader>g", group = "Git" })
local function toggle_stash()
	local stash_list = vim.fn.systemlist("git stash list")
	local exit_code = vim.v.shell_error
	if exit_code ~= 0 then
		notify("Not a git repo", vim.log.levels.ERROR)
		return
	end
	if #stash_list > 0 then
		local out = vim.fn.system("git stash pop")
	else
		local out = vim.fn.system("git stash")
		if out:match("No local changes") then
			notify("Nothing to stash", vim.log.levels.WARN)
		end
	end
end
map("n", "<leader>gs", toggle_stash, { desc = "Toggle git stash" })
map("n", "<leader>gd", function()
	if next(require("diffview.lib").views) ~= nil then
		vim.cmd("DiffviewClose")
		return
	end
	vim.ui.input({ prompt = "Commits back ([o]rigin or #): " }, function(x)
		if not x or x == "" then
			return
		end
		local cmp = ""
		if x:lower() == "o" then
			cmp = vim.fn.system("git rev-parse --abbrev-ref --symbolic-full-name @{u}"):gsub("\n", "")
		else
			local n = tonumber(x)
			if not n or n < 1 then
				return
			end
			cmp = "HEAD~" .. n
		end
		if cmp == "" or cmp:match("^fatal") then
			return
		end
		vim.cmd("DiffviewOpen " .. cmp)
	end)
end, { desc = "View diff vs ..." })

-- #################
-- ### Lazy nvim ###
-- #################
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- #################
-- ### Telescope ###
-- #################
local telescope = require("telescope.builtin")

group({ "<leader>f", group = "Telescope" })
map("n", "<leader>ff", telescope.find_files, { desc = "Telescope find files" })
map("n", "<leader>fg", telescope.live_grep, { desc = "Telescope live grep" })
map("n", "<leader>fb", telescope.buffers, { desc = "Telescope buffers" })
map("n", "<leader>fm", telescope.marks, { desc = "Telescope marks" })
map("n", "<leader>fh", telescope.help_tags, { desc = "Telescope help tags" })

-- ###############
-- ### Conform ###
-- ###############
local formatter = require("conform")
group({ "<leader>c", group = "Code actions" })
map("n", "<leader>cf", formatter.format, { desc = "Format document" })
map("n", "<leader>ca", function()
	require("actions-preview").code_actions()
end, { desc = "Code action" })

map("n", "ga", vim.lsp.buf.references, { desc = "Go to references" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
map("n", "gp", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gP", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gr", "<cmd>Telescope lsp_references<CR>", { desc = "Go to references" })
map("n", "gt", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
map("n", "U", vim.lsp.buf.hover, { desc = "Hover documentation" })

map("n", "<leader>r", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Type definition" })
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
on_hover(function()
	vim.diagnostic.open_float(nil, {
		focusable = false,
		close_events = { "BufLeave", "CursorMoved", "InsertEnter" },
		border = "rounded",
		source = "always",
		prefix = " ",
		scope = "cursor",
	})
end)

-- ################
-- ### nvim-cmp ###
-- ################
local cmp = require("cmp")
map("i", "<C-b>", function()
	cmp.scroll_docs(-4)
end, { desc = "Scroll docs up" })
map("i", "<C-f>", function()
	cmp.scroll_docs(4)
end, { desc = "Scroll docs down" })
map("i", "<C-n>", function()
	cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
end, { desc = "Next completion item" })
map(
	"i",
	"<C-p>",
	with_cmp(function(cmp)
		cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
	end),
	{ desc = "Prev completion item" }
)
map("i", "<C-Space>", function()
	cmp.mapping.complete()
end, { desc = "Trigger completion" })
map("i", "<C-Tab>", function()
	cmp.confirm({ select = "auto_select" })
end, { desc = "Confirm (auto-select)" })
map("i", "<S-Tab>", function()
	cmp.confirm({ behavior = require("cmp").ConfirmBehavior.Replace })
end, { desc = "Confirm (replace)" })
map("i", "<C-CR>", function()
	cmp.abort()
end, { desc = "Abort completion" })

-- ################
-- ### Snippets ###
-- ################
local ls = require("luasnip")
map({ "i", "s" }, "<c-k>", function()
	if ls.expand_or_jumpable() then
		ls.expand_or_jump()
	end
end, { silent = true })
map({ "i", "s" }, "<c-j>", function()
	if ls.expand_or_jumpable(-1) then
		ls.expand_or_jump(-1)
	end
end, { silent = true })

-- ############
-- ### yazi ###
-- ############
map("n", "<leader>b", "<cmd>Yazi cwd<cr>", { desc = "Toggle yazi" })

-- ##################
-- ### Treesitter ###
-- ##################
local ts_select = function(target)
	return function()
		require("nvim-treesitter-textobjects.select").select_textobject(target, "textobjects")
	end
end

local ts_move = function(method, target)
	return function()
		require("nvim-treesitter-textobjects.move")[method](target, "textobjects")
	end
end

map({ "x", "o" }, "af", ts_select("@function.outer"), { desc = "Function" })
map({ "x", "o" }, "if", ts_select("@function.inner"), { desc = "Inner Function" })
map({ "x", "o" }, "ac", ts_select("@class.outer"), { desc = "Class" })
map({ "x", "o" }, "ic", ts_select("@class.inner"), { desc = "Inner Class" })
map({ "x", "o" }, "aa", ts_select("@parameter.outer"), { desc = "Argument" })
map({ "x", "o" }, "ia", ts_select("@parameter.inner"), { desc = "Inner Argument" })

map({ "n", "x", "o", "v" }, "]m", ts_move("goto_next_start", "@function.outer"))
map({ "n", "x", "o", "v" }, "]M", ts_move("goto_next_end", "@function.outer"))
map({ "n", "x", "o", "v" }, "[m", ts_move("goto_previous_start", "@function.outer"))
map({ "n", "x", "o", "v" }, "[M", ts_move("goto_previous_end", "@function.outer"))
map({ "n", "x", "o", "v" }, "]]", ts_move("goto_next_start", "@class.outer"))
map({ "n", "x", "o", "v" }, "[[", ts_move("goto_previous_start", "@class.outer"))

-- ##################
-- ### Treewalker ###
-- ##################
map({ "n", "x", "o", "v" }, "<S-k>", "<cmd>Treewalker Up<cr>", { silent = true })
map({ "n", "x", "o", "v" }, "<S-j>", "<cmd>Treewalker Down<cr>", { silent = true })
map({ "n", "x", "o", "v" }, "<S-h>", "<cmd>Treewalker Left<cr>", { silent = true })
map({ "n", "x", "o", "v" }, "<S-l>", "<cmd>Treewalker Right<cr>", { silent = true })

-- #################
-- ### Debugging ###
-- #################
local dap = require("dap")
group({ "<leader>d", group = "Debugging" })
map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
map("n", "<leader>dt", dap.run_to_cursor, { desc = "Run to cursor" })

-- Eval under cursor (and pull up dapui)
map("n", "<leader>d?", function()
	require("dapui").eval(nil, { enter = true })
end, { desc = "Eval current line" })
map("n", "<F1>", dap.continue)
map("n", "<F2>", dap.step_into)
map("n", "<F3>", dap.step_over)
map("n", "<F4>", dap.step_out)
map("n", "<F5>", dap.step_back)
map("n", "<F12>", dap.restart)
