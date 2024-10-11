local config = {
	enabled = true,
	keys = {
		{ "<leader>ga", "<cmd>Telescope advanced_git_search show_custom_functions<cr>", desc = "Advanced Git Search" },
	},
}

return {
	"aaronhallaert/ts-advanced-git-search.nvim",
	dependencies = {
		"nvim-telescope/telescope.nvim",
		-- to show diff splits and open commits in browser
		"tpope/vim-fugitive",
	},
	config = function()
		require("telescope").load_extension("advanced_git_search")
	end,
	cmd = "AdvancedGitSearch",
	keys = config.keys,
}
