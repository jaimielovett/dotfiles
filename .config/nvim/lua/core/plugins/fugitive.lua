local default_config = {
	enabled = true,
	keys = {},
	opts = {},
}

local config = vim.tbl_deep_extend("force", default_config, {})

return {
	"tpope/vim-fugitive",
	enabled = config.enabled,
	keys = config.keys,
	cmd = "G",
}
