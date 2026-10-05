require("vis")

local function map(modes, key, action, help)
	for _, m in ipairs(modes) do vis:map(m, key, action, help) end
end

local M = vis.modes
local NORMAL, VISUAL, VLINE, OPEND = M.NORMAL, M.VISUAL, M.VISUAL_LINE, M.OPERATOR_PENDING

-- start of the line containing pos
local function line_start(file, pos)
	while pos > 0 and file:content(pos - 1, 1) ~= "\n" do pos = pos - 1 end
	return pos
end

-- position of the "\n" ending the line containing pos (or EOF)
local function line_end(file, pos)
	local size = file.size
	while pos < size and file:content(pos, 1) ~= "\n" do pos = pos + 1 end
	return pos
end

local leader = ' '

-- normal

local motions = {
	{ 'w', "<vis-motion-line-up>", "up" },
	{ 'a', "<vis-motion-char-prev>", "left" },
	{ 's', "<vis-motion-line-down>", "down" },
	{ 'd', "<vis-motion-char-next>", "right" },
	{ 'f', "<vis-motion-word-start-next>", "word forward" },
	{ 'b', "<vis-motion-word-start-prev>", "word backward" },
	{ leader..'w', "<vis-motion-line-first>", "start of file" },
	{ leader..'a', "<vis-motion-line-begin>", "start of line" },
	{ leader..'s', "<vis-motion-line-last>", "end of file" },
	{ leader..'d', "<vis-motion-line-end>", "end of line" },
	{ leader..'b', "<vis-motion-line-start>", "first non-whitespace" },
	{ leader..'f', "<vis-motion-line-finish>", "last non-whitespace" },
}
for _, m in ipairs(motions) do
	map({ NORMAL, VISUAL, VLINE, OPEND }, m[1], m[2], m[3])
end

vis:map(NORMAL, leader..leader, ":w<Enter>", "save")
vis:map(NORMAL, leader..'q', ":q<Enter>", "quit")

vis:map(NORMAL, 'o', "<vis-append-char-next>", "append")
vis:map(NORMAL, leader..'o', "<vis-open-line-below>", "new line")

vis:map(NORMAL, 'u', "<vis-operator-change><vis-motion-char-next>", "substitute")

vis:map(NORMAL, 'z',     "<vis-undo>", "undo")
vis:map(NORMAL, '<S-z>', "<vis-redo>", "redo")

vis:map(NORMAL, 'k', "<vis-operator-delete>", "delete")
vis:map(OPEND,  'k', "<vis-operator-delete>", "delete line")
vis:map(VISUAL, 'k', "<vis-operator-delete>", "delete")
vis:map(VLINE,  'k', "<vis-operator-delete>", "delete")

--y = copy
--p = paste

vis:map(NORMAL, '<Up>', '<C-w>k') -- nav up window
vis:map(NORMAL, '<Left>', '<C-w>h') -- nav left window
vis:map(NORMAL, '<Down>', '<C-w>j') -- nav down window
vis:map(NORMAL, '<Right>', '<C-w>l') -- nav right window

-- visual

vis:map(VISUAL, 'u', "<vis-operator-change>", "substitute selection")
vis:map(VLINE,  'u', "<vis-operator-change>", "substitute selection")

local function move_lines(dir)
	local win = vis.win
	local file = win.file
	local sel = win.selection
	local size = file.size
	local visual = vis.mode ~= NORMAL
	local pos = sel.pos
	if not pos then return end

	local a, b = pos, pos
	local r = sel.range
	if visual and r then
		a, b = r.start, math.max(r.start, r.finish-1)
	end

	local bs = line_start(file, a)
	local be = line_end(file, b)
	if be < size then be = be+1 end
	local block = file:content(bs, be - bs)
	local from, to, new, shift

	if dir < 0 then
		if bs == 0 then return end
		local ps = line_start(file, bs-1)
		local prev = file:content(ps, bs - ps)
		from, to = ps, be
		if block:sub(-1) == "\n" then
			new = block..prev
		else
			new = block.."\n"..prev:sub(1,-2)
		end
		shift = -#prev
	else
		if be >= size then return end
		local ne = line_end(file, be)
		if ne < size then ne = ne + 1 end
		local nxt = file:content(be, ne - be)
		from, to = bs, ne
		if nxt:sub(-1) == "\n" then
			new = nxt .. block
			shift = #nxt
		else
			new = nxt .. "\n" .. block:sub(1,-2)
			shift = #nxt+1
		end
	end

	file:delete(from, to - from)
	file:insert(from, new)

	if visual and r then
		sel.range = { start = r.start + shift, finish = r.finish + shift }
	else
		sel.pos = pos + shift
	end
end

for _, m in ipairs({ NORMAL, VISUAL, VLINE }) do
	vis:map(m, '<S-w>', function() move_lines(-1) end, "move line(s) up")
	vis:map(m, '<S-s>', function() move_lines(1)  end, "move line(s) down")
end

-- surround

local delims = {
	['('] = { '(', ')' }, [')'] = { '(', ')' }, b = { '(', ')' },
	['{'] = { '{', '}' }, ['}'] = { '{', '}' }, B = { '{', '}' },
	['['] = { '[', ']' }, [']'] = { '[', ']' }, r = { '[', ']' },
	a = { '<', '>' },
	['"'] = { '"', '"' }, ["'"] = { "'", "'" }, ['`'] = { '`', '`' },
}

local function wrap(file, s, e, d)
	file:insert(e, d[2])
	file:insert(s, d[1])
end

local function surround_word(d)
	local sel = vis.win.selection
	local file = vis.win.file
	local pos = sel.pos
	local ls, le = line_start(file, pos), line_end(file, pos)
	local text = file:content(ls, le - ls)
	local i = pos+1 - ls
	if not text:sub(i, i):match("[%w_]") then return end
	local s, e = i, i
	while s > 1 and text:sub(s-1, s-1):match("[%w_]") do s = s-1 end
	while e < #text and text:sub(e+1, e+1):match("[%w_]") do e = e+1 end
	wrap(file, ls-1 + s, ls + e, d)
	sel.pos = pos+1
end

local function surround_line(d)
	local sel = vis.win.selection
	local file = vis.win.file
	local pos = sel.pos
	local ls, le = line_start(file, pos), line_end(file, pos)
	local text = file:content(ls, le - ls)
	local lead = #text:match("^%s*")
	local trail = #text:match("%s*$")
	if lead >= #text then return end
	wrap(file, ls + lead, le - trail, d)
	sel.pos = pos+1
end

local function surround_selection(d)
	local sel = vis.win.selection
	local file = vis.win.file
	local r = sel.range
	if not r then return end
	local s, e = r.start, r.finish
	if e > s and file:content(e-1,1) == "\n" then e = e-1 end
	wrap(file, s, e, d)
	vis.mode = NORMAL
	sel.pos = s
end

local function find_pair(file, pos, d)
	local open, close = d[1], d[2]
	local lo = math.max(0, pos - 50000)
	local hi = math.min(file.size, pos + 50000)
	local text = file:content(lo, hi - lo)
	local i = pos+1 - lo

	if open == close then
		local ls = line_start(file, pos)+1 - lo
		local le = line_end(file, pos) - lo
		local marks = {}
		for k = math.max(ls,1), math.min(le, #text) do
			if text:sub(k, k) == open and text:sub(k-1, k-1) ~= "\\" then
				marks[#marks+1] = k
			end
		end
		for k = 1, #marks-1, 2 do
			if marks[k] <= i and i <= marks[k+1] then
				return lo + marks[k]-1, lo + marks[k+1]-1
			end
		end
		return
	end

	local depth, s = 0, nil
	local j = i
	if text:sub(i, i) == close then j = i-1 end
	while j >= 1 do
		local c = text:sub(j, j)
		if c == close then depth = depth+1
		elseif c == open then
			if depth == 0 then s = j break end
			depth = depth-1
		end
		j = j-1
	end
	if not s then return end
	depth = 0
	for k = s+1, #text do
		local c = text:sub(k, k)
		if c == open then depth = depth+1
		elseif c == close then
			if depth == 0 then return lo-1 + s, lo-1 + k end
			depth = depth-1
		end
	end
end

local function delete_surround(d)
	local sel = vis.win.selection
	local file = vis.win.file
	local pos = sel.pos
	local s, e = find_pair(file, pos, d)
	if not s then return end
	file:delete(e,1)
	file:delete(s,1)
	local np = pos
	if pos > s then np = np-1 end
	if pos > e then np = np-1 end
	sel.pos = np
end

local function change_surround(from, to)
	local sel = vis.win.selection
	local file = vis.win.file
	local pos = sel.pos
	local s, e = find_pair(file, pos, from)
	if not s then return end
	file:delete(e,1)
	file:insert(e, to[2])
	file:delete(s,1)
	file:insert(s, to[1])
	sel.pos = pos
end

for key, d in pairs(delims) do
	vis:map(NORMAL, 'js'..key, function() surround_word(d) end,      "surround word")
	vis:map(NORMAL, 'jS'..key, function() surround_line(d) end,      "surround line")
	vis:map(VISUAL, 'js'..key, function() surround_selection(d) end, "surround selection")
	vis:map(VLINE,  'js'..key, function() surround_selection(d) end, "surround selection")
	vis:map(NORMAL, 'ks'..key, function() delete_surround(d) end,    "delete surround")
	for key2, d2 in pairs(delims) do
		vis:map(NORMAL, 'ls'..key..key2, function() change_surround(d, d2) end, "change surround")
	end
end

-- fzf

local function sq(s) return "'"..tostring(s):gsub("'", "'\\''").."'" end

local function have(prog)
	local ok = os.execute("command -v "..prog.." >/dev/null 2>&1")
	return ok == true or ok == 0
end

local function redraw() vis:feedkeys("<vis-redraw>") end

-- run "<producer> | fzf <args>" fullscreen; returns the picked line or nil
local function fzf(producer, args)
	if not have("fzf") then vis:info("fzf not found in PATH") return nil end
	local file = vis.win.file
	local status, out = vis:pipe(file, { start = 0, finish = 0 },
		producer.." | fzf "..(args or ""), true)
	redraw()
	if status ~= 0 or not out then return nil end
	out = out:gsub("\n.*$", "")
	if out == "" then return nil end
	return out
end

local function edit(path, line)
	vis:command("e "..sq(path))
	if line then vis.win.selection:to(line,1) end
end

local files_cmd = "(fd --type f --hidden --exclude .git 2>/dev/null || find . -type f -not -path '*/.git/*' | sed 's|^\\./||')"

local function pick_file()
	local p = fzf(files_cmd, "--prompt 'files> '")
	if p then edit(p) end
end

local function live_grep()
	local rg = "rg --line-number --no-heading --color=never --smart-case -e {q} . 2>/dev/null"
	local gr = "grep -rIn -e {q} . 2>/dev/null"
	local reload = "[ -n {q} ] && ("..rg.." || "..gr..") || true"
	local out = fzf(":", "--disabled --delimiter : --prompt 'grep> ' --bind "..sq("change:reload:"..reload))
	if not out then return end
	local path, line = out:match("^(.-):(%d+):")
	if path then edit(path, tonumber(line)) end
end

local function pick_buffer()
	local names, seen = {}, {}
	for win in vis:windows() do
		local n = win.file.path or win.file.name
		if n and not seen[n] then seen[n] = true names[#names + 1] = n end
	end
	if #names == 0 then return end
	local tmp = os.tmpname()
	local f = io.open(tmp, "w")
	f:write(table.concat(names, "\n"), "\n")
	f:close()
	local p = fzf("cat "..sq(tmp), "--prompt 'buffers> '")
	os.remove(tmp)
	if p then edit(p) end
end

-- recent files are stored most-recent-last in a plain text file
local data_home = os.getenv("XDG_DATA_HOME") or ((os.getenv("HOME") or "").."/.local/share")
local recent_path = data_home.."/vis/recent"

local function remember(path)
	if not path then return end
	os.execute("mkdir -p "..sq(data_home.."/vis"))
	local f = io.open(recent_path, "a")
	if f then f:write(path, "\n") f:close() end
end

local function pick_recent()
	local f = io.open(recent_path, "r")
	if not f then vis:info("no recent files yet") return end
	local list, seen = {}, {}
	local all = {}
	for l in f:lines() do all[#all+1] = l end
	f:close()
	for i = #all, 1, -1 do
		local p = all[i]
		if not seen[p] then
			seen[p] = true
			local t = io.open(p, "r")
			if t then t:close() list[#list+1] = p end
			if #list >= 200 then break end
		end
	end
	if #list == 0 then vis:info("no recent files yet") return end
	local tmp = os.tmpname()
	local w = io.open(tmp, "w")
	w:write(table.concat(list, "\n"), "\n")
	w:close()
	local p = fzf("cat " .. sq(tmp), "--prompt 'recent> '")
	os.remove(tmp)
	if p then edit(p) end
end

vis:map(NORMAL, leader..'ff', pick_file,      "fzf files")
vis:map(NORMAL, leader..'fg', live_grep,      "fzf live grep")
vis:map(NORMAL, leader..'fb', pick_buffer,    "fzf buffers")
vis:map(NORMAL, leader..'fh', ":help<Enter>", "help")
vis:map(NORMAL, leader..'fr', pick_recent,    "fzf recent files")

-- Statusline
local statusline = require("statusline")

-- Completion
local localcomplete = require("localcomplete")

vis.events.subscribe(vis.events.FILE_OPEN, function(file) remember(file.path) end)
vis.events.subscribe(vis.events.FILE_SAVE_POST, function(file) remember(file.path) end)

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	vis:command("set autoindent")
	vis:command("set tabwidth 2")

	vis:command("set relativenumbers")
	vis:command("set statusbar")
end)
