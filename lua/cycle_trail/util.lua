local M = {}

---@alias namespace_id number
---@alias sign_group string

---@type namespace_id
M.ns_id = vim.api.nvim_create_namespace("cycletrail")

---@type sign_group
M.sign_group = "CycleTrailSigns"

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

---@param force boolean | nil
function M.is_buffer_valid(bufnum, force)
	if not vim.api.nvim_buf_is_valid(bufnum) or not vim.api.nvim_buf_is_loaded(bufnum) then
		if force == true then
			vim.fn.bufload(bufnum)
			return true
		end
		return false
	end
	return true
end

function M.save_to_shada(marks)
	local sucess, marks_json = pcall(vim.json.encode, marks)
	if sucess then
		vim.g.CycleTrailMarks = marks_json
	else
		vim.notify("CycleTrail: Failed to encode marks: " .. marks_json, vim.log.levels.ERROR)
	end
end

---@return LoadedMark[] | nil
function M.load_from_shada()
	local result = {}
	if vim.g.CycleTrailMarks then
		local marks_decoded = vim.json.decode(vim.g.CycleTrailMarks)
		for _, mark in ipairs(marks_decoded) do
			if vim.fn.bufexists(mark.filename) == 1 then
				table.insert(result, mark)
			end
		end
	end
	return result
end

return M
