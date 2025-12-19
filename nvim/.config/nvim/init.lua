vim.o.number = true
vim.o.relativenumber = true

vim.schedule(function()
	vim.o.clipboard ='unnamedplus'
end)

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.g.inverse_scrolloff_size = 5

local function set_dynamic_scrolloff()
	vim.opt.scrolloff = math.ceil(vim.o.lines / 2) - (vim.g.inverse_scrolloff_size + 1)
	-- On odd line count: scroll_off_size*2 - 1 lines
	-- On even: scroll_off_size*2 line
end

vim.api.nvim_create_autocmd("VimResized", {
	pattern = "*",
	callback = set_dynamic_scrolloff,
})

set_dynamic_scrolloff()

vim.o.undofile = true

require("lazy-bootstrap")
require("lazy").setup("plugins")
require("keybinds")
