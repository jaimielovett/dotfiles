local config = {
	enabled = true,
	opts = {
		auto_preview = false,
		modes = {
			preview_diagnostics = {
				mode = "diagnostics",
				preview = {
					type = "split",
					relative = "win",
					position = "right",
					size = 0.3,
				},
			},
		},
	},
	keys = {
		{ "<leader>x", "", desc = "Trouble" },
		{
			"<leader>qq",
			"<cmd>Trouble qflist toggle<cr>",
			desc = "Toggle",
		},
		{
			"<leader>xl",
			"<cmd>Trouble loclist toggle<cr>",
			desc = "Location List (Trouble)",
		},
		{
			"<leader>qj",
			function()
				require("trouble").next({ skip_groups = true, jump = true })
			end,
			desc = "Next",
		},
		{
			"<leader>qk",
			function()
				require("trouble").prev({ skip_groups = true, jump = true })
			end,
			desc = "Prev",
		},
	},
}

return {
	{
		"folke/trouble.nvim",
		event = "VeryLazy",
		enabled = config.enabled,
		opts = config.opts,
		keys = config.keys,
	},
}
