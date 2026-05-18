local M = {}

function M.enable_format_on_save()
  local group = vim.api.nvim_create_augroup("format_on_save", { clear = false })
  vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function()
      -- Filter to only use rust-analyzer for Rust files
      if vim.bo.filetype == "rust" then
        vim.lsp.buf.format({
          filter = function(client)
            return client.name == "rust_analyzer"
          end,
        })
      else
        vim.lsp.buf.format()
      end
    end,
    group = group,
  })
  require("notify")("Enabled format on save", "info", { title = "LSP", timeout = 2000 })
end

function M.disable_format_on_save()
  vim.api.nvim_del_augroup_by_name("format_on_save")
  require("notify")("Disabled format on save", "info", { title = "LSP", timeout = 2000 })
end

function M.toggle_format_on_save()
  if vim.fn.exists("#format_on_save#BufWritePre") == 0 then
    M.enable_format_on_save()
  else
    M.disable_format_on_save()
  end
end

vim.api.nvim_create_user_command("LspToggleAutoFormat", 'lua require("lsp.functions").toggle_format_on_save()', {})

M.toggle_format_on_save()

return M
