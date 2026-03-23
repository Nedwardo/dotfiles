return {
	"hrsh7th/nvim-cmp",
	version = false, -- last release is way too old
	event = "BufEnter",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"onsails/lspkind.nvim",
	},
	opts = function()
		local cmp = require("cmp")
		local defaults = require("cmp.config.default")()
		local auto_select = true
		return {
			auto_brackets = {},
			completion = {
				completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
			},
			preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "path" },
			}, {
				{ name = "buffer" },
			}),
			formatting = {
				format = require("lspkind").cmp_format({
					mode = "symbol_text", -- show icon + text, or "symbol" for icon only
					maxwidth = 40,
					ellipsis_char = "…",
				}),
			},
			sorting = defaults.sorting,
		}
	end,
	config = function(_, opts)
		vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })
		vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
		require("cmp").setup(opts)
	end,
}
