return {
  {
    url = "https://github.com/devinMcArthur/nvim-bacon-dir",
    name = "bacon",
    lazy = false,
    config = function()
      require("bacon").setup({
        project_dirs = {
          {
            project_dir = "/home/dev/work/hubsite",
            rust_dir = "server/"
          }
        }
      })
    end,
  },
}
