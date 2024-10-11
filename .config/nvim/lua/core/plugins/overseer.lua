return {
	"stevearc/overseer.nvim",
	keys = {
		{ "<leader>r", "<cmd>OverseerRun<cr>", desc = "Overseer Run" },
		{ "<leader>tr", "<cmd>OverseerToggle<cr>", desc = "Overseer" },
	},
	opts = {
		task_list = {
			bindings = {
				["<C-l>"] = false,
				["<C-h>"] = false,
			},
		},
	},
	config = true,
}
