return {
	"mfussenegger/nvim-lint",
	config = function()
		require("coding").setup_linting()
	end,
}
