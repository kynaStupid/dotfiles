-- Shared helpers for language analyzers: a lexical scope stack and bracket matching.
-- (lang_lua / lang_sh predate this and keep their own copies.)

local Scope = {}
Scope.__index = Scope

function Scope.new()
	local s = setmetatable({ stack = {}, next_id = 0 }, Scope)
	s.stack[1] = { kind = "file", decls = {}, depth = 1 }
	return s
end

function Scope:top() return self.stack[#self.stack] end

-- Every frame can hold declarations; `kind` says what closes it.
function Scope:push(kind, fields)
	local f = fields or {}
	f.kind, f.decls, f.depth = kind, f.decls or {}, #self.stack + 1
	self.stack[#self.stack + 1] = f
	return f
end

-- remove frames k..top (never the file frame)
function Scope:pop_to(k)
	for j = #self.stack, math.max(k, 2), -1 do self.stack[j] = nil end
end

-- index of the nearest frame (from the top) satisfying pred
function Scope:find(pred)
	for k = #self.stack, 1, -1 do
		if pred(self.stack[k]) then return k, self.stack[k] end
	end
end

function Scope:declare(name, role, frame, line, extra)
	self.next_id = self.next_id + 1
	local d = extra or {}
	d.name, d.id, d.role, d.line, d.depth = name, self.next_id, role, line or 0, frame.depth
	frame.decls[name] = d
	return d
end

function Scope:lookup(name)
	for k = #self.stack, 1, -1 do
		local d = self.stack[k].decls[name]
		if d then return d end
	end
end

-- name -> declaration, innermost wins
function Scope:visible()
	local v = {}
	for k = 1, #self.stack do
		for name, d in pairs(self.stack[k].decls) do v[name] = d end
	end
	return v
end

-- owner key: what the root name resolves to, plus the rest of the path
function Scope.key_for(decl, root, rest)
	local base = decl and (decl.key or (root .. "@" .. decl.id)) or root
	return base .. (rest or "")
end

-- ------------------------------------------------------------------
-- Bracket matching over a flat token list.  opens/closes: sets of token texts.
-- Returns match[i] = index of the partner bracket (both directions).
-- ------------------------------------------------------------------
local M = {}

function M.match_brackets(toks, opens, closes)
	local match, st = {}, {}
	for i, t in ipairs(toks) do
		if t.type == "op" then
			if opens[t.text] then st[#st + 1] = i
			elseif closes[t.text] then
				local o = st[#st]
				if o then match[o], match[i] = i, o st[#st] = nil end
			end
		end
	end
	return match
end

function M.set(list)
	local s = {}
	for _, v in ipairs(list) do s[v] = true end
	return s
end

function M.ulen(s)
	if utf8 then return utf8.len(s) or #s end
	return #s
end

M.Scope = Scope
return M
