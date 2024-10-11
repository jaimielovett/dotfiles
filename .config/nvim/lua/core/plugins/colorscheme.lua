return {
	{
		"catppuccin/nvim",
		priority = 1000, -- make sure to load this before all the other start plugins
		config = function()
			require("catppuccin").setup({
				flavour = "frappe",
				background = {
					light = "latte",
					dark = "frappe",
				},
				transparent_background = true,
			})
			-- load the colorscheme here
			vim.cmd([[colorscheme catppuccin]])
		end,
	},
}
