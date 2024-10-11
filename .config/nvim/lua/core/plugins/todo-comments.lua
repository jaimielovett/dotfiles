local config = {
	enabled = false,
	event = { "VeryLazy" },
	opts = {},
	keys = {
		{
			"<leader>qt",
			"<cmd>TodoTrouble<cr>",
			desc = "TODO",
		},
	},
}

return {
	{
		"folke/todo-comments.nvim",
		event = config.event,
		enabled = config.enabled,
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = config.opts,
		keys = config.keys,
	},
}
