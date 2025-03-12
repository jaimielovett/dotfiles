return {
  "smjonas/inc-rename.nvim",
  lazy = true,
  config = function()
    vim.keymap.set("n", "<leader>rn", ":IncRename ")
  end,
}
