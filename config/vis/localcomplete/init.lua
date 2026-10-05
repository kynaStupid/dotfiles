-- localcomplete: document-local, syntax-aware completion for vis.
--
--   <Tab>    (insert mode) complete with the best candidate (the [highlighted] one)
--   <S-Tab>  (insert mode) insert a literal tab
--
-- While you type in insert mode, the fuzzy-ranked candidates are offered as a
-- segment of the status bar:   INSERT » foo.lua » [get_token_name] gtn_x +2
-- localcomplete does NOT own the status bar; it registers a segment with
-- statusline.lua (a separate file, so other plugins and your own config can
-- share the bar).  Without statusline.lua, <Tab> still works, you just don't
-- see the list.
--
-- It only ever suggests things the current document has shown it (see engine.lua).

local base = ...
local Index  = require(base .. ".engine")
local detect = require(base .. ".detect")

local M = {}

-- Config
M.config = {
	tab_fallback = true,
	max_items    = 5,
	budget_ms    = 50,      -- if analysing a file takes longer, the live list pauses for
	                        -- that file (<Tab> still works); see TODO "cache the model"
}

-- Languages
local languages = {
	lua = require(base .. ".lang_lua"),
	sh  = require(base .. ".lang_sh"),
	nix = require(base .. ".lang_nix"),
}

-- Re-checked on every use (cheap: 512 bytes)
local function language_of(win)
	local file = win.file
	local head = file:content(0, math.min(512, file.size)) or ""
	local key = detect.language_key(head, file.name or file.path, win.syntax)
	return key and languages[key]
end

-- Per-file index, kept in step with the buffer by diffing at use time.
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
	if a > na and a > nb then return end            -- nothing changed
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

-- Candidates at the cursor: { cands, prefix, pos } or nil.
-- Cached on (buffer text, cursor), so redraws that change nothing cost one string compare.
-- `force` (used by <Tab>) ignores the live-list budget.
local function compute(win, force)
	local lang = language_of(win)
	local sel = win.selection
	local pos = sel and sel.pos
	if not lang or not pos then return nil end

	local text = buffer_text(win.file)
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

-- <Tab> / <S-Tab>
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
	if not language_of(vis.win) then
		insert_tab()
	elseif not complete() and M.config.tab_fallback then
		insert_tab()
	end
end, "complete")

vis:map(vis.modes.INSERT, "<S-Tab>", insert_tab, "insert tab")

-- The status-bar segment
local function ulen(s)
	if utf8 then return utf8.len(s) or #s end
	return #s
end

-- "[best] alt alt +3"
local function format_items(res, room)
	local parts, used = {}, 0
	for i, c in ipairs(res.cands) do
		if i > M.config.max_items then break end
		local item = i == 1 and ("[" .. c.text .. "]") or c.text
		if i > 1 and used + ulen(item) + 1 > room then break end
		parts[#parts + 1] = item
		used = used + ulen(item) + 1
	end
	local s = table.concat(parts, " ")
	local more = #res.cands - #parts
	if more > 0 then s = s .. " +" .. more end
	return s
end

local has_statusline, statusline = pcall(require, "statusline")
if has_statusline and type(statusline) == "table" and statusline.add then
	statusline.add("localcomplete", function(win, ctx)
		if vis.mode ~= vis.modes.INSERT or vis.win ~= win or ctx.room <= 8 then return nil end
		local ok, res = pcall(compute, win, false)
		if ok and res and #res.cands > 0 then return format_items(res, ctx.room) end
	end)
else
	M.no_statusline = true
	vis.events.subscribe(vis.events.WIN_OPEN, function()
		vis:info("localcomplete: no statusline.lua, so the candidate list is hidden (Tab works)")
	end)
end

-- warm the index
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	local lang = language_of(win)
	if lang then sync(slot_for(win, lang).idx, buffer_text(win.file)) end
end)

return M
