return {
  	"neovim/nvim-lspconfig",
  	{
	  	"nvim-telescope/telescope.nvim",
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	{
		"mason-org/mason.nvim",
		opts = {}
	}
}
