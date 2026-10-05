-- Nix language support for the document-local completion engine.
--
-- What the document can teach us here:
--   locals     let-bindings, rec-set attributes, function arguments (incl. { a, b ? 1, ... }@args)
--   members    attribute paths:  a.b.c  /  a ? b  /  `a.b = v;` inside a set  /  inherit (src) x
--              /  `with src; [ x y ]` (bare names inside `with src;` are members of src)
--   globals    names used but never bound (builtins, lib, ...) -- only once they appear
-- Owners are keyed by the DECLARATION they resolve to, so `pkgs.x` in two different
-- functions' `pkgs` arguments are different owners.

local base = (...) and (...):match("^(.*)%.[^.]+$")
local function sib(name) return require(base and (base .. "." .. name) or name) end
local U = sib("scope")
local Scope, set = U.Scope, U.set

local N = {}

local KEYWORDS = set { "if", "then", "else", "let", "in", "with", "rec", "inherit", "assert", "or",
	"true", "false", "null" }
local VALUE_KW = set { "true", "false", "null" }
local EXPR_KW = { "assert", "false", "if", "let", "null", "rec", "true", "with" }
local CONT_KW = { "else", "in", "or", "then" }
local HEAD_KW = { "inherit" }
local OPS = { "...", "//", "++", "->", "==", "!=", "<=", ">=", "&&", "||" }

-- ------------------------------------------------------------------
-- 1. Lexer.  State = { ctx = stack of "str" | "istr" | "interp" | "brace" | "comment" }
-- ------------------------------------------------------------------

function N.lex_line(text, state)
	local toks, n = {}, #text
	local ctx = {}
	if state then for k, c in ipairs(state.ctx) do ctx[k] = c end end
	local function push(type, s, e, extra)
		local t = { type = type, text = text:sub(s, e), s = s, e = e }
		if extra then for k, v in pairs(extra) do t[k] = v end end
		toks[#toks + 1] = t
	end

	local i, str_start, cstart = 1, nil, nil
	while i <= n do
		local top = ctx[#ctx]
		if top == "comment" then
			local start = cstart or i
			cstart = nil
			local a, b = text:find("*/", i, true)
			if a then push("comment", start, b) table.remove(ctx) i = b + 1
			else push("comment", start, n, { open = true }) i = n + 1 end
		elseif top == "str" or top == "istr" then
			local start = str_start or i
			str_start = nil
			local j, closed, interp = i, false, false
			while j <= n do
				local c = text:sub(j, j)
				if top == "str" then
					if c == "\\" then j = j + 2
					elseif c == '"' then closed = true break
					elseif c == "$" and text:sub(j + 1, j + 1) == "{" then interp = true break
					else j = j + 1 end
				else
					if c == "'" and text:sub(j + 1, j + 1) == "'" then
						local nx = text:sub(j + 2, j + 2)
						if nx == "'" or nx == "$" or nx == "\\" then j = j + 3
						else closed = true j = j + 1 break end
					elseif c == "$" and text:sub(j + 1, j + 1) == "{" then interp = true break
					else j = j + 1 end
				end
			end
			if closed then push("string", start, j) table.remove(ctx) i = j + 1
			elseif interp then
				if j - 1 >= start then push("string", start, j - 1) end
				table.insert(ctx, "interp")
				push("op", j, j + 1)
				i = j + 2
			else
				push("string", start, n, { open = true })
				i = n + 1
			end
		else
			local c = text:sub(i, i)
			local two = text:sub(i, i + 1)
			if c:find("%s") then i = i + 1
			elseif c == "#" then push("comment", i, n, { open = true }) i = n + 1
			elseif two == "/*" then cstart = i table.insert(ctx, "comment") i = i + 2
			elseif c == '"' then str_start = i table.insert(ctx, "str") i = i + 1
			elseif two == "''" then str_start = i table.insert(ctx, "istr") i = i + 2
			elseif two == "${" then table.insert(ctx, "interp") push("op", i, i + 1) i = i + 2
			elseif c == "{" then
				if top == "interp" or top == "brace" then table.insert(ctx, "brace") end
				push("op", i, i)
				i = i + 1
			elseif c == "}" then
				if top == "brace" or top == "interp" then table.remove(ctx) end
				push("op", i, i)
				i = i + 1
			else
				local p = text:match("^<[%w._+%-/]+>", i) or text:match("^~/[%w._+%-/~]*", i)
					or text:match("^%.%.?/[%w._+%-/~]*", i)
					or (c == "/" and text:match("^/[%w._+%-~][%w._+%-/~]*", i))
					or text:match("^%a[%w+.%-]*://[^%s;,%)%]}\"]*", i)
				if p then push("path", i, i + #p - 1) i = i + #p
				elseif c:find("%d") then
					local w = text:match("^%d+%.?%d*", i)
					local e = text:match("^[eE][+-]?%d+", i + #w)
					if e then w = w .. e end
					push("number", i, i + #w - 1)
					i = i + #w
				elseif c:find("[%a_]") then
					local w = text:match("^[%a_][%w_'%-]*", i)
					local after = text:sub(i + #w, i + #w + 1)
					if after:find("^/[%w._+%-~]") then          -- foo/bar is a path
						local q = text:match("^[%w_'%-]+/[%w._+%-/~]*", i)
						push("path", i, i + #q - 1)
						i = i + #q
					else
						push(KEYWORDS[w] and "keyword" or "ident", i, i + #w - 1)
						i = i + #w
					end
				else
					local op
					for _, o in ipairs(OPS) do
						if text:sub(i, i + #o - 1) == o then op = o break end
					end
					op = op or c
					push("op", i, i + #op - 1)
					i = i + #op
				end
			end
		end
	end
	if #ctx == 0 then return toks, nil end
	return toks, { ctx = ctx }
end

function N.same_state(a, b)
	if a == nil or b == nil then return a == b end
	if #a.ctx ~= #b.ctx then return false end
	for k = 1, #a.ctx do if a.ctx[k] ~= b.ctx[k] then return false end end
	return true
end

-- ------------------------------------------------------------------
-- 2. Owner path:  a.b.c -> "a", ".b.c"     (chains may span lines)
-- k = index of the accessor token ('.' or '?').  Dynamic parts (${...}) give up.
-- ------------------------------------------------------------------
local function is_op(t, x) return t and t.type == "op" and t.text == x end

local function owner_path(toks, k)
	local segs = {}
	local i = k - 1
	while true do
		local t = toks[i]
		if not t or t.type ~= "ident" then return nil end
		table.insert(segs, 1, t.text)
		if is_op(toks[i - 1], ".") then i = i - 2 else break end
	end
	local rest = {}
	for idx = 2, #segs do rest[#rest + 1] = "." .. segs[idx] end
	return segs[1], table.concat(rest)
end

-- ------------------------------------------------------------------
-- 3. Analysis
-- ------------------------------------------------------------------
local OPEN = set { "(", "[", "{", "${" }
local CLOSE = set { ")", "]", "}" }

function N.analyze(line_toks, cursor)
	local flat = {}
	for ln, toks in ipairs(line_toks) do
		for _, t in ipairs(toks) do
			if t.type ~= "comment" then t.line = ln flat[#flat + 1] = t end
		end
	end
	local n = #flat
	local match = U.match_brackets(flat, OPEN, CLOSE)

	-- let ... in pairing; which '{' open a function pattern ( {a, b}: / {a}@x: )
	local let_in, is_pattern = {}, {}
	do
		local ls = {}
		for i, t in ipairs(flat) do
			if t.type == "keyword" then
				if t.text == "let" then ls[#ls + 1] = i
				elseif t.text == "in" and #ls > 0 then let_in[table.remove(ls)] = i end
			elseif t.type == "op" and t.text == "{" and match[i] then
				local nx = flat[match[i] + 1]
				if is_op(nx, ":") or is_op(nx, "@") then is_pattern[i] = true end
			end
		end
	end

	-- binding heads in [a, b] at depth 0:  name = ...   name.path = ...   inherit [(src)] names;
	local function scan_bindings(a, b)
		local out, i, start = {}, a, true
		while i <= b do
			local t, step = flat[i], 1
			if t.type == "op" and OPEN[t.text] and match[i] then
				i, start, step = match[i], false, 1
			elseif is_op(t, ";") then start = true
			elseif start then
				start = false
				if t.type == "keyword" and t.text == "inherit" then
					local j = i + 1
					if is_op(flat[j], "(") and match[j] then j = match[j] + 1 end
					while j <= b and not is_op(flat[j], ";") do
						if flat[j].type == "ident" then out[#out + 1] = { name = flat[j].text, idx = j } end
						j = j + 1
					end
					i, step, start = j, 0, false
				elseif t.type == "ident" then
					local j = i
					while is_op(flat[j + 1], ".") and flat[j + 2] do j = j + 2 end
					if is_op(flat[j + 1], "=") then out[#out + 1] = { name = t.text, idx = i } end
				end
			end
			i = i + step
		end
		return out
	end

	local sc = Scope.new()
	local stack = sc.stack
	local globals, members = {}, {}
	local skip, snap, prev = {}, nil, nil
	local bcount = 0
	local bind_frame = nil              -- set when the next token starts a binding
	local head = nil                    -- binding head being read: { frame, owner, path, let }
	local pending_owner = nil           -- owner key for the next set literal
	local pending_with = nil
	local inherit_ctx = nil

	local function add_member(key, name)
		local m = members[key]
		if not m then m = {} members[key] = m end
		m[name] = (m[name] or 0) + 1
	end
	local function innermost_with()
		for k = #stack, 1, -1 do if stack[k].kind == "with" then return stack[k] end end
	end
	local function root_key(root, rest)
		local d = sc:lookup(root)
		if d then return Scope.key_for(d, root, rest) end
		local w = innermost_with()
		if w and w.owner then return w.owner .. "." .. root .. rest end
		return root .. rest
	end
	local function end_exprs()
		while true do
			local f = stack[#stack]
			if (f.kind == "lambda" or f.kind == "with" or (f.kind == "let" and f.phase == "body"))
				and f.bdepth == bcount then
				stack[#stack] = nil
			else break end
		end
	end
	local function bind_target()          -- frame that owns bindings at the current position
		local f = stack[#stack]
		if f.kind == "set" or f.kind == "rec" or (f.kind == "let" and f.phase == "bindings") then return f end
	end

	local function take_snap(ci)
		local withs = {}
		for k = #stack, 1, -1 do
			if stack[k].kind == "with" and stack[k].owner then withs[#withs + 1] = stack[k].owner end
		end
		local top = stack[#stack]
		local last = flat[ci]
		snap = {
			ci = ci, visible = sc:visible(), withs = withs,
			pattern = top.kind == "br" and top.pattern or false,
			pattern_name = top.kind == "br" and top.pattern and (is_op(last, "{") or is_op(last, ",")) or false,
			inherit = inherit_ctx and { src = inherit_ctx.src } or nil,
		}
		if head then
			snap.head = { owner = head.owner, path = { table.unpack(head.path) }, let = head.let }
		elseif bind_frame then
			snap.bind = { kind = bind_frame.kind, owner = bind_frame.owner }
		end
	end

	local function use_name(name)
		if sc:lookup(name) then return end
		local w = innermost_with()
		if w then
			if w.owner then add_member(w.owner, name) end
		else
			globals[name] = (globals[name] or 0) + 1
		end
	end

	-- finish a binding head `a.b.c =`: teach members, remember the value's owner
	local function finish_head(i)
		local f, path = head.frame, head.path
		local owner
		if head.let then
			local d = f.decls[path[1]]
			owner = Scope.key_for(d, path[1], "")
		else
			owner = f.owner
			add_member(owner, path[1])
			owner = owner .. "." .. path[1]
		end
		for k = 2, #path do
			add_member(owner, path[k])
			owner = owner .. "." .. path[k]
		end
		local nx = flat[i + 1]
		if is_op(nx, "{") or (nx and nx.type == "keyword" and nx.text == "rec") then pending_owner = owner end
		head = nil
	end

	for i, t in ipairs(flat) do
		if not snap and (t.line > cursor.line or (t.line == cursor.line and t.s > cursor.col)) then
			take_snap(i - 1)
		end
		local starting = bind_frame
		bind_frame = nil
		if starting and not (t.type == "ident" or (t.type == "keyword" and t.text == "inherit")) then
			starting = nil
		end

		local ty, x = t.type, t.text
		if ty == "op" then
			if head and x ~= "." then
				if x == "=" then finish_head(i) else head = nil end
			end
			if x == "(" or x == "[" or x == "{" or x == "${" then
				if x == "{" and is_pattern[i] then
					local lam = sc:push("lambda", { bdepth = bcount })
					local close = match[i]
					local j, startel = i + 1, true
					while j < close do
						local e = flat[j]
						if e.type == "op" and OPEN[e.text] and match[j] then j = match[j] startel = false
						elseif is_op(e, ",") then startel = true
						else
							if startel and e.type == "ident" then
								sc:declare(e.text, "var", lam, e.line)
								skip[j] = true
							end
							startel = false
						end
						j = j + 1
					end
					if is_op(flat[close + 1], "@") and flat[close + 2] and flat[close + 2].type == "ident" then
						sc:declare(flat[close + 2].text, "var", lam, flat[close + 2].line)
						skip[close + 2] = true
					end
					if is_op(flat[i - 1], "@") and flat[i - 2] and flat[i - 2].type == "ident" then
						sc:declare(flat[i - 2].text, "var", lam, flat[i - 2].line)
					end
					sc:push("br", { closer = true, pattern = true })
				elseif x == "{" then
					local is_rec = prev and prev.type == "keyword" and prev.text == "rec"
					local owner = pending_owner or ("set#" .. i)
					pending_owner = nil
					local f = sc:push(is_rec and "rec" or "set", { closer = true, owner = owner })
					if is_rec and match[i] then
						for _, b in ipairs(scan_bindings(i + 1, match[i] - 1)) do
							sc:declare(b.name, "var", f, flat[b.idx].line)
						end
					end
					bind_frame = f
				else
					sc:push("br", { closer = true })
				end
				bcount = bcount + 1
			elseif CLOSE[x] then
				local k = sc:find(function(f) return f.closer end)
				if k then sc:pop_to(k) bcount = bcount - 1 end
				if inherit_ctx and inherit_ctx.semi == nil then inherit_ctx = nil end
			elseif x == ";" then
				if pending_with and pending_with.semi == i then
					sc:push("with", { owner = pending_with.owner, bdepth = bcount })
					pending_with = nil
				else
					end_exprs()
					if inherit_ctx and inherit_ctx.semi == i then inherit_ctx = nil end
				end
				bind_frame = bind_target()
			elseif x == "," then
				end_exprs()
			elseif x == "?" then
				local top = stack[#stack]
				if not (top.kind == "br" and top.pattern) then
					local root, rest = owner_path(flat, i)
					local nx = flat[i + 1]
					if root and nx and nx.type == "ident" then
						add_member(root_key(root, rest), nx.text)
						skip[i + 1] = true
					end
				end
			end
		elseif ty == "keyword" then
			if x == "let" then
				local f = sc:push("let", { phase = "bindings", bdepth = bcount })
				local stop = (let_in[i] or (n + 1)) - 1
				for _, b in ipairs(scan_bindings(i + 1, stop)) do
					sc:declare(b.name, "var", f, flat[b.idx].line)
				end
				bind_frame = f
			elseif x == "in" then
				local k, f = sc:find(function(fr) return fr.kind == "let" and fr.phase == "bindings" end)
				if f then f.phase = "body" end
			elseif x == "with" then
				local j = i + 1
				while j <= n and not is_op(flat[j], ";") do
					if flat[j].type == "op" and OPEN[flat[j].text] and match[j] then j = match[j] end
					j = j + 1
				end
				local root, rest
				local ok = true
				for q = i + 1, j - 1 do
					local e = flat[q]
					if not ((e.type == "ident" and (q == i + 1 or is_op(flat[q - 1], "."))) or is_op(e, ".")) then ok = false end
				end
				local owner
				if ok and j > i + 1 then
					local r, rs = owner_path(flat, j)
					if r then owner = root_key(r, rs) end
				end
				pending_with = { semi = j, owner = owner }
			elseif x == "inherit" then
				local j, src = i + 1, nil
				if is_op(flat[j], "(") and match[j] then
					local r, rs = owner_path(flat, match[j])
					if r then src = root_key(r, rs) end
					j = match[j] + 1
				end
				local frame = bind_target()
				while j <= n and not is_op(flat[j], ";") do
					local e = flat[j]
					if e.type == "ident" then
						skip[j] = true
						if src then add_member(src, e.text) else use_name(e.text) end
						if frame and frame.kind ~= "let" then add_member(frame.owner, e.text) end
					end
					j = j + 1
				end
				inherit_ctx = { src = src, semi = j }
			end
		elseif ty == "ident" and not skip[i] then
			local nx = flat[i + 1]
			if head then
				if is_op(prev, ".") or #head.path == 0 then head.path[#head.path + 1] = x end
			elseif starting then
				local f = starting
				head = { frame = f, owner = f.owner, path = { x }, let = (f.kind == "let") }
			elseif is_op(prev, ".") then
				local root, rest = owner_path(flat, i - 1)
				if root then add_member(root_key(root, rest), x) end
			elseif is_op(nx, ":") and not (flat[i + 2] and is_op(flat[i + 2], ":")) then
				local lam = sc:push("lambda", { bdepth = bcount })
				sc:declare(x, "var", lam, t.line)
			elseif is_op(nx, "@") and is_op(flat[i + 2], "{") then
				-- args@{ ... }: declared when the pattern opens
			else
				use_name(x)
			end
		end
		prev = t
	end
	if not snap then take_snap(n) end

	return { flat = flat, globals = globals, members = members, snap = snap }
end

-- ------------------------------------------------------------------
-- 4. Prefix / literal / context
-- ------------------------------------------------------------------

function N.prefix(before)
	local w = before:match("[%a_][%w_'%-]*$") or ""
	local rest = before:sub(1, #before - #w)
	if rest:sub(-1) == "/" then return nil end               -- inside a path
	if w ~= "" and rest:match("[%w_]$") then return nil end
	return w, "word"
end

function N.word_after(after) return after:match("^[%w_'%-]*") end

function N.inside_literal(toks, st)
	local last = toks[#toks]
	if last and last.type == "comment" then return true end
	if st then
		local top = st.ctx[#st.ctx]
		if top == "str" or top == "istr" or top == "comment" then return true end
	end
	return false
end

local function member_key(model, snap)
	local last = model.flat[snap.ci]
	if snap.head then
		local key = snap.head.owner
		if snap.head.let then
			local d = snap.visible[snap.head.path[1]]
			key = Scope.key_for(d, snap.head.path[1], "")
			for k = 2, #snap.head.path do key = key .. "." .. snap.head.path[k] end
		else
			for _, p in ipairs(snap.head.path) do key = key .. "." .. p end
		end
		return key
	end
	local root, rest = owner_path(model.flat, snap.ci)
	if not root then return nil end
	local d = snap.visible[root]
	if d then return Scope.key_for(d, root, rest) end
	if snap.withs[1] then return snap.withs[1] .. "." .. root .. rest end
	return root .. rest
end

function N.context(model, prefix, cursor_line, mode)
	local snap = model.snap
	local last = model.flat[snap.ci]

	if is_op(last, ".") or (is_op(last, "?") and not snap.pattern) then
		local key = member_key(model, snap)
		if not key then return nil end
		return { type = "members", key = key }
	end
	if prefix == "" then return nil end
	if snap.pattern_name then return nil end                      -- naming an argument
	if snap.head then return nil end
	if snap.bind then
		if snap.bind.kind == "set" or snap.bind.kind == "rec" then
			return { type = "members", key = snap.bind.owner, keywords = HEAD_KW }
		end
		return { type = "none", keywords = HEAD_KW }               -- a new let-binding name
	end
	if snap.inherit then
		if snap.inherit.src then return { type = "members", key = snap.inherit.src } end
		return { type = "expr", keywords = {} }
	end

	local value_before = last and (last.type == "ident" or last.type == "number" or last.type == "string"
		or last.type == "path" or (last.type == "keyword" and VALUE_KW[last.text])
		or (last.type == "op" and (last.text == ")" or last.text == "]" or last.text == "}")))
	return { type = "expr", keywords = value_before and CONT_KW or EXPR_KW }
end

function N.candidates(spec, model)
	local out, snap = {}, model.snap
	local function add(text, kind, group, rank)
		out[#out + 1] = { text = text, kind = kind, group = group, rank = rank }
	end
	if spec.type == "members" then
		for name, n in pairs(model.members[spec.key] or {}) do add(name, "member", 1, n) end
	elseif spec.type == "expr" then
		for name, d in pairs(snap.visible) do add(name, "variable", 1, d.depth * 1e6 + d.line) end
		for _, owner in ipairs(snap.withs) do
			for name, n in pairs(model.members[owner] or {}) do
				if not snap.visible[name] then add(name, "member", 2, n) end
			end
		end
		for name, n in pairs(model.globals) do
			if not snap.visible[name] then add(name, "variable", 3, n) end
		end
	end
	for _, kw in ipairs(spec.keywords or {}) do add(kw, "keyword", 4, 0) end
	return out
end

return N
