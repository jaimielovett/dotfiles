return {
	"NeogitOrg/neogit",
	cmd = "Neogit",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = {
		{ "<leader>g<Enter>", "<cmd>Neogit<cr>", desc = "Neogit" },
	},
	opts = {},
	config = function(_, opts)
		require("neogit").setup(opts)
	end,
}
