vim.keymap.set("n", "<leader>vb", ":BaconList<CR>")

require("bacon").setup({
  project_dirs = {
    {
      project_dir = "/home/dev/work/hubsite",
      rust_dir = "server/"
    }
  }
})
