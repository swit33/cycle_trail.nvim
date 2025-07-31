--- TODO: Rewrite the plugin; it works now but it's not very good
---@class CycleTrail
---@field add_mark fun()
---@field cycle_marks fun(direction: "up"|"down")
---@field pop_and_jump fun(leave_mark: boolean)
---@field rewind fun()
---@field smart_rewind fun()
---@field clear_marks fun()
---@field get_number_of_marks fun(): number
---@field setup fun(opts: CycleTrailOpts)
local M = {}

local util = require("cycle_trail.util")

---@class CycleTrailOpts
---@field text string or nil
---@field texthl highlight_group or nil
---@field linehl highlight_group or nil
---@field numhl highlight_group or nil
---@field setup_clear_command boolean

---@alias extmark_id number
---@alias highlight_group string

---@class LoadedMark
---@field filename string
---@field line number
---@field col number

---@class CycleTrailQueueItem
---@field buf number
---@field id extmark_id

---@class SignOpts
---@field text string
---@field texthl highlight_group
---@field linehl highlight_group
---@field numhl highlight_group

---@class CycleTrailPosition
---@field line number
---@field col number
---@field buf number

---@type CycleTrailQueueItem[]
local mark_queue = {}

---@type CycleTrailQueueItem|nil
local rewind_mark = nil

---@type number|nil
local selected_mark = nil

---@param opts SignOpts
local function define_sign(opts)
	vim.fn.sign_define("CycleTrailMark", {
		text = opts.text,
		texthl = opts.texthl,
		linehl = opts.linehl,
		numhl = opts.numhl,
	})
end

local function remove_mark(mark)
	vim.api.nvim_buf_del_extmark(mark.buf, util.ns_id, mark.id)
	vim.fn.sign_unplace(util.sign_group, { buffer = mark.buf, id = mark.id })
end

function M.add_mark()
	local pos = util.get_current_position()
	for i, mark in ipairs(mark_queue) do
		local mark_info = vim.api.nvim_buf_get_extmark_by_id(mark.buf, util.ns_id, mark.id, {})
		if mark.buf == pos.buf and pos.line - 1 == mark_info[1] then
			table.remove(mark_queue, i)
			remove_mark(mark)
			return
		end
	end
	local new_mark = vim.api.nvim_buf_set_extmark(pos.buf, util.ns_id, pos.line - 1, pos.col, {})
	table.insert(mark_queue, { buf = pos.buf, id = new_mark })
	vim.fn.sign_place(new_mark, util.sign_group, "CycleTrailMark", pos.buf, {
		lnum = pos.line,
		priority = 10,
	})
	selected_mark = 1
end

local function set_rewind_mark()
	local pos = util.get_current_position()
	rewind_mark = { buf = pos.buf, id = vim.api.nvim_buf_set_extmark(pos.buf, util.ns_id, pos.line - 1, pos.col, {}) }
end

---@param mark CycleTrailQueueItem
local function jump_to_mark(mark)
	if vim.api.nvim_get_current_buf() ~= mark.buf then
		local win_id = util.find_window_with_bufnum(mark.buf)
		if win_id then
			vim.api.nvim_set_current_win(win_id)
		else
			vim.api.nvim_set_current_buf(mark.buf)
		end
	end
	local mark_info = vim.api.nvim_buf_get_extmark_by_id(mark.buf, util.ns_id, mark.id, {})
	vim.api.nvim_win_set_cursor(0, { mark_info[1] + 1, mark_info[2] })
end

---@param direction "up"|"down"
function M.cycle_marks(direction)
	if #mark_queue == 0 then
		vim.notify("No marks in queue", vim.log.levels.WARN)
		return
	end
	if #mark_queue == 1 then
		return
	end
	if direction == "up" then
		if selected_mark == 1 then
			selected_mark = #mark_queue
		else
			selected_mark = selected_mark - 1
		end
	elseif direction == "down" then
		if selected_mark == #mark_queue then
			selected_mark = 1
		else
			selected_mark = selected_mark + 1
		end
	else
		vim.notify("Invalid direction", vim.log.levels.ERROR)
	end
	jump_to_mark(mark_queue[selected_mark])
end

---@param leave_mark boolean
function M.pop_and_jump(leave_mark)
	if #mark_queue == 0 then
		vim.notify("No marks in queue", vim.log.levels.WARN)
		return
	end
	local mark = table.remove(mark_queue)
	if not util.is_buffer_valid(mark.buf) then
		return
	end
	if leave_mark == true then
		M.add_mark()
	else
		set_rewind_mark()
	end
	jump_to_mark(mark)
	remove_mark(mark)
end

function M.rewind()
	if not rewind_mark then
		vim.notify("No marks to rewind to", vim.log.levels.WARN)
		return
	end
	local mark = rewind_mark
	rewind_mark = nil
	M.add_mark()
	jump_to_mark(mark)
	remove_mark(mark)
end

function M.smart_rewind()
	if not rewind_mark then
		M.pop_and_jump(true)
	else
		M.rewind()
	end
end

function M.clear_marks()
	for _, mark in ipairs(mark_queue) do
		if util.is_buffer_valid(mark.buf) then
			remove_mark(mark)
		end
	end
	mark_queue = {}
	vim.fn.sign_unplace(util.sign_group)
end

function M.get_number_of_marks()
	return #mark_queue
end

function M.save_marks()
	local result = {}
	for _, mark in ipairs(mark_queue) do
		if util.is_buffer_valid(mark.buf) then
			local mark_info = vim.api.nvim_buf_get_extmark_by_id(mark.buf, util.ns_id, mark.id, {})
			table.insert(result, {
				filename = vim.api.nvim_buf_get_name(mark.buf),
				line = mark_info[1],
				col = mark_info[2],
			})
		end
	end
	if #result > 0 then
		util.save_to_shada(result)
	end
end

function M.load_marks()
	local loaded_marks = util.load_from_shada()
	if loaded_marks == nil then
		return
	end
	local result = {}
	for _, mark in ipairs(loaded_marks) do
		local bufnr = vim.fn.bufnr(mark.filename)
		if util.is_buffer_valid(bufnr, true) then
			local new_mark = vim.api.nvim_buf_set_extmark(bufnr, util.ns_id, mark.line, mark.col, {})
			vim.fn.sign_place(new_mark, util.sign_group, "CycleTrailMark", bufnr, {
				lnum = mark.line + 1,
				priority = 10,
			})
			table.insert(result, {
				buf = bufnr,
				id = new_mark,
			})
		end
	end
	if #result > 0 then
		selected_mark = 1
	end
	mark_queue = result
end

---@param opts CycleTrailOpts
function M.setup(opts)
	opts = opts or {}
	local setup_clear_command = opts.setup_clear_command or true
	define_sign({
		text = opts.text or "󱚐",
		texthl = opts.texthl or "Special",
		linehl = opts.linehl or "WildMenu",
		numhl = opts.numhl or "WildMenu",
	})
	if setup_clear_command == true then
		vim.api.nvim_create_user_command("RemoveMarks", function()
			require("cycle_trail").clear_marks()
		end, { desc = "Clear all CycleTrail marks" })
	end
end
---

return M
