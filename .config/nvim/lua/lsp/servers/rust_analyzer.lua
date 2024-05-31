local M = {}

local on_attach = function(client, bufnr)
  require('completion').on_attach(client)
  vim.lsp.inlay_hint.enable(bufnr)
end

M.on_attach = on_attach;

-- Implement leptosfmt for rust-analyzer rustfmt

local settings = {
  ["rust-analyzer"] = {
    rustfmt = {
      overrideCommand = { "leptosfmt", "--stdin", "--rustfmt" },
    }
  }
}

M.settings = settings

return M
