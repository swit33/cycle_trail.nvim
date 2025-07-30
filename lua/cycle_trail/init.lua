local M = {}

local mark_queue = {}
local ns_id = vim.api.nvim_create_namespace("cycletrail")
local sign_group = "CycleTrailSigns"

local function define_sign(opts)
	vim.fn.sign_define("CycleTrailMark", {
		text = opts.text,
		texthl = opts.texthl,
		linehl = opts.linehl,
		numhl = opts.numhl,
	})
end

local function get_current_position()
	local pos = vim.api.nvim_win_get_cursor(0)
	local buf = vim.api.nvim_get_current_buf()
	return {
		line = pos[1],
		col = pos[2],
		buf = buf,
	}
end

function M.add_mark()
	local pos = get_current_position()
	for _, mark in ipairs(mark_queue) do
		local mark_info = vim.api.nvim_buf_get_extmark_by_id(mark.buf, ns_id, mark.id, {})
		if mark.buf == pos.buf and pos.line - 1 == mark_info[1] then
			return
		end
	end
	local new_mark = vim.api.nvim_buf_set_extmark(pos.buf, ns_id, pos.line - 1, pos.col, {})
	table.insert(mark_queue, { buf = pos.buf, id = new_mark })
	vim.fn.sign_place(new_mark, sign_group, "CycleTrailMark", pos.buf, {
		lnum = pos.line,
		priority = 10,
	})
end

local function find_window_with_bufnum(bufnum)
	local win_ids = vim.api.nvim_list_wins()
	for _, win_id in ipairs(win_ids) do
		if vim.api.nvim_win_get_buf(win_id) == bufnum then
			return win_id
		end
	end
	return nil
end

function M.pop_and_jump(leave_mark)
	if #mark_queue == 0 then
		vim.notify("No marks in queue", vim.log.levels.WARN)
		return
	end
	local mark = table.remove(mark_queue)
	if not vim.api.nvim_buf_is_valid(mark.buf) then
		vim.notify("Buffer for mark is invalid", vim.log.levels.ERROR)
		return
	end
	if leave_mark == true then
		M.add_mark()
	end
	if vim.api.nvim_get_current_buf() ~= mark.buf then
		local win_id = find_window_with_bufnum(mark.buf)
		if win_id then
			vim.api.nvim_set_current_win(win_id)
		else
			vim.api.nvim_set_current_buf(mark.buf)
		end
	end

	local mark_info = vim.api.nvim_buf_get_extmark_by_id(mark.buf, ns_id, mark.id, {})
	vim.api.nvim_win_set_cursor(0, { mark_info[1] + 1, mark_info[2] })

	vim.fn.sign_unplace(sign_group, { buffer = mark.buf, id = mark.id })
end

local function clear_marks()
	mark_queue = {}
	vim.fn.sign_unplace(sign_group)
end

function M.get_number_of_marks()
	return #mark_queue
end

function M.setup(opts)
	define_sign({
		text = opts.text or "󱚐",
		texthl = opts.texthl or "Special",
		linehl = opts.linehl or "WildMenu",
		numhl = opts.numhl or "WildMenu",
	})
	-- vim.opt.statuscolumn = "%s"
	vim.api.nvim_create_user_command("RemoveMarks", clear_marks, { desc = "Clear all CycleTrail marks" })
end

return M
