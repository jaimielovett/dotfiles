return {
  "ThePrimeagen/harpoon",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>hm", "<cmd>lua require('harpoon.mark').add_file()<cr>")
    keymap.set("n", "<leader>he", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>")
    keymap.set("n", "<leader>1", "<cmd>lua require('harpoon.ui').nav_file(1)<cr>")
    keymap.set("n", "<leader>2", "<cmd>lua require('harpoon.ui').nav_file(2)<cr>")
    keymap.set("n", "<leader>3", "<cmd>lua require('harpoon.ui').nav_file(3)<cr>")
    keymap.set("n", "<leader>4", "<cmd>lua require('harpoon.ui').nav_file(4)<cr>")
  end,
}
