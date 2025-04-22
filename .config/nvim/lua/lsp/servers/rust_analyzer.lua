local M = {}

local on_attach = function(client, bufnr)
  -- require('completion').on_attach(client)
  vim.lsp.inlay_hint.enable(bufnr)
end

M.on_attach = on_attach;

-- Implement leptosfmt for rust-analyzer rustfmt
M.settings = {
  ["rust-analyzer"] = {
    rustfmt = {
      overrideCommand = { "leptosfmt", "--stdin", "--rustfmt" },
    },
    -- checkOnSave = {
    --   command = "clippy",
    --   allFeatures = true,
    --   extraArgs = { "--all-targets", "--all-features" },
    -- },
    inlayHints = {
      typeHints = { enable = true }, -- or false to test toggling
      parameterHints = { enable = true },
      chainingHints = { enable = true },
      maxLength = 5 -- This will truncate hints to be very short
    },
    lens = {
      enable = true,                      -- or false to toggle
      references = { enable = true },     -- Toggle "N references" tags
      implementations = { enable = true } -- Toggle "N implementations" tags
    },
    cargo = {
      allFeatures = true,
      loadOutDirsFromCheck = true,
      runBuildScripts = true,
      buildScripts = true,
    },
    -- Other Settings ...
    procMacro = {
      ignored = {
        leptos_macro = {
          -- optional: --
          -- "component",
          -- "server",
        },
      },
    },
  }
}

return M
