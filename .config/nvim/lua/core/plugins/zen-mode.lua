return {
	"folke/zen-mode.nvim",
	opts = {
		plugins = {
			options = {
				enabled = true,
				ruler = false,
				showcmd = false,
				laststatus = 0,
				number = false,
				relativenumber = false,
				signcolumn = "no",
				cursorline = false,
				cursorcolumn = false,
				foldcolumn = "0",
			},
			tmux = { enabled = false },
		},
	},

	vim.api.nvim_set_keymap("n", "<leader>z", ":ZenMode | Pencil<CR>", { noremap = true, silent = true }),
}
