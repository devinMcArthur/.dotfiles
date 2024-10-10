local home = vim.fn.expand("$HOME")
require("chatgpt").setup({
  api_key_cmd = "gpg --decrypt " .. home .. "/openai_api.txt.gpg",
  openai_params = {
    model = "gpt-4o-mini"
  },
  chat = {
    keymaps = {
      close = "q"
    }
  }
})
