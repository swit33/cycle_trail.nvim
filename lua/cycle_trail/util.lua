local M = {}

---@return CycleTrailPosition
function M.get_current_position()
	local pos = vim.api.nvim_win_get_cursor(0)
	local buf = vim.api.nvim_get_current_buf()
	return {
		line = pos[1],
		col = pos[2],
		buf = buf,
	}
end

---@param bufnum number
---@return number|nil
function M.find_window_with_bufnum(bufnum)
	local win_ids = vim.api.nvim_list_wins()
	for _, win_id in ipairs(win_ids) do
		if vim.api.nvim_win_get_buf(win_id) == bufnum then
			return win_id
		end
	end
	return nil
end

function M.is_buffer_valid(bufnum)
	if not vim.api.nvim_buf_is_valid(bufnum) and not vim.api.nvim_buf_is_loaded(bufnum) then
		vim.notify("Buffer for mark is invalid", vim.log.levels.ERROR)
		return false
	end
	return true
end

return M
