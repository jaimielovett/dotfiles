return {
  -- Make lua_ls aware of the LÖVE (LOVE2D) runtime: recognize the `love`
  -- global and load the love2d API definitions for completion and hover docs.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                globals = { "love" },
              },
            },
          },
        },
      },
    },
  },

  -- lazydev (shipped with LazyVim) pulls in the LÖVE API types so calls like
  -- love.graphics.* autocomplete and show documentation.
  {
    "folke/lazydev.nvim",
    opts = {
      library = {
        { path = "${3rd}/love2d/library", words = { "love" } },
      },
    },
  },
}
