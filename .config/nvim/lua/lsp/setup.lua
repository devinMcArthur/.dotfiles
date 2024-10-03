-- Setup installer & lsp configs
local mason_ok, mason = pcall(require, "mason")
local mason_lsp_ok, mason_lsp = pcall(require, "mason-lspconfig")

if not mason_ok or not mason_lsp_ok then
  return
end

mason.setup({
  ui = {
    -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
    border = Devim.ui.float.border or "rounded",
  },
})

mason_lsp.setup({
  -- A list of servers to automatically install if they're not already installed
  ensure_installed = {
    "bashls",
    "cssls",
    "eslint",
    "graphql",
    "html",
    "jsonls",
    "lua_ls",
    "prismals",
    "tailwindcss",
    "gopls"
  },
  -- Whether servers that are set up (via lspconfig) should be automatically installed if they're not already installed.
  -- This setting has no relation with the `ensure_installed` setting.
  -- Can either be:
  --   - false: Servers are not automatically installed.
  --   - true: All servers set up via lspconfig are automatically installed.
  --   - { exclude: string[] }: All servers set up via lspconfig, except the ones provided in the list, are automatically installed.
  --       Example: automatic_installation = { exclude = { "rust_analyzer", "solargraph" } }
  automatic_installation = true,
})

local lspconfig = require("lspconfig")

local util = require("lspconfig/util")

local handlers = {
  ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    silent = true,
    border = Devim.ui.float.border,
  }),
  ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = Devim.ui.float.border }),
  ["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    { virtual_text = Devim.lsp.virtual_text }
  ),
}

local function on_attach(client, bufnr)
  -- set up buffer keymaps, etc.
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()

capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

-- Order matters

lspconfig.tailwindcss.setup({
  capabilities = require("lsp.servers.tailwindcss").capabilities,
  filetypes = require("lsp.servers.tailwindcss").filetypes,
  handlers = handlers,
  init_options = require("lsp.servers.tailwindcss").init_options,
  on_attach = require("lsp.servers.tailwindcss").on_attach,
  settings = require("lsp.servers.tailwindcss").settings,
})

lspconfig.cssls.setup({
  capabilities = capabilities,
  handlers = handlers,
  on_attach = require("lsp.servers.cssls").on_attach,
  settings = require("lsp.servers.cssls").settings,
})

lspconfig.eslint.setup({
  capabilities = capabilities,
  handlers = handlers,
  on_attach = require("lsp.servers.eslint").on_attach,
  settings = require("lsp.servers.eslint").settings,
})

lspconfig.jsonls.setup({
  capabilities = capabilities,
  handlers = handlers,
  on_attach = on_attach,
  settings = require("lsp.servers.jsonls").settings,
})

lspconfig.lua_ls.setup({
  capabilities = capabilities,
  handlers = handlers,
  on_attach = on_attach,
  settings = require("lsp.servers.lua_ls").settings,
})

lspconfig.tsserver.setup({
  capabilities = capabilities,
  handlers = require("lsp.servers.tsserver").handlers,
  on_attach = require("lsp.servers.tsserver").on_attach,
  settings = require("lsp.servers.tsserver").settings,
})

lspconfig.rust_analyzer.setup({
  capabilities = capabilities,
  on_attach = require("lsp.servers.rust_analyzer").on_attach,
  handlers = handlers,
})

lspconfig.gopls.setup({
  capabilities = capabilities,
  on_attach,
  handlers = handlers,
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = util.root_pattern("go.mod", "go.work", ".git"),
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = {
        unusedparams = true,
      },
    },
  },
})

for _, server in ipairs({ "bashls", "emmet_ls", "graphql", "html", "prismals", "rust_analyzer", "glint" }) do
  lspconfig[server].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    handlers = handlers,
  })
end

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }),
}
