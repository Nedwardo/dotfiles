local map = vim.keymap.set
local group = require("which-key").add

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
map("n", "<Esc>", "<cmd>nohl<CR>")

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
map("n", "gp", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gP", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "ga", vim.lsp.buf.references, { desc = "Go to references" })

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
map("n", "<leader>fh", telescope.help_tags, { desc = "Telescope help tags" })

-- ###############
-- ### Conform ###
-- ###############
local formatter = require("conform")
group({ "<leader>c", group = "Code actions" })
map("n", "<leader>cf", formatter.format, { desc = "Format document" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
map("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })

map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>r", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>D", vim.lsp.buf.type_definition, { desc = "Type definition" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
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

group({ "<leader>g", group = "Go to" })
map("n", "<leader>gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
map("n", "<leader>gr", vim.lsp.buf.references, { desc = "Go to references/usages" })
map("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "<leader>gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "<leader>gt", vim.lsp.buf.type_definition, { desc = "Go to type definition" })

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
	cmp.confirm({ select = auto_select })
end, { desc = "Confirm (auto-select)" })
map("i", "<S-Tab>", function()
	cmp.confirm({ behavior = require("cmp").ConfirmBehavior.Replace })
end, { desc = "Confirm (replace)" })
map("i", "<C-CR>", function()
	cmp.abort()
end, { desc = "Abort completion" })

-- #################
-- ### nvim-tree ###
-- #################
local tree = require("neo-tree.command")
map("n", "<leader>b", function()
	tree.execute({ toggle = true })
end, { desc = "Toggle file tree" })

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

map({ "n", "x", "o" }, "]m", ts_move("goto_next_start", "@function.outer"))
map({ "n", "x", "o" }, "]M", ts_move("goto_next_end", "@function.outer"))
map({ "n", "x", "o" }, "[m", ts_move("goto_previous_start", "@function.outer"))
map({ "n", "x", "o" }, "[M", ts_move("goto_previous_end", "@function.outer"))
map({ "n", "x", "o" }, "]]", ts_move("goto_next_start", "@class.outer"))
map({ "n", "x", "o" }, "[[", ts_move("goto_previous_start", "@class.outer"))
