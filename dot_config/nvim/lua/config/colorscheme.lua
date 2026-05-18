local present = pcall(require, "tokyonight")
if not present then
    return
end

-- Set Colorschema
vim.cmd("colorscheme " .. Devim.colorscheme)

-- Sets transparent background
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
