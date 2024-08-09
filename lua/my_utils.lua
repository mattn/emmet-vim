local M = {}

M.get_node_at_cursor = function()
	local ts_utils = require("nvim-treesitter.ts_utils")
	local node = ts_utils.get_node_at_cursor()
	if not node then
		return nil
	end

	while node do
		local node_type = node:type()

		if node_type == "element" then
			return "html"
		elseif node_type == "stylesheet" then
			return "css"
		end

		node = node:parent()
	end

	return ""
end

return M
