local default_config = {
	enabled = false,
	opts = {},
	keys = {
    -- stylua: ignore start
    { "<leader>a", function() require("harpoon"):list():append() end, desc = "Harpoon append", },
    { "<leader>0", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon UI", },
    { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1", },
    { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2", },
    { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3", },
    { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4", },
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
	end,
}
