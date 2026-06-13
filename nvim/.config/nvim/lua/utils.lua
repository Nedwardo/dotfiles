local M = {}
M.persistent_session_exists = function()
	local session_dir = vim.fn.stdpath("state") .. "/sessions/"
	local cwd = vim.fn.getcwd()
	local session_name = cwd:gsub("/", "%%") .. ".vim"
	return vim.fn.filereadable(session_dir .. session_name) == 1
end

M.vim_opened_on_folder = function()
	return vim.fn.argc() == 0 or (vim.fn.isdirectory(vim.fn.argv(0)) == 1)
end

return M
