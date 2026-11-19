-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Run the LÖVE project in the current working directory in a terminal split
vim.keymap.set("n", "<leader>r", "<cmd>botright split | terminal love .<cr>", { desc = "Run LÖVE" })

vim.keymap.set({ "n", "i", "t" }, "<F7>", function()
  local terminal = vim.b.snacks_terminal
  Snacks.terminal.toggle(nil, { cwd = terminal and terminal.cwd or LazyVim.root() })
end, { desc = "Toggle project terminal" })

require("config.codex").setup()
