-- statusline.lua: the ONE place that writes vis's status bar.
--
-- Why this exists: vis lets any plugin call win:status(left, right) on every
-- redraw, and whichever runs last wins.  If a completion plugin, a git plugin and
-- your own config each wrote the whole bar, they would overwrite each other.
-- So the bar is owned here (it reproduces vis's default, from vis-std.lua), and
-- everything else adds *segments*:
--
--   local statusline = require("statusline")
--   statusline.add("git", function(win, ctx)       -- ctx.room = free columns on the left
--       return "main"                              -- or nil to show nothing
--   end)                                           -- optional 3rd arg: "right" side
--   statusline.remove("git")
--
-- Left segments go after the file name, right segments before the percentage.
-- To restyle the bar, edit this file or set statusline.config.* from your visrc.

require("vis")

local M = {}

M.config = {
	left_sep  = " » ",
	right_sep = " « ",
}

local segments = { left = {}, right = {} }

function M.remove(name)
	for _, list in pairs(segments) do
		for i = #list, 1, -1 do
			if list[i].name == name then table.remove(list, i) end
		end
	end
end

function M.add(name, fn, side)
	M.remove(name)
	table.insert(segments[side == "right" and "right" or "left"], { name = name, fn = fn })
end

local function ulen(s)
	if utf8 then return utf8.len(s) or #s end
	return #s
end

local mode_names = {
	[vis.modes.NORMAL] = '', [vis.modes.OPERATOR_PENDING] = '',
	[vis.modes.VISUAL] = 'VISUAL', [vis.modes.VISUAL_LINE] = 'VISUAL-LINE',
	[vis.modes.INSERT] = 'INSERT', [vis.modes.REPLACE] = 'REPLACE',
}

local function render(win)
	local left_parts, right_parts = {}, {}
	local file, selection = win.file, win.selection

	-- ---- vis's default content (vis-std.lua) ----
	local mode = mode_names[vis.mode]
	if mode ~= '' and vis.win == win then table.insert(left_parts, mode) end
	table.insert(left_parts, (file.name or '[No Name]') ..
		(file.modified and ' [+]' or '') .. (vis.recording and ' @' or ''))

	local count, keys = vis.count, vis.input_queue
	if keys ~= '' then table.insert(right_parts, keys)
	elseif count then table.insert(right_parts, count) end

	if #win.selections > 1 then
		table.insert(right_parts, selection.number .. '/' .. #win.selections)
	end

	local size = file.size
	local pos = selection.pos or 0
	table.insert(right_parts, (size == 0 and "0" or math.ceil(pos / size * 100)) .. "%")
	if not win.large then
		local col = selection.col
		table.insert(right_parts, selection.line .. ', ' .. col)
		if size > 33554432 or col > 65536 then win.large = true end
	end

	-- ---- plugin segments ----
	local ctx = { width = win.width or 80 }
	ctx.room = ctx.width - ulen(table.concat(left_parts, M.config.left_sep))
		- ulen(table.concat(right_parts, M.config.right_sep)) - 8
	for _, seg in ipairs(segments.left) do
		local ok, s = pcall(seg.fn, win, ctx)
		if ok and type(s) == "string" and s ~= "" then
			table.insert(left_parts, s)
			ctx.room = ctx.room - ulen(s) - ulen(M.config.left_sep)
		end
	end
	for _, seg in ipairs(segments.right) do
		local ok, s = pcall(seg.fn, win, ctx)
		if ok and type(s) == "string" and s ~= "" then table.insert(right_parts, 1, s) end
	end

	return ' ' .. table.concat(left_parts, M.config.left_sep) .. ' ',
		' ' .. table.concat(right_parts, M.config.right_sep) .. ' '
end

if not M.installed then
	M.installed = true
	vis.events.subscribe(vis.events.WIN_STATUS, function(win)
		local left, right = render(win)
		win:status(left, right)
	end)
end

return M
