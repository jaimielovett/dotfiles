-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Run the LÖVE project in the current working directory in a terminal split
vim.keymap.set("n", "<leader>r", "<cmd>botright split | terminal love .<cr>", { desc = "Run LÖVE" })

local project_terminal = require("config.project_terminal")
vim.keymap.set({ "n", "i", "t" }, "<F7>", project_terminal.toggle, { desc = "Toggle project terminal" })
vim.keymap.set({ "n", "i", "t" }, "<F5>", project_terminal.run_spawn, { desc = "Build and run Spawn project" })

require("config.codex").setup()
