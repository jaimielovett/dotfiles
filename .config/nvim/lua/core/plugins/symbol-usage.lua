local utils = require("utils.functions")
local event
if utils.isNeovimVersionsatisfied(10) then
	event = "LspAttach"
else
	event = "BufReadPre"
end

return {
	"Wansmer/symbol-usage.nvim",
	event = event,
	config = true,
	opts = {},
}
