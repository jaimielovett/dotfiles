local default_config = {
  enabled = false,
  opts = {},
  keys = {
    -- stylua: ignore start
    -- stylua: ignore end
  },
}

return {
  "ThePrimeagen/harpoon",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  branch = "harpoon2",
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    vim.keymap.set("n", "<leader>a", function()
      require("harpoon"):list():add()
    end)
    vim.keymap.set("n", "<leader>0", function()
      require("harpoon").ui:toggle_quick_menu(require("harpoon"):list())
    end)
    vim.keymap.set("n", "<leader>1", function()
      require("harpoon"):list():select(1)
    end)
    vim.keymap.set("n", "<leader>2", function()
      require("harpoon"):list():select(2)
    end)
    vim.keymap.set("n", "<leader>3", function()
      require("harpoon"):list():select(3)
    end)
    vim.keymap.set("n", "<leader>4", function()
      require("harpoon"):list():select(4)
    end)
  end,
}
