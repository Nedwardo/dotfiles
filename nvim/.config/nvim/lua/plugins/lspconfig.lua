return {
	"neovim/nvim-lspconfig",
	config = function()
		require("coding").setup_lsp()
	end,
}
