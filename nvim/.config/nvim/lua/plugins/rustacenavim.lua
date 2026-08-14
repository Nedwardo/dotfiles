return {
	"mrcjkb/rustaceanvim",
	version = "^8",
	lazy = false,
	dependencies = {
		"mfussenegger/nvim-dap",
	},
	ft = { "rust" },
	config = function()
		vim.g.rustaceanvim = {
			-- Plugin configuration
			tools = {},
			-- LSP configuration
			server = {
				on_attach = function(client, bufnr)
					local success, _ = pcall(vim.lsp.inlay_hint.enable, true)
					if not success then
						vim.lsp.inlay_hint.enable(0, true)
					end
				end,
				default_settings = {
					["rust-analyzer"] = {
						cargo = {
							features = "all",
						},
					},
				},
			},
			-- DAP configuration
			dap = {},
		}
	end,
}
