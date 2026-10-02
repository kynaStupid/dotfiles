-- Document-local completion engine (language-agnostic).
--
-- Stores only: the lines, and per line its tokens + lexer state.  Everything the
-- document "teaches" is derived by the language module's single analysis pass
-- whenever a completion is requested, so there is nothing to keep in sync on
-- edit.  Per-keystroke cost is one line re-lexed; per-completion cost is
-- O(tokens in the document).
--
-- A language module provides:
--   lex_line(text, state)            -> tokens, state_out
--   same_state(a, b)                 -> bool            (optional; default compares level/comment)
--   analyze(line_tokens, cursor)     -> model
--   prefix(text_before)              -> prefix, mode | nil
--   inside_literal(toks, st, before) -> bool
--   context(model, prefix, line, mode) -> spec | nil
--   candidates(spec, model)          -> { {text, kind, group, rank}, ... }
-- The engine owns matching and ranking (fuzzy), the language owns *what exists*.

local Index = {}
Index.__index = Index

-- Fuzzy matching
local function is_boundary(name, i)
	if i == 1 then return true end
	local p, c = name:sub(i - 1, i - 1), name:sub(i, i)
	if p:find("%W") then return true end
	if p:find("%l") and c:find("%u") then return true end
	return false
end

local NEG = -1e9

local function fuzzy(name, query)
	local n, m = #name, #query
	if m == 0 then return 0, true end
	if m > n then return nil end
	local nl, ql = name:lower(), query:lower()

	if nl:sub(1, m) == ql then
		local s = 1000 - (n - m)
		if name:sub(1, m) == query then s = s + 100 end
		return s, true
	end

	-- cheap reject: must be a subsequence
	local pos = 1
	for k = 1, m do
		pos = nl:find(ql:sub(k, k), pos, true)
		if not pos then return nil end
		pos = pos + 1
	end

	local prev, cur = {}, {}
	for i = 1, m do
		local qc = ql:sub(i, i)
		local run = NEG -- best (prev[k] + 2k) for k <= j-2
		for j = 1, n do
			local best = NEG
			if nl:sub(j, j) == qc then
				local bonus = 16
				local boundary = is_boundary(name, j)
				if boundary then bonus = bonus + 12 end
				if name:sub(j, j) == query:sub(i, i) then bonus = bonus + 2 end
				if i == 1 then
					if boundary then best = bonus - (j - 1) end
				else
					local from = NEG
					if j >= 2 and prev[j - 1] and prev[j - 1] > NEG then
						from = prev[j - 1] + 10
					end
					if run > NEG then from = math.max(from, run - 2 * (j - 1)) end
					if from > NEG then best = from + bonus end
				end
			end
			cur[j] = best
			if i > 1 and j >= 2 and prev[j - 1] and prev[j - 1] > NEG then
				run = math.max(run, prev[j - 1] + 2 * (j - 1))
			end
		end
		prev, cur = cur, {}
	end

	local top = NEG
	for j = 1, n do if prev[j] and prev[j] > top then top = prev[j] end end
	if top <= NEG then return nil end
	return top - (n - m) * 0.3, false
end
Index.fuzzy = fuzzy

local function same_state_default(a, b)
	if a == nil or b == nil then return a == b end
	return a.level == b.level and a.comment == b.comment
end

-- Replace `count` lines starting at `first` with `new_lines`. Downstream lines are re-lexed only while the lexer state keeps changing.
function Index:replace(first, count, new_lines)
	local same = self.lang.same_state or same_state_default
	for _ = 1, count do
		table.remove(self.lines, first)
		table.remove(self.info, first)
	end
	for k, line in ipairs(new_lines) do
		table.insert(self.lines, first + k - 1, line)
		table.insert(self.info, first + k - 1, { fresh = true })
	end
	local last_new = first + #new_lines - 1
	local i = first
	while i <= #self.lines do
		local state_in = i > 1 and self.info[i - 1].state_out or nil
		local rec = self.info[i]
		if i > last_new and not rec.fresh and same(rec.state_in, state_in) then break end
		local toks, state_out = self.lang.lex_line(self.lines[i], state_in)
		self.info[i] = { toks = toks, state_in = state_in, state_out = state_out }
		i = i + 1
	end
end

function Index:new_index() end

function Index.new(lang)
	return setmetatable({ lang = lang, lines = {}, info = {} }, Index)
end

function Index:set_text(text)
	local lines = {}
	for l in (text .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = l end
	self:replace(1, #self.lines, lines)
end

-- Rank the language's candidates against the typed prefix.
-- prefix matches  (group, exact case, rank, name)
-- fuzzy matches   (score, group, rank, name)
local function rank(items, prefix)
	local out = {}
	for _, it in ipairs(items) do
		if it.text ~= prefix then
			local score, is_prefix = fuzzy(it.text, prefix)
			if score then
				it.score, it.tier = score, is_prefix and 1 or 2
				it.exact = it.text:sub(1, #prefix) == prefix
				out[#out + 1] = it
			end
		end
	end
	table.sort(out, function(a, b)
		if a.tier ~= b.tier then return a.tier < b.tier end
		if a.tier == 2 and a.score ~= b.score then return a.score > b.score end
		if a.group ~= b.group then return a.group < b.group end
		if a.exact ~= b.exact then return a.exact end
		if a.rank ~= b.rank then return a.rank > b.rank end
		return a.text < b.text
	end)
	return out
end

-- Complete at line n, with `col` bytes of that line before the cursor.
-- Returns candidates (best first), prefix.
function Index:complete(n, col)
	local lang, text = self.lang, self.lines[n]
	if not text then return {}, "" end
	local before, after = text:sub(1, col), text:sub(col + 1)
	local state_in = self.info[n].state_in

	local toks_full, st = lang.lex_line(before, state_in)
	if lang.inside_literal(toks_full, st, before) then return {}, "" end

	local prefix, pmode = lang.prefix(before)
	if not prefix then return {}, "" end

	local before_wo = before:sub(1, #before - #prefix)
	local line_wo = before_wo .. after:sub(#after:match("^[%w_]*") + 1)

	local line_toks = {}
	for i = 1, #self.lines do line_toks[i] = self.info[i].toks end
	line_toks[n] = lang.lex_line(line_wo, state_in)

	local model = lang.analyze(line_toks, { line = n, col = #before_wo })
	local spec = lang.context(model, prefix, n, pmode)
	if not spec then return {}, prefix end
	return rank(lang.candidates(spec, model), prefix), prefix
end

return Index
