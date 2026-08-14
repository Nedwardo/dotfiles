return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-telescope/telescope-ui-select.nvim",
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_cursor({
							layout_config = {
								width = 60,
								height = 12,
							},
						}),
					},
				},
			})
			telescope.load_extension("fzf")
			telescope.load_extension("ui-select")
			local orig_select = vim.ui.select
			vim.ui.select = function(items, opts, on_choice)
				opts = opts or {}
				local first = items[1]
				if type(first) == "table" and first.name and first.name:match("^Cargo:") then
					opts.format_item = function(cfg)
						local test = cfg.args and cfg.args[1]
						local pkg = cfg.name:match("%-%-package%s+(%S+)")
						if test and not test:match("^%-%-") then
							return pkg and ("  " .. pkg .. " › " .. test) or ("  " .. test)
						end
						return cfg.name
					end
				end
				orig_select(items, opts, on_choice)
			end
		end,
	},
}
