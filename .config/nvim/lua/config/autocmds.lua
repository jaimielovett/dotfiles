-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Scroll the Claude Code window with Ctrl+u / Ctrl+d. Claude draws its own
-- full-screen UI, so send it Page Up / Page Down instead of scrolling the buffer.
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("claude_scroll", { clear = true }),
  callback = function(args)
    if not vim.api.nvim_buf_get_name(args.buf):lower():find("claude") then
      return
    end
    vim.keymap.set("t", "<C-u>", "<PageUp>", { buffer = args.buf, desc = "Claude: scroll up" })
    vim.keymap.set("t", "<C-d>", "<PageDown>", { buffer = args.buf, desc = "Claude: scroll down" })
  end,
})

-- Close the LÖVE terminal (opened by <leader>r) when the game exits cleanly.
-- On a non-zero exit it stays open so the output and error are still readable.
vim.api.nvim_create_autocmd("TermClose", {
  group = vim.api.nvim_create_augroup("love_term_close", { clear = true }),
  callback = function(args)
    if not vim.api.nvim_buf_get_name(args.buf):find(":love ", 1, true) then
      return
    end
    if vim.v.event.status ~= 0 then
      return
    end
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        vim.api.nvim_buf_delete(args.buf, { force = true })
      end
    end)
  end,
})
