return {
  {
    "nvim-mini/mini.pairs",
    config = function(_, opts)
      LazyVim.mini.pairs(opts)
      local pairs = require("mini.pairs")
      local newline = pairs.cr
      pairs.cr = function(key)
        if vim.bo.filetype == "c" or vim.bo.filetype == "cpp" then
          -- Keep automatic closing braces, but Enter inserts only one newline.
          return key or vim.api.nvim_replace_termcodes("<CR>", true, false, true)
        end
        return newline(key)
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          -- Reuse Homebrew LLVM rather than installing another copy with Mason.
          mason = false,
          cmd = {
            "/opt/homebrew/opt/llvm/bin/clangd",
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=iwyu",
            "--function-arg-placeholders",
            "--query-driver=/usr/bin/c++,/usr/bin/clang++,/opt/homebrew/opt/llvm/bin/clang++",
          },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { c = { "clang_format" }, cpp = { "clang_format" } },
      formatters = { clang_format = { command = "/opt/homebrew/opt/llvm/bin/clang-format" } },
    },
  },
  {
    "zbirenbaum/copilot.lua",
    -- Authenticate interactively with :Copilot auth, not during installation.
    build = false,
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-w>",
          accept_line = "<M-S-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
    },
  },
}
