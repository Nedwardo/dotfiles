local map = vim.keymap.set
local group = require("which-key").add

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
map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

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

-- ##############
-- ### Coding ###
-- ##############
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
	cmp.complete()
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
