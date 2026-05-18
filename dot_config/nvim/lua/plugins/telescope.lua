return {
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
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
    end,
  },
}
