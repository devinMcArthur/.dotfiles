--require("dev")
--
---- Bootstrap lazy.nvim
--local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
--if not vim.loop.fs_stat(lazypath) then
--    vim.fn.system({
--        "git",
--        "clone",
--        "--filter=blob:none",
--        "https://github.com/folke/lazy.nvim.git",
--        "--branch=stable", -- latest stable release
--        lazypath,
--    })
--end
--vim.opt.rtp:prepend(lazypath)

-- Add lazy.nvim
--require("lazy").setup("dev.plugins")

require("config.Devim")

require("config.options")
require("config.lazy")
require("config.keymappings")

require("lsp.setup")
require("lsp.functions")

vim.diagnostic.config({
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    prefix = "",
  },
  severity_sort = true,
})
