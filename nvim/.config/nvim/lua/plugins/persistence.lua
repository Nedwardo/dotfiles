return {
	"folke/persistence.nvim",
	lazy = false,
	config = function()
		require("persistence").setup({
			dir = vim.fn.stdpath("state") .. "/sessions/",
			options = { "buffers", "curdir", "tabpages", "winsize", "globals" },
		})
		vim.api.nvim_create_autocmd("VimEnter", {
			callback = function()
				local utils = require("utils")
				if utils.persistent_session_exists() and utils.vim_opened_on_folder() then
					require("persistence").load()
				end
			end,
			nested = true,
		})

		-- When closing down, if no valid file buffers are open, don't save state
		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				local has_valid_buf = false
				local bufs = {}
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					local buf_name = vim.api.nvim_buf_get_name(buf)
					bufs[buf] = "Name: "
						.. tostring(buf_name)
						.. ", is directory: "
						.. tostring(vim.fn.isdirectory(buf_name))
						.. ", Loaded: "
						.. tostring(vim.api.nvim_buf_is_loaded(buf))
						.. ", Type: "
						.. tostring(vim.bo[buf].buftype)
					if
						vim.api.nvim_buf_is_loaded(buf)
						and vim.bo[buf].buftype == ""
						and buf_name ~= ""
						and not vim.fn.isdirectory(buf_name) == 1
					then
						has_valid_buf = true
						-- break
					end
				end
				local message_preamble = "\n" .. os.date() .. ": "
				local message_postamble = ": {" .. table.concat(bufs, "}, {") .. "}"

				if not has_valid_buf then
					local message = message_preamble .. "Exiting and not saving state" .. message_postamble
					vim.notify(message)
					local file = io.open("/home/nedwardo/nvim_close_log", "a")
					file:write(message)
					file:close()
					require("persistence").stop()

					local session_file = require("persistence").current()
					if session_file and vim.fn.filereadable(session_file) == 1 then
						vim.fn.delete(session_file)
					end
				else
					local message = message_preamble .. "Exiting and saving state" .. message_postamble
					vim.notify(message)
					local file = io.open("/home/nedwardo/nvim_close_log", "a")
					file:write(message)
					file:close()
				end
			end,
		})
	end,
}
