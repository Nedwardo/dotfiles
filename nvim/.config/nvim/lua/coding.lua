local M = {}

M.servers = {
	basedpyright = {
		disableOrganizeImports = true,
		analysis = {
			typeCheckingMode = "strict",
			diagnosticSeverityOverrides = {
				reportMissingTypeArgument = false,
			},
			autoImportCompletions = false,
			ignore = { "*" },
		},
	},
	ruff = {},
	ts_server = {
		cmd = { "typescript-language-server", "--stdio" },
		filetypes = { "typescript", "javascript" },
	},
	lua_language_server = {
		cmd = { "lua-language-server" },
		filetypes = { "lua" },
		root_markers = {
			".luarc.json",
			".luarc.jsonc",
			".luacheckrc",
			".stylua.toml",
			".git",
		},
	},
	bash_language_server = {
		cmd = { "bash-language-server" },
		args = { "start" },
		filetypes = { "sh" },
	},
	vscode_json_languageserver = {
		cmd = { "vscode-json-languageserver", "--stdio" },
		filetypes = { "json" },
	},
	nixd = {
		cmd = { "nixd" },
		filetypes = { "nix" },
		root_markers = { "flake.nix", ".git" },
	},
}

M.formatters_by_ft = {
	lua = { "stylua" },
	python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
	javascript = { "prettier" },
	json = { "prettier" },
	sh = { "shfmt" },
	nix = { "nixfmt" },
}

M.formatter_config = {
	stylua = {
		command = "stylua",
	},
}

M.linters_by_ft = {}
M.linter_config = {}

local capabilities = require("cmp_nvim_lsp").default_capabilities()

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
