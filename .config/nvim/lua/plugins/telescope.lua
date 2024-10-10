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
      '--smart-case',
      '--hidden',
      '--follow',
      '--glob=!node_modules'
    },
    layout_strategy = 'flex',
    layout_config = {
      prompt_position = 'top',
      horizontal = {
        preview_width = 0.6,
      },
      vertical = {
        mirror = false,
      },
      width = 0.9,
      height = 0.85,
    },
    sorting_strategy = 'ascending',
  }
}

require('telescope').load_extension('fzf')

local wk = require('which-key')
wk.add({
  { "<leader>f",  group = "file" }, -- group
  { "<leader>ff", builtin.git_files, desc = "Find File", mode = "n" },
  { "<leader>fw", builtin.live_grep, desc = "Find Word", mode = "n" },
  {
    "<leader>ps",
    function()
      builtin.grep_string({ search = vim.fn.input("Grep > ") })
    end,
    desc = "Grep String",
    mode = "n"
  },
})
-- vim.keymap.set('n', '<leader>ff', builtin.git_files, {})
-- vim.keymap.set('n', '<leader>fw', builtin.live_grep, {})
-- vim.keymap.set('n', '<leader>ps', function()
--   builtin.grep_string({ search = vim.fn.input("Grep > ") })
-- end)
