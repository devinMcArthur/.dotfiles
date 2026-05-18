local keymap = vim.keymap.set

keymap("n", "<leader>pv", "<cmd>Oil<CR>")

keymap("n", "J", "mzJ`z")
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")

-- greatest remap ever
keymap("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
keymap({ "n", "v" }, "<leader>y", [["+y]])
keymap("n", "<leader>Y", [["+Y]])

keymap({ "n", "v" }, "<leader>d", [["_d]])

-- This is going to get me cancelled
keymap("i", "<C-c>", "<Esc>")

-- Keep selection after indent
keymap("v", "<", "<gv", { noremap = true, silent = true })
keymap("v", ">", ">gv", { noremap = true, silent = true })

keymap("n", "Q", "<nop>")
keymap("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
keymap("n", "<leader>fo", vim.lsp.buf.format)

-- List all symbols in the current buffer
keymap("n", "<leader>ds", vim.lsp.buf.document_symbol)

keymap("n", "<C-k>", "<cmd>cnext<CR>zz")
keymap("n", "<C-j>", "<cmd>cprev<CR>zz")
keymap("n", "<leader>k", "<cmd>lnext<CR>zz")
keymap("n", "<leader>j", "<cmd>lprev<CR>zz")

keymap("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
keymap("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

keymap("n", "<leader><leader>", function()
  vim.cmd("so")
end)

keymap("n", "<leader>gg", ":LazyGit<CR>")

-- Comment
keymap("n", "<leader>/", function()
  require("Comment.api").toggle.linewise.count(vim.v.count > 0 and vim.v.count or 1)
end)
keymap("v", "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>")

local builtin = require("telescope.builtin")
local wk = require('which-key')
wk.add({
  { "<leader>f",  group = "file" }, -- group
  { "<leader>ff", builtin.git_files, desc = "Find File", mode = "n" },
  { "<leader>fw", builtin.live_grep, desc = "Find Word", mode = "n" },
  {
    "<leader>ps",
    function()
      builtin.grep_string({ search = vim.fn.input("Grep > ") })
    end,
    desc = "Grep String",
    mode = "n"
  },
})

keymap("n", "-", require("oil").open, { desc = "Open parent directory" })

local harpoon = require("harpoon")
keymap("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
keymap("n", "<leader>a", function() harpoon:list():add() end)

keymap("n", "<C-h>", function() harpoon:list():select(1) end)
keymap("n", "<C-t>", function() harpoon:list():select(2) end)
keymap("n", "<C-n>", function() harpoon:list():select(3) end)
keymap("n", "<C-s>", function() harpoon:list():select(4) end)

-- Toggle previous & next buffers stored within Harpoon list
keymap("n", "<C-S-P>", function() harpoon:list():prev() end)
keymap("n", "<C-S-N>", function() harpoon:list():next() end)

keymap("n", "<leader>ft", ":FloatermNew<CR>")

keymap("n", "<leader>vb", ":BaconList<CR>")

keymap("n", "<leader>la", "<cmd>:Lazy<cr>")
