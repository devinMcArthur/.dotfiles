local builtin = require("telescope.builtin")

require("telescope").setup {
  defaults = {
    vimgrep_arguments = {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case'
    }
  }
}

vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fw', builtin.live_grep, {})
vim.keymap.set('n', '<leader>ps', function ()
	builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)
