return {
  "jackMort/ChatGPT.nvim",
  cmd = { "ChatGPT", "ChatGPTRun" },
  opts = {
    api_key_cmd = "op read op://private/OpenAI/credential --no-newline",
  },
  config = function(_, opts)
    require("chatgpt").setup(opts)
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "folke/trouble.nvim",
    "nvim-telescope/telescope.nvim",
  },
}
