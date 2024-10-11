return {
	"allaman/emoji.nvim",
	ft = "markdown",
	dependencies = "hrsh7th/nvim-cmp",
	opts = {},
	config = function(_, opts)
		require("emoji").setup(opts)
		require("telescope").load_extension("emoji")
	end,
	dev = true,
}
