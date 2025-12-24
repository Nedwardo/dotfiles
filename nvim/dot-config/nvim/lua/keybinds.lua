local map = vim.keymap.set

-- ###############
-- ### Default ###
-- ###############
map('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
map('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
map('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
map('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')
map({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- #################
-- ### Lazy nvim ###
-- #################
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- #################
-- ### Telescope ###
-- #################
local builtin = require('telescope.builtin')
map('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
map('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
map('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
map('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

