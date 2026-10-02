-- localcomplete: document-local, syntax-aware completion for vis.
--
--   <Tab>    (insert mode) complete with the best candidate (the [highlighted] one)
--   <S-Tab>  (insert mode) insert a literal tab
--
-- While you type in insert mode, the status bar shows a one-line box of the
-- fuzzy-ranked candidates:   INSERT » foo.lua » [get_token_name] gtn_x +2
-- It never changes your buffer: vis has no overlay API, and an earlier attempt
-- to draw the box as temporary buffer text corrupted the cursor/undo state.
--
-- It only ever suggests things the current document has shown it (see engine.lua).

local base = ...
local Index = require(base .. ".engine")

local M = {}

-- Config
M.config = {
	tab_fallback = true,
	statusline   = true,
	max_items    = 3,
	budget_ms    = 50, -- if analysing a file takes longer, live suggestions pause
}

-- Languages (add new ones here; keys are vis syntax names / file extensions)
local lua_lang = require(base .. ".lang_lua")
local sh_lang  = require(base .. ".lang_sh")
local languages = {
	lua = lua_lang,
	bash = sh_lang, sh = sh_lang,
}

local function language_of(win)
	local syntax = win.syntax
	if syntax and languages[syntax] then return languages[syntax] end
	local name = win.file.name or win.file.path or ""
	local ext = name:match("%.(%w+)$")
	return ext and languages[ext] or nil
end

-- Per-file index kept in step with the buffer by diffing at use time.
local slots = {} -- key -> slot

local function split_lines(text)
	local lines = {}
	for l in (text .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = l end
	return lines
end

local function sync(idx, text)
	local new = split_lines(text)
	local old = idx.lines
	local na, nb = #old, #new
	local a = 1
	while a <= na and a <= nb and old[a] == new[a] do a = a + 1 end
	if a > na and a > nb then return end
	local ea, eb = na, nb
	while ea >= a and eb >= a and old[ea] == new[eb] do ea, eb = ea - 1, eb - 1 end
	local mid = {}
	for i = a, eb do mid[#mid + 1] = new[i] end
	idx:replace(a, ea - a + 1, mid)
end

local function slot_for(win, lang)
	local key = win.file.path or win.file.name or ""
	local slot = slots[key]
	if not slot or slot.lang ~= lang then
		slot = { idx = Index.new(lang), lang = lang }
		slots[key] = slot
	end
	return slot
end

local function buffer_text(file)
	return file:content(0, file.size) or ""
end

-- Candidates at the cursor: { cands = {...}, prefix = "...", pos = n } or nil.
-- Cached on (buffer text, cursor), so redraws that change nothing cost one string compare.
local function compute(win, force)
	local lang = language_of(win)
	local sel = win.selection
	local pos = sel and sel.pos
	if not lang or not pos then return nil end

	local file = win.file
	local text = buffer_text(file)
	local slot = slot_for(win, lang)
	if slot.text == text and slot.pos == pos and slot.result then return slot.result end
	if slot.slow and not force then return nil end

	local t0 = os.clock()
	sync(slot.idx, text)
	local before = text:sub(1, pos)
	local _, newlines = before:gsub("\n", "")
	local cands, prefix = slot.idx:complete(newlines + 1, #before:match("[^\n]*$"))
	slot.slow = (os.clock() - t0) * 1000 > M.config.budget_ms

	slot.text, slot.pos = text, pos
	slot.result = { cands = cands, prefix = prefix, pos = pos }
	return slot.result
end

-- <Tab>/<S-Tab>
local function complete()
	local win = vis.win
	local ok, res = pcall(compute, win, true)
	if not ok then vis:info("localcomplete: " .. tostring(res)) return false end
	local best = res and res.cands[1]
	if not best then return false end

	local file, sel = win.file, win.selection
	local pos, prefix = res.pos, res.prefix
	-- Insert only what's missing; if what was typed isn't a literal prefix
	-- (fuzzy match / different case), replace the typed word instead.
	if best.text:sub(1, #prefix) == prefix then
		file:insert(pos, best.text:sub(#prefix + 1))
		sel.pos = pos + #best.text - #prefix
	else
		file:delete(pos - #prefix, #prefix)
		file:insert(pos - #prefix, best.text)
		sel.pos = pos - #prefix + #best.text
	end
	return true
end

local function insert_tab()
	local sel = vis.win.selection
	local pos = sel.pos
	vis.win.file:insert(pos, "\t")
	sel.pos = pos + 1
end

vis:map(vis.modes.INSERT, "<Tab>", function()
	if not language_of(vis.win) then          -- unsupported filetype: <Tab> stays a plain tab
		insert_tab()
	elseif not complete() and M.config.tab_fallback then
		insert_tab()
	end
end, "complete")

vis:map(vis.modes.INSERT, "<S-Tab>", insert_tab, "insert tab")

-- The suggestion box (status bar)
local function ulen(s) return utf8.len(s) or #s end

local function box_text(win, room)
	local ok, res = pcall(compute, win, false)
	if not ok or not res or #res.cands == 0 then return nil end
	local parts, used = {}, 0
	for i, c in ipairs(res.cands) do
		if i > M.config.max_items then break end
		local item = i == 1 and ("[" .. c.text .. "]") or c.text
		if i > 1 and used + #item + 1 > room then break end
		parts[#parts + 1] = item
		used = used + ulen(item) + 1
	end
	local more = #res.cands - #parts
	local s = table.concat(parts, " ")
	if more > 0 then s = s .. " +" .. more end
	return s
end

-- This replaces vis's default status line (same content, copied from vis-std.lua) with one extra part while completing.
local mode_names = {
	[vis.modes.NORMAL] = '', [vis.modes.OPERATOR_PENDING] = '',
	[vis.modes.VISUAL] = 'VISUAL', [vis.modes.VISUAL_LINE] = 'VISUAL-LINE',
	[vis.modes.INSERT] = 'INSERT', [vis.modes.REPLACE] = 'REPLACE',
}

vis.events.subscribe(vis.events.WIN_STATUS, function(win)
	if not M.config.statusline then return end
	local left_parts, right_parts = {}, {}
	local file, selection = win.file, win.selection

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

	local left = ' ' .. table.concat(left_parts, " » ") .. ' '
	local right = ' ' .. table.concat(right_parts, " « ") .. ' '

	if vis.mode == vis.modes.INSERT and vis.win == win then
		local room = (win.width or 80) - ulen(left) - ulen(right) - 6
		if room > 8 then
			local box = box_text(win, room)
			if box then left = ' ' .. table.concat(left_parts, " » ") .. " » " .. box .. ' ' end
		end
	end
	win:status(left, right)
end)

-- Warm the index
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	local lang = language_of(win)
	if lang then sync(slot_for(win, lang).idx, buffer_text(win.file)) end
end)

return M
