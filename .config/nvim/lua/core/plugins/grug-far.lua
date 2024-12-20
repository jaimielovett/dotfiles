local default_config = {
	enabled = false,
	opts = {},
	keys = {},
}

local config = vim.tbl_deep_extend("force", default_config, {})

return {
	enabled = config.enabled,
	"MagicDuck/grug-far.nvim",
	opts = config.opts,
	keys = config.keys,
	config = function(_, opts)
		require("grug-far").setup(opts)
	end,
}
