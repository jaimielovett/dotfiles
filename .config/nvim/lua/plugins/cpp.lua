return {
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
