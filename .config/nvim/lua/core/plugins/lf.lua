return {
	"lmburns/lf.nvim",
	dependencies = "akinsho/nvim-toggleterm.lua",
	opts = {
		border = "rounded",
	},
	config = function(_, opts)
		-- does not work when lazy loaded
		vim.g.lf_netrw = 1
		-- TODO: my mapping <leader>lf is soo good but in the LSP cluster
		vim.keymap.set("n", "<leader>lf", "<cmd>Lf<cr>", { desc = "LF" })
		vim.api.nvim_create_autocmd("User", {
			pattern = "LfTermEnter",
			callback = function(a)
				vim.api.nvim_buf_set_keymap(a.buf, "t", "q", "q", { nowait = true })
			end,
		})
		require("lf").setup(opts)
	end,
}
