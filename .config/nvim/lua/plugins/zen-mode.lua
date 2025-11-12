return {
  "folke/zen-mode.nvim",
  opts = {
    window = {
      width = 0.7, -- 70% of editor width
      options = {
        number = true,
        relativenumber = true,
      },
    },
  },
  keys = {
    {
      "<leader>z",
      function()
        require("zen-mode").toggle()
      end,
      desc = "Toggle Zen Mode",
    },
  },
}
