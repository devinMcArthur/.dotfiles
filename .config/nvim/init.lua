require("config.Devim")

require("config.lazy")
require("config.options")
require("config.keymappings")
require("config.plugins")

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
