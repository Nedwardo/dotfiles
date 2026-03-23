local M = {}

M.servers = {
	omnisharp = {
		cmd = { "omnisharp", "--languageserver" },
		settings = {
			omnisharp = {
				enableRoslynAnalyzers = true,
				enableEditorConfigSupport = true,
				enableImportCompletion = true,
				organizeImportsOnFormat = true,
			},
		},
	},
}

M.formatters_by_ft = {
	cs = { "csharpier" },
	lua = { "stylua" },
	py = { "ruff" },
}

M.formatter_config = {
	csharpier = {
		command = "dotnet-csharpier",
	},
	stylua = {
		command = "stylua",
	},
	ruff = {
		command = "ruff format",
	},
}

M.linters_by_ft = {}
M.linter_config = {}

function M.setup_lsp()
	local servers_to_enable = {}

	for server, config in pairs(M.servers) do
		vim.lsp.config(
			server,
			vim.tbl_extend("force", {
				capabilities = capabilities,
			}, config)
		)
		table.insert(servers_to_enable, server)
	end

	vim.lsp.enable(servers_to_enable)
end

function M.setup_formatting()
	require("conform").setup({
		formatters_by_ft = M.formatters_by_ft,
		formatters = M.formatter_config,
		format_on_save = {
			timeout_ms = 3000,
			lsp_fallback = true,
		},
	})
end

function M.setup_linting()
	local lint = require("lint")
	lint.linters_by_ft = M.linters_by_ft

	for linter, config in pairs(M.linter_config) do
		if lint.linters[linter] then
			lint.linters[linter].cmd = config.cmd
		end
	end

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
		group = vim.api.nvim_create_augroup("lint", { clear = true }),
		callback = function()
			lint.try_lint()
		end,
	})
end

return M
