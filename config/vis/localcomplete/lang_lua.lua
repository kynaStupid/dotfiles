-- Lua language support for the document-local completion engine.
--
-- A language module provides:
--   lex_line(text, state)         -> tokens, state_out   (strings/comments isolated)
--   analyze(line_tokens, cursor)  -> model               (ONE pass over the whole document:
--                                     blocks, scopes, declarations, members, globals)
--   prefix(text_before)           -> word being typed | nil
--   inside_literal(toks, state)   -> bool
--   context(model, prefix, line)  -> query spec | nil    (what is VALID at the cursor)
--
-- Scoping is lexical and purely syntactic: `local`, parameters, `for` variables
-- and `local function` names are declarations; blocks (function/do/if-branch/
-- loop/repeat) bound their visibility.  A name used with no visible declaration
-- is a global.  Member owners are keyed by the DECLARATION they resolve to, so
-- `a.x` in two different functions' parameters `a` are different owners.
--
-- The only "outside knowledge" is the keyword table: the minimum grammar.

local L = {}

local base = (...) and (...):match("^(.*)%.[^.]+$")
local Scope = require(base and (base .. ".scope") or "scope").Scope

local function set(list)
	local s = {}
	for _, v in ipairs(list) do s[v] = true end
	return s
end

local KEYWORDS = set {
	"and", "break", "do", "else", "elseif", "end", "false", "for", "function",
	"goto", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
	"true", "until", "while",
}
local VALUE_KW = set { "nil", "true", "false" }

-- keywords that make sense at a given syntactic position
local STATEMENT_KW = { "break", "do", "else", "elseif", "end", "for", "function",
	"goto", "if", "local", "repeat", "return", "until", "while" }
local EXPR_KW = { "false", "function", "nil", "not", "true" }
local ALL_KW = {}
for k in pairs(KEYWORDS) do ALL_KW[#ALL_KW + 1] = k end
table.sort(ALL_KW)

-- after these keywords a new statement may begin
local STMT_START_AFTER = set { "then", "do", "else", "repeat", "end" }

-- ------------------------------------------------------------------
-- 1. Lexer: one line at a time, carrying long-string/comment state
-- ------------------------------------------------------------------

function L.lex_line(text, state)
	local toks, n, i = {}, #text, 1

	local function push(type, s, e, open)
		toks[#toks + 1] = { type = type, text = text:sub(s, e), s = s, e = e, open = open or nil }
	end

	-- ts = token start, p = position of the opening '['
	local function long(ts, p, is_comment)
		local kind = is_comment and "comment" or "string"
		local level = #text:match("^%[(=*)%[", p)
		local close = "]" .. string.rep("=", level) .. "]"
		local _, e = text:find(close, p + level + 2, true)
		if e then
			push(kind, ts, e)
			return e + 1, nil
		end
		push(kind, ts, n, true)
		return n + 1, { level = level, comment = is_comment }
	end

	if state then                                    -- inside a multi-line construct
		local kind = state.comment and "comment" or "string"
		local close = "]" .. string.rep("=", state.level) .. "]"
		local _, e = text:find(close, 1, true)
		if not e then
			push(kind, 1, n, true)
			return toks, state
		end
		push(kind, 1, e)
		i, state = e + 1, nil
	end

	while i <= n do
		local c = text:sub(i, i)
		if c:find("^%s") then
			i = i + 1
		elseif text:sub(i, i + 1) == "--" then
			if text:find("^%-%-%[=*%[", i) then
				i, state = long(i, i + 2, true)
			else
				push("comment", i, n, true)          -- line comment runs to EOL
				i = n + 1
			end
		elseif c == '"' or c == "'" then
			local j, closed = i + 1, false
			while j <= n do
				local d = text:sub(j, j)
				if d == "\\" then j = j + 2
				elseif d == c then closed = true break
				else j = j + 1 end
			end
			if closed then push("string", i, j) i = j + 1
			else push("string", i, n, true) i = n + 1 end
		elseif c == "[" and text:find("^%[=*%[", i) then
			i, state = long(i, i, false)
		elseif c:find("^[%a_]") then
			local w = text:match("^[%w_]+", i)
			push(KEYWORDS[w] and "keyword" or "ident", i, i + #w - 1)
			i = i + #w
		elseif c:find("^%d") or text:find("^%.%d", i) then
			local w = text:match("^0[xX][%x%.]*", i)
				or text:match("^%d*%.?%d*", i)
			local exp = text:match("^[eE][+-]?%d+", i + #w)
			if exp then w = w .. exp end
			push("number", i, i + #w - 1)
			i = i + #w
		else
			local op = text:match("^%.%.%.", i) or text:match("^[=~<>]=", i)
				or text:match("^%.%.", i) or text:match("^//", i) or text:match("^::", i)
				or text:match("^<<", i) or text:match("^>>", i) or c
			push("op", i, i + #op - 1)
			i = i + #op
		end
	end
	return toks, state
end

local function significant(toks)
	local out = {}
	for _, t in ipairs(toks) do
		if t.type ~= "comment" then out[#out + 1] = t end
	end
	return out
end

local function is_op(t, text) return t and t.type == "op" and t.text == text end
local function is_kw(t, text) return t and t.type == "keyword" and t.text == text end

local function is_value_end(t)
	return t.type == "ident" or t.type == "number" or t.type == "string"
		or (t.type == "keyword" and VALUE_KW[t.text])
		or (t.type == "op" and (t.text == ")" or t.text == "]" or t.text == "}" or t.text == "..."))
end

-- `name(`, `name "str"`, `name {` on the same line
local function is_call(nxt, t)
	return nxt and nxt.line == t.line
		and (nxt.type == "string" or is_op(nxt, "(") or is_op(nxt, "{")) or false
end

-- ------------------------------------------------------------------
-- 2. Owner path: THE shared normalizer (analysis AND completion use it)
--      a.b.c -> "a", ".b.c"     a:b -> "a", ".b"     f().x -> "f", "()"
--      a[i].x -> "a", "[]"
-- k = index of the accessor token ('.' or ':'); chains may span lines because
-- toks is the whole document's token stream.  nil if the chain has no name root.
-- ------------------------------------------------------------------

local function owner_path(toks, k)
	local segs = {}                                   -- { text, suffix }
	local i = k - 1
	while true do
		local t = toks[i]
		if not t then break end
		if t.type == "ident" then
			table.insert(segs, 1, { t.text })
			if is_op(toks[i - 1], ".") or is_op(toks[i - 1], ":") then
				i = i - 2
			else
				break
			end
		elseif is_op(t, ")") or is_op(t, "]") then
			local close = t.text
			local open = close == ")" and "(" or "["
			local depth, j = 0, i
			while j >= 1 do
				local x = toks[j]
				if x.type == "op" then
					if x.text == close then depth = depth + 1
					elseif x.text == open then
						depth = depth - 1
						if depth == 0 then break end
					end
				end
				j = j - 1
			end
			if j < 1 then return nil end
			table.insert(segs, 1, { close == ")" and "()" or "[]", suffix = true })
			i = j - 1
		else
			return nil
		end
	end
	if #segs == 0 or segs[1].suffix then return nil end
	local rest = {}
	for idx = 2, #segs do
		local s = segs[idx]
		rest[#rest + 1] = s.suffix and s[1] or ("." .. s[1])
	end
	return segs[1][1], table.concat(rest)
end

-- owner key = what the root resolves to + the rest of the path.
--   local  -> "name@id"  (or the decl's own key, e.g. self(Class))
--   global -> "name"
local key_for = Scope.key_for

-- ------------------------------------------------------------------
-- 3. Analysis: one forward pass over the whole document
-- ------------------------------------------------------------------
-- line_toks[i] = tokens of line i.  cursor = { line, col }: the pass takes a
-- snapshot of "what is visible / what is expected" right before that point.

function L.analyze(line_toks, cursor)
	local flat = {}
	for ln, toks in ipairs(line_toks) do
		for _, t in ipairs(toks) do
			if t.type ~= "comment" then
				t.line = ln
				flat[#flat + 1] = t
			end
		end
	end

	local globals, members = {}, {}
	local sc = Scope.new()
	local stack = sc.stack
	local ds                      -- declaration-list state: what name-introducing list we're inside
	local fn_pending              -- function scope waiting for its '(' parameter list
	local until_line              -- a `repeat` body stays visible through its `until` line
	local snap
	local decl_func, skip = {}, {}

	-- bracket frames ("br") only track nesting; every other frame is a block scope
	local function push_scope(kind, await_do) return sc:push(kind, { await_do = await_do }) end
	local function top_scope()
		local _, f = sc:find(function(fr) return fr.kind ~= "br" end)
		return f
	end
	local function lookup(name) return sc:lookup(name) end
	local function declare(name, role, scope, line, key)
		return sc:declare(name, role, scope, line, key and { key = key } or nil)
	end
	local function pop_end()                          -- `end`: close nearest block
		local k = sc:find(function(fr) return fr.kind ~= "br" end)
		if k and k >= 2 then
			local kind = stack[k].kind
			sc:pop_to(k)
			if kind == "branch" and #stack > 1 and stack[#stack].kind == "if" then
				stack[#stack] = nil
			end
		end
	end
	local function pop_bracket(open)
		local k = sc:find(function(fr) return fr.kind == "br" and fr.ch == open end)
		if k and k >= 2 then sc:pop_to(k) end
	end
	local function pop_repeat()
		local k = sc:find(function(fr) return fr.kind ~= "br" end)
		if k and k >= 2 and stack[k].kind == "repeat" then sc:pop_to(k) end
	end
	local function add_member(key, name, call)
		local m = members[key]
		if not m then m = {} members[key] = m end
		local r = m[name]
		if not r then r = { n = 0, call = 0 } m[name] = r end
		r.n = r.n + 1
		if call then r.call = r.call + 1 end
	end
	local function owner_key(root, rest) return key_for(lookup(root), root, rest) end

	local function take_snap(ci)
		if until_line and cursor.line > until_line then pop_repeat() until_line = nil end
		snap = { ci = ci, visible = sc:visible(), declaring = (ds ~= nil and ds.awaiting) or false }
	end

	-- name-introducing lists: `local a, b`, `for k, v`, `function f(a, b)`
	local function step_decl(t)
		if ds.kind == "params" then
			if t.type == "ident" and ds.awaiting then
				declare(t.text, "var", ds.target, t.line)
				ds.awaiting = false
				return true
			end
			if is_op(t, ",") then ds.awaiting = true return true end
			if is_op(t, "...") then ds.awaiting = false return true end
			ds = nil                                  -- ')' (or garbage) ends the list
			return false
		end
		if ds.attrib then
			if is_op(t, ">") then ds.attrib = false end
			return true
		end
		if t.type == "ident" and ds.awaiting then
			declare(t.text, "var", ds.target or top_scope(), t.line)
			ds.awaiting = false
			return true
		end
		if is_op(t, ",") and not ds.awaiting then ds.awaiting = true return true end
		if is_op(t, "<") and not ds.awaiting and ds.kind == "local" then ds.attrib = true return true end
		ds = nil
		return false
	end

	local function on_ident(i, t)
		local prev, nxt = flat[i - 1], flat[i + 1]
		local pt = prev and prev.type == "op" and prev.text or nil
		local call = (decl_func[i] or is_call(nxt, t)) and true or false

		if pt == "." or pt == ":" then                -- member of an observed owner
			local root, rest = owner_path(flat, i - 1)
			if root then add_member(owner_key(root, rest), t.text, pt == ":" or call) end
			return
		end

		local top = stack[#stack]
		if top.kind == "br" and top.ch == "{" and (pt == "{" or pt == "," or pt == ";")
			and is_op(nxt, "=") then                  -- table field key, not a variable
			if top.owner then add_member(top.owner, t.text, is_kw(flat[i + 2], "function")) end
			return
		end

		local d = lookup(t.text)
		if d then
			if call then d.called = true end
		else
			local g = globals[t.text]
			if not g then g = { var = 0, func = 0 } globals[t.text] = g end
			local role = call and "func" or "var"
			g[role] = g[role] + 1
		end
	end

	for i, t in ipairs(flat) do
		if not snap and (t.line > cursor.line or (t.line == cursor.line and t.s > cursor.col)) then
			take_snap(i - 1)
		end
		if until_line and t.line > until_line then pop_repeat() until_line = nil end
		if fn_pending and not (t.type == "ident" or is_op(t, ".") or is_op(t, ":") or is_op(t, "(")) then
			fn_pending = nil
		end

		if ds and step_decl(t) then
			-- consumed as part of a declaration list
		elseif t.type == "keyword" then
			local k = t.text
			if k == "local" then
				if not is_kw(flat[i + 1], "function") then ds = { kind = "local", awaiting = true } end
			elseif k == "function" then
				ds = nil
				local is_local = is_kw(flat[i - 1], "local")
				local first, last, colon
				if flat[i + 1] and flat[i + 1].type == "ident" then
					first, last = i + 1, i + 1
					while (is_op(flat[last + 1], ".") or is_op(flat[last + 1], ":"))
						and flat[last + 2] and flat[last + 2].type == "ident" do
						if flat[last + 1].text == ":" then colon = last + 1 end
						last = last + 2
					end
					decl_func[last] = true
				end
				if is_local and first and first == last then      -- visible inside its own body
					declare(flat[first].text, "func", top_scope(), flat[first].line)
					skip[first] = true
				end
				local fscope = push_scope("function")
				if colon then                                     -- method: implicit `self`
					local root, rest = owner_path(flat, colon)
					if root then
						declare("self", "var", fscope, t.line, "self(" .. owner_key(root, rest) .. ")")
					end
				end
				fn_pending = fscope
			elseif k == "for" then
				local s = push_scope("loop", true)
				ds = { kind = "for", awaiting = true, target = s }
			elseif k == "while" then push_scope("loop", true)
			elseif k == "do" then
				local top = stack[#stack]
				if top.await_do then top.await_do = nil else push_scope("do") end
			elseif k == "if" then push_scope("if")
			elseif k == "then" then
				if stack[#stack].kind == "if" then push_scope("branch") end
			elseif k == "elseif" then
				if stack[#stack].kind == "branch" then stack[#stack] = nil end
			elseif k == "else" then
				if stack[#stack].kind == "branch" then stack[#stack] = nil end
				if stack[#stack].kind == "if" then push_scope("branch") end
			elseif k == "end" then pop_end()
			elseif k == "repeat" then push_scope("repeat")
			elseif k == "until" then until_line = t.line
			elseif k == "goto" then skip[i + 1] = true
			end
		elseif t.type == "op" then
			local x = t.text
			if x == "(" or x == "[" or x == "{" then
				local frame = { ch = x }
				if x == "(" and fn_pending then
					ds = { kind = "params", awaiting = true, target = fn_pending }
					fn_pending = nil
				elseif x == "{" and is_op(flat[i - 1], "=")
					and flat[i - 2] and flat[i - 2].type == "ident" then
					local root, rest = owner_path(flat, i - 1)     -- `name = {` : fields belong to name
					if root then frame.owner = owner_key(root, rest) end
				end
				sc:push("br", frame)
			elseif x == ")" then pop_bracket("(")
			elseif x == "]" then pop_bracket("[")
			elseif x == "}" then pop_bracket("{")
			elseif x == "::" and flat[i + 1] and flat[i + 1].type == "ident" and is_op(flat[i + 2], "::") then
				skip[i + 1] = true
			end
		elseif t.type == "ident" and not skip[i] then
			on_ident(i, t)
		end
	end
	if not snap then take_snap(#flat) end

	return { flat = flat, globals = globals, members = members, snap = snap }
end

-- ------------------------------------------------------------------
-- 4. Context: what is the cursor completing, and what categories apply?
-- ------------------------------------------------------------------

function L.prefix(before)
	local w = before:match("[%a_][%w_]*$") or ""
	if w ~= "" and before:sub(1, #before - #w):match("[%w_]$") then return nil end  -- 1abc
	return w, "word"
end

function L.same_state(a, b)
	if a == nil or b == nil then return a == b end
	return a.level == b.level and a.comment == b.comment
end

function L.inside_literal(toks, state)
	if state then return true end
	local last = toks[#toks]
	return (last and (last.type == "string" or last.type == "comment") and last.open) and true or false
end

-- model: from analyze() on the document with the word under the cursor removed
function L.context(model, prefix, cursor_line)
	local flat, snap = model.flat, model.snap
	local last = flat[snap.ci]

	if is_op(last, ".") or is_op(last, ":") then       -- member access (even across lines)
		local root, rest = owner_path(flat, snap.ci)
		if not root then return nil end
		return { type = "members", key = key_for(snap.visible[root], root, rest),
			call_only = last.text == ":" }
	end

	if prefix == "" then return nil end                -- whitespace never triggers

	if is_kw(last, "local") or is_kw(last, "function") or is_kw(last, "goto")
		or is_op(last, "::") or snap.declaring then
		return nil                                     -- introducing a name
	end

	local keywords
	if not last or is_op(last, ";") or (last.type == "keyword" and STMT_START_AFTER[last.text]) then
		keywords = STATEMENT_KW
	elseif is_value_end(last) then
		if last.line == cursor_line then               -- `x = foo f|` : no names after a value
			return { type = "free", names = false, keywords = ALL_KW }
		end
		keywords = STATEMENT_KW                        -- value ended the previous line: new statement
	else
		keywords = EXPR_KW
	end
	return { type = "free", names = true, keywords = keywords }
end

-- ------------------------------------------------------------------
-- 5. Candidates: everything that EXISTS for a spec (the engine ranks them)
-- ------------------------------------------------------------------
-- groups: 1 = locals visible here / members, 2 = globals seen in the document, 3 = keywords

function L.candidates(spec, model)
	local out = {}
	local function add(text, kind, group, rank)
		out[#out + 1] = { text = text, kind = kind, group = group, rank = rank }
	end
	if spec.type == "members" then
		for name, r in pairs(model.members[spec.key] or {}) do
			if not spec.call_only or r.call > 0 then add(name, "member", 1, r.n) end
		end
	else
		if spec.names then
			local vis = model.snap.visible
			for name, d in pairs(vis) do               -- innermost scope, then most recent first
				add(name, (d.role == "func" or d.called) and "function" or "variable",
					1, d.depth * 1e6 + d.line)
			end
			for name, g in pairs(model.globals) do
				if not vis[name] then
					add(name, (g.func > 0 and g.var == 0) and "function" or "variable",
						2, g.var + g.func)
				end
			end
		end
		for _, kw in ipairs(spec.keywords or {}) do add(kw, "keyword", 3, 0) end
	end
	return out
end

return L
