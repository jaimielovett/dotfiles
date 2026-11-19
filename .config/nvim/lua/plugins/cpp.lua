local clangd = "clangd"
local clang_format = "clang-format"
local clangd_args = {
  "--background-index",
  "--clang-tidy",
  "--completion-style=detailed",
  "--header-insertion=iwyu",
  "--function-arg-placeholders=1",
}

if vim.fn.has("macunix") == 1 then
  local prefix = vim.env.HOMEBREW_PREFIX or (jit.arch == "arm64" and "/opt/homebrew" or "/usr/local")
  local llvm_bin = prefix .. "/opt/llvm/bin/"
  if vim.fn.executable(llvm_bin .. "clangd") == 1 then
    clangd = llvm_bin .. "clangd"
  end
  if vim.fn.executable(llvm_bin .. "clang-format") == 1 then
    clang_format = llvm_bin .. "clang-format"
  end
  table.insert(clangd_args, "--query-driver=/usr/bin/c++,/usr/bin/clang++," .. llvm_bin .. "clang++")
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          -- Use the system LLVM toolchain.
          mason = false,
          cmd = vim.list_extend({ clangd }, clangd_args),
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { c = { "clang_format" }, cpp = { "clang_format" } },
      formatters = { clang_format = { command = clang_format } },
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
