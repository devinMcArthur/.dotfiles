-- Apply the active colorscheme (from config/theme.lua via Devim); pcall so
-- a missing/not-yet-installed theme plugin degrades to default colors
-- instead of erroring on startup.
local ok = pcall(vim.cmd, "colorscheme " .. Devim.colorscheme)
if not ok then
    vim.notify("colorscheme '" .. Devim.colorscheme .. "' not available", vim.log.levels.WARN)
    return
end

-- Sets transparent background
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
