-- sh/bash language support for the document-local completion engine.
--
-- What the document can teach us here, and where it is valid:
--   command    a word in command position (also: functions defined in the file)
--   variable   assigned or referenced names; `local`/`declare` are function-scoped
--   option     a `-x` / `--long` word, remembered PER COMMAND   (git --amend)
--   subcommand the first plain argument, remembered PER COMMAND (git commit)
-- Suggested only where that role is syntactically valid:
--   command position -> commands, functions, keywords
--   after $ / ${     -> variables
--   after `cmd -`    -> options previously seen with cmd
--   first argument   -> subcommands previously seen with cmd
--   anything else (later arguments, paths, redirect targets, case patterns,
--   strings, comments, heredoc bodies, names being declared) -> nothing.

local S = {}

local base = (...) and (...):match("^(.*)%.[^.]+$")
local Scope = require(base and (base .. ".scope") or "scope").Scope

local function set(list) local s = {} for _, v in ipairs(list) do s[v] = true end return s end

local OPS = {
	"<<<", "<<-", ";;&", "&>>",
	"<<", ">>", "&>", ">&", "<&", ">|", "<>", "&&", "||", ";;", ";&", "|&", "<(", ">(",
	"|", "&", ";", "<", ">",
}
local CMD_KEYWORDS = { "case", "do", "done", "elif", "else", "esac", "fi", "for",
	"function", "if", "select", "then", "time", "until", "while" }
local DECL = { ["local"] = "local", declare = "local", typeset = "local",
	export = "global", readonly = "global", unset = "unset", read = "read", getopts = "getopts" }
local STAY_CMD = set { "if", "elif", "while", "until", "then", "else", "do", "!", "time", "coproc" }

local function scan_vars(s)
	local vars = {}
	for name in s:gmatch("%$([%a_][%w_]*)") do vars[#vars + 1] = name end
	for name in s:gmatch("%${[!#]?([%a_][%w_]*)") do vars[#vars + 1] = name end
	return vars
end

-- ------------------------------------------------------------------
-- 1. Lexer.  State = { ctx = stack of "sq"|"dq"|"cmd"|"bt"|"paren"|"arith"|"aparen",
--                      hd = active heredoc, pending = heredocs opened on this line }
-- ------------------------------------------------------------------

function S.lex_line(text, state)
	local toks, n = {}, #text
	local ctx, hd, pending = {}, nil, nil
	local started_in_str = false
	if state then
		for k, c in ipairs(state.ctx) do ctx[k] = c end
		hd = state.hd
		if state.pending then
			pending = {}
			for k, p in ipairs(state.pending) do pending[k] = p end
		end
		local top = ctx[#ctx]
		started_in_str = (top == "sq" or top == "dq")
	end

	local function push(type, s, e, extra)
		local t = { type = type, text = text:sub(s, e), s = s, e = e }
		if extra then for k, v in pairs(extra) do t[k] = v end end
		toks[#toks + 1] = t
		return t
	end
	local function out_state()
		if pending and #pending == 0 then pending = nil end
		if #ctx == 0 and not hd and not pending then return nil end
		return { ctx = ctx, hd = hd, pending = pending }
	end

	-- heredoc body line
	if hd then
		local cmp = hd.strip and (text:gsub("^\t+", "")) or text
		if cmp == hd.delim then
			hd = nil
			if pending and #pending > 0 then hd = table.remove(pending, 1) end
			return toks, out_state()
		end
		local t = push("string", 1, n, { contd = true, open = true, heredoc = true, adj_prev = true })
		if hd.expand then t.vars = scan_vars(text) end
		return toks, out_state()
	end

	local i = 1
	local sq_start, dq_start, resume_dq = nil, nil, false

	local function pop_sub()
		table.remove(ctx)
		if ctx[#ctx] == "dq" then resume_dq = true end
	end

	-- `$...` : returns true if consumed
	local function dollar()
		local nx = text:sub(i + 1, i + 1)
		if nx == "(" then
			if text:sub(i + 2, i + 2) == "(" then
				table.insert(ctx, "arith") push("op", i, i + 2) i = i + 3
			else
				table.insert(ctx, "cmd") push("op", i, i + 1) i = i + 2
			end
			return true
		elseif nx == "{" then
			local nm = text:match("^%${[!#]?([%a_][%w_]*)", i)
			local depth, k = 1, i + 2
			while k <= n and depth > 0 do
				local ch = text:sub(k, k)
				if ch == "{" then depth = depth + 1 elseif ch == "}" then depth = depth - 1 end
				k = k + 1
			end
			push("var", i, k - 1, { name = nm })
			i = k
			return true
		elseif nx == "'" then
			sq_start = i
			table.insert(ctx, "sq")
			i = i + 2
			return true
		end
		local nm = text:match("^%$([%a_][%w_]*)", i)
		if nm then
			push("var", i, i + #nm, { name = nm })
			i = i + 1 + #nm
			return true
		end
		if nx ~= "" and nx:find("[%d@*#?$!%-]") then
			push("var", i, i + 1, {})
			i = i + 2
			return true
		end
		return false
	end

	local function word()
		local j = i
		while j <= n do
			local c = text:sub(j, j)
			if c:find("[%s;|&<>()'\"`]") then break end
			if c == "$" then
				local nx = text:sub(j + 1, j + 1)
				if nx ~= "" and nx:find("[%a_{(%d@*#?$!'%-]") then break end
				j = j + 1
			elseif c == "\\" then j = j + 2
			else j = j + 1 end
		end
		if j > n + 1 then j = n + 1 end
		if j == i then j = i + 1 end
		push("word", i, j - 1)
		i = j
	end

	local function heredoc_op(op)
		local sp = text:match("^%s*", i)
		i = i + #sp
		local delim, expand
		local q = text:sub(i, i)
		if q == "'" or q == '"' then
			local e = text:find(q, i + 1, true)
			if e then
				delim, expand = text:sub(i + 1, e - 1), false
				push("word", i, e)
				i = e + 1
			end
		else
			local w = text:match("^[^%s;|&<>()]+", i)
			if w then
				expand = not w:find("[\\'\"]")
				delim = (w:gsub("[\\'\"]", ""))
				push("word", i, i + #w - 1)
				i = i + #w
			end
		end
		if delim and #ctx == 0 then
			pending = pending or {}
			pending[#pending + 1] = { delim = delim, strip = (op == "<<-"), expand = expand }
		end
	end

	while i <= n do
		local top = ctx[#ctx]
		if top == "sq" then
			local start = sq_start or i
			sq_start = nil
			local j = text:find("'", i, true)
			local contd = (started_in_str and start == 1) or nil
			if j then
				push("string", start, j, { contd = contd })
				table.remove(ctx)
				i = j + 1
			else
				push("string", start, n, { open = true, contd = contd })
				i = n + 1
			end
		elseif top == "dq" then
			local start = dq_start or i
			dq_start = nil
			local j, vars, special, closed = i, {}, nil, false
			while j <= n do
				local c = text:sub(j, j)
				if c == "\\" then j = j + 2
				elseif c == '"' then closed = true break
				elseif c == "$" then
					local nx = text:sub(j + 1, j + 1)
					if nx == "(" then special = text:sub(j + 2, j + 2) == "(" and "$((" or "$(" break
					elseif nx == "{" then
						local nm = text:match("^%${[!#]?([%a_][%w_]*)", j)
						if nm then vars[#vars + 1] = nm end
						local k = text:find("}", j + 2, true)
						j = (k or n) + 1
					else
						local nm = text:match("^%$([%a_][%w_]*)", j)
						if nm then vars[#vars + 1] = nm j = j + 1 + #nm else j = j + 1 end
					end
				elseif c == "`" then special = "`" break
				else j = j + 1 end
			end
			local extra = { vars = vars, dq = true,
				contd = (started_in_str and start == 1) or nil, adj_force = resume_dq or nil }
			resume_dq = false
			if closed then
				push("string", start, j, extra)
				table.remove(ctx)
				i = j + 1
			elseif special then
				if j - 1 >= start then push("string", start, j - 1, extra) end
				if special == "`" then
					table.insert(ctx, "bt") push("op", j, j) i = j + 1
				elseif special == "$((" then
					table.insert(ctx, "arith") push("op", j, j + 2) i = j + 3
				else
					table.insert(ctx, "cmd") push("op", j, j + 1) i = j + 2
				end
			else
				extra.open = true
				push("string", start, n, extra)
				i = n + 1
			end
		else
			local c = text:sub(i, i)
			if c:find("%s") then
				i = i + 1
			elseif top == "arith" or top == "aparen" then
				if c == "(" then table.insert(ctx, "aparen") i = i + 1
				elseif c == ")" then
					if top == "aparen" then table.remove(ctx) i = i + 1
					elseif text:sub(i, i + 1) == "))" then pop_sub() push("op", i, i + 1) i = i + 2
					else i = i + 1 end
				elseif c:find("[%a_]") then
					local w = text:match("^[%a_][%w_]*", i)
					push("arith", i, i + #w - 1, { name = w })
					i = i + #w
				elseif c == "$" then
					if not dollar() then i = i + 1 end
				else i = i + 1 end
			elseif c == "#" then
				push("comment", i, n, { open = true })
				i = n + 1
			elseif c == "\\" and i == n then
				push("op", i, i)
				i = n + 1
			elseif c == "'" then
				sq_start = i
				table.insert(ctx, "sq")
				i = i + 1
			elseif c == '"' then
				dq_start = i
				table.insert(ctx, "dq")
				i = i + 1
			elseif c == "`" then
				if top == "bt" then pop_sub() else table.insert(ctx, "bt") end
				push("op", i, i)
				i = i + 1
			elseif c == "$" then
				if not dollar() then word() end
			elseif c == "(" then
				if text:sub(i, i + 1) == "((" then
					table.insert(ctx, "arith") push("op", i, i + 1) i = i + 2
				else
					if top == "cmd" or top == "paren" then table.insert(ctx, "paren") end
					push("op", i, i)
					i = i + 1
				end
			elseif c == ")" then
				if top == "paren" then table.remove(ctx)
				elseif top == "cmd" then pop_sub() end
				push("op", i, i)
				i = i + 1
			else
				local fd = text:match("^(%d+)[<>]", i) or ""
				local at, op = i + #fd, nil
				for _, o in ipairs(OPS) do
					if text:sub(at, at + #o - 1) == o then op = o break end
				end
				if op then
					push("op", i, at + #op - 1)
					i = at + #op
					if op == "<(" or op == ">(" then table.insert(ctx, "cmd") end
					if op == "<<" or op == "<<-" then heredoc_op(op) end
				else
					word()
				end
			end
		end
	end

	-- a heredoc opened on this line starts on the next one
	if not hd and pending and #pending > 0 and #ctx == 0 then hd = table.remove(pending, 1) end

	-- tokens glued to the previous one are part of the same argument
	for k = 2, #toks do
		local t, p = toks[k], toks[k - 1]
		if t.contd or t.adj_force then t.adj_prev = true
		elseif t.type ~= "op" and t.type ~= "comment" and t.s == p.e + 1
			and (p.type == "word" or p.type == "var" or p.type == "string") then
			t.adj_prev = true
		end
	end
	if toks[1] and toks[1].contd then toks[1].adj_prev = true end

	return toks, out_state()
end

function S.same_state(a, b)
	if a == nil or b == nil then return a == b end
	if #a.ctx ~= #b.ctx then return false end
	for k = 1, #a.ctx do if a.ctx[k] ~= b.ctx[k] then return false end end
	local ha, hb = a.hd, b.hd
	if (ha == nil) ~= (hb == nil) then return false end
	if ha and (ha.delim ~= hb.delim or ha.strip ~= hb.strip or ha.expand ~= hb.expand) then return false end
	return (a.pending and #a.pending or 0) == (b.pending and #b.pending or 0)
end

-- ------------------------------------------------------------------
-- 2. Analysis: one forward pass over the whole document
-- ------------------------------------------------------------------

function S.analyze(line_toks, cursor)
	local flat = {}
	for ln, toks in ipairs(line_toks) do
		for _, t in ipairs(toks) do
			if t.type ~= "comment" then t.line = ln flat[#flat + 1] = t end
		end
	end

	local commands, globals, options, subs = {}, {}, {}, {}
	local sc = Scope.new()
	local stack = sc.stack
	local snap

	local cmd_pos, cur_cmd, argn = true, nil, 0
	local decl_mode, skip_word = nil, false
	local fn_pending, fn_name_next = false, false
	local for_state, case_state = nil, nil
	local skip_ops = 0
	local prev

	local function top() return stack[#stack] end
	local function nested(tbl, a, b)
		local m = tbl[a]
		if not m then m = {} tbl[a] = m end
		m[b] = (m[b] or 0) + 1
	end
	local function use_var(name)
		if not name then return end
		if sc:lookup(name) then return end
		globals[name] = (globals[name] or 0) + 1
	end
	local function declare_local(name, line)
		local _, f = sc:find(function(fr) return fr.kind == "fn" end)
		if f then sc:declare(name, "var", f, line) return end
		globals[name] = (globals[name] or 0) + 1       -- `local` outside a function: global
	end
	local function new_command()
		cmd_pos, cur_cmd, argn = true, nil, 0
		decl_mode, skip_word = nil, false
	end
	local function continues(p)
		return p.type == "op" and (p.text == "|" or p.text == "||" or p.text == "&&"
			or p.text == "|&" or p.text == "\\")
	end
	local function adjacent(t)
		return prev and prev.line == t.line and prev.e + 1 == t.s
			and (prev.type == "word" or prev.type == "var" or prev.type == "string")
	end

	-- $( ... ) and friends: the inner commands are analysed, then the outer command resumes
	local function push_sub(kind, adj)
		sc:push(kind, { saved = { cmd_pos, cur_cmd, argn, decl_mode, skip_word }, adj = adj })
		new_command()
	end
	local function pop_sub()
		for k = #stack, 2, -1 do
			local fr = stack[k]
			if fr.saved then
				local s = fr.saved
				sc:pop_to(k)
				cmd_pos, cur_cmd, argn, decl_mode, skip_word = s[1], s[2], s[3], s[4], s[5]
				if not fr.adj then
					if cmd_pos then cmd_pos, cur_cmd = false, nil else argn = argn + 1 end
				end
				return true
			end
		end
		return false
	end
	local function pop_to_closer(closer)
		for k = #stack, 2, -1 do
			if stack[k].closer == closer then
				sc:pop_to(k)
				return true
			end
		end
		return false
	end
	local function pop_case()
		for k = #stack, 2, -1 do
			if stack[k].kind == "case" then
				sc:pop_to(k)
				return
			end
		end
	end

	local function take_snap(ci)
		if prev and cursor.line > prev.line and not continues(prev) then
			new_command()
			if for_state == "list" then for_state = nil end
		end
		local f = top()
		snap = {
			ci = ci, cmd_pos = cmd_pos, cur_cmd = cur_cmd, argn = argn, decl_mode = decl_mode,
			for_state = for_state, case_state = case_state, skip_word = skip_word,
			fn_name_next = fn_name_next,
			pat = (f.kind == "case" and f.pat) or false,
			in_array = f.kind == "arr", in_arith = f.kind == "arith",
			visible = sc:visible(),
		}
	end

	local function on_op(t)
		local x = t.text
		if skip_ops > 0 then skip_ops = skip_ops - 1 return end
		if fn_pending and x ~= "(" then fn_pending = false end
		local adj = adjacent(t)

		if x == "|" or x == "||" or x == "&&" or x == "&" or x == ";" or x == "|&" then
			if cur_cmd == "[[" and (x == "&&" or x == "||") then return end
			new_command()
			if x == ";" and for_state == "list" then for_state = nil end
		elseif x == ";;" or x == ";&" or x == ";;&" then
			new_command()
			local f = top()
			if f.kind == "case" then f.pat, cmd_pos = true, false end
		elseif x == "$(" or x == "<(" or x == ">(" then push_sub("cmd", adj)
		elseif x == "$((" or x == "((" then push_sub("arith", adj)
		elseif x == "))" then pop_sub()
		elseif x == "`" then
			if top().kind == "bt" then pop_sub() else push_sub("bt", adj) end
		elseif x == "(" then
			local f = top()
			if f.kind == "case" and f.pat then return end
			if prev and prev.type == "word" and adj and prev.text:sub(-1) == "=" then
				sc:push("arr", { closer = ")" })
			elseif fn_pending then
				sc:push("fn", { closer = ")" })
				fn_pending = false
				new_command()
			else
				sc:push("paren", { closer = ")" })
				new_command()
			end
		elseif x == ")" then
			local f = top()
			if f.kind == "case" and f.pat then f.pat = false new_command() return end
			for k = #stack, 2, -1 do
				local fr = stack[k]
				if fr.saved then pop_sub() return end
				if fr.closer == ")" then
					sc:pop_to(k)
					cmd_pos, cur_cmd = false, nil
					return
				end
			end
		elseif x ~= "\\" and x:find("[<>]") then
			skip_word = true                              -- redirection: next word is a target
		end
	end

	local function on_command_word(i, t)
		local text = t.text
		if fn_pending and text ~= "{" then fn_pending = false end
		local plain = text:match("^[%w_][%w_.+%-]*$") ~= nil

		if STAY_CMD[text] then
			if text == "do" and for_state == "list" then for_state = nil end
			return
		end
		if text == "fi" or text == "done" then cmd_pos, cur_cmd = false, nil return end
		if text == "esac" then pop_case() cmd_pos, cur_cmd = false, nil return end
		if text == "for" or text == "select" then for_state, cmd_pos = "var", false return end
		if text == "case" then
			sc:push("case", { pat = false })
			case_state, cmd_pos = "subject", false
			return
		end
		if text == "function" then fn_name_next, cmd_pos = true, false return end
		if text == "{" then
			if fn_pending then
				sc:push("fn", { closer = "}" })
				fn_pending = false
			else
				sc:push("brace", { closer = "}" })
			end
			return
		end
		if text == "}" then pop_to_closer("}") cmd_pos, cur_cmd = false, nil return end

		-- name() { ... }
		local n1, n2 = flat[i + 1], flat[i + 2]
		if plain and n1 and n1.type == "op" and n1.text == "(" and n2 and n2.type == "op" and n2.text == ")" then
			local r = commands[text] or { n = 0 }
			r.n, r.func = r.n + 1, true
			commands[text] = r
			skip_ops, fn_pending = 2, true
			return
		end

		-- NAME=value prefix assignment: still in command position
		local name = text:match("^([%a_][%w_]*)%+?=")
		if name then use_var(name) return end

		cmd_pos, argn = false, 0
		cur_cmd = text
		if DECL[text] then decl_mode = DECL[text] end
		if plain then
			local r = commands[text] or { n = 0 }
			r.n = r.n + 1
			commands[text] = r
		end
	end

	local function on_arg_word(i, t)
		local text = t.text
		if fn_name_next then
			fn_name_next = false
			if text:match("^[%w_][%w_.:+%-]*$") then
				local r = commands[text] or { n = 0 }
				r.n, r.func = r.n + 1, true
				commands[text] = r
			end
			local n1, n2 = flat[i + 1], flat[i + 2]
			if n1 and n1.type == "op" and n1.text == "(" and n2 and n2.type == "op" and n2.text == ")" then
				skip_ops = 2
			end
			fn_pending, cmd_pos = true, true
			return
		end
		if for_state == "var" then
			use_var(text:match("^[%a_][%w_]*"))
			for_state = "in"
			return
		end
		if for_state == "in" then
			if text == "in" then for_state = "list" end
			return
		end
		if case_state == "subject" then case_state = "in" return end
		if case_state == "in" then
			if text == "in" then
				case_state = nil
				local f = top()
				if f.kind == "case" then f.pat = true end
			end
			return
		end
		local f = top()
		if f.kind == "case" and f.pat then
			if text == "esac" then pop_case() cmd_pos, cur_cmd = false, nil end
			return
		end
		if f.kind == "arr" then return end
		if decl_mode then
			if text:sub(1, 1) == "-" then return end
			local nm = text:match("^([%a_][%w_]*)")
			if decl_mode == "getopts" then
				argn = argn + 1
				if argn == 2 then use_var(nm) end
			elseif nm then
				if decl_mode == "local" then declare_local(nm, t.line) else use_var(nm) end
			end
			return
		end
		argn = argn + 1
		if cur_cmd then
			if text:sub(1, 1) == "-" then
				local opt = text:match("^(%-%-?[%w][%w_%-]*)")
				if opt then nested(options, cur_cmd, opt) end
			elseif argn == 1 and text:match("^[%a_][%w_.%-]*$") then
				nested(subs, cur_cmd, text)
			end
		end
	end

	-- a non-word argument/command (variable, quoted string)
	local function on_other(t)
		if t.adj_prev then return end
		if skip_word then skip_word = false return end
		if cmd_pos then cmd_pos, cur_cmd = false, nil
		elseif case_state == "subject" then case_state = "in"
		else argn = argn + 1 end
	end

	for i, t in ipairs(flat) do
		if not snap and (t.line > cursor.line or (t.line == cursor.line and t.s > cursor.col)) then
			take_snap(i - 1)
		end
		if prev and t.line > prev.line and not t.contd and not continues(prev) then
			new_command()
			if for_state == "list" then for_state = nil end
		end

		local ty = t.type
		if ty == "op" then on_op(t)
		elseif ty == "word" then
			if t.adj_prev then
				-- glued to the previous argument (e.g. the value in --name=value)
			elseif skip_word then skip_word = false
			elseif cmd_pos then on_command_word(i, t)
			else on_arg_word(i, t) end
		elseif ty == "var" then
			use_var(t.name)
			on_other(t)
		elseif ty == "string" then
			if t.vars then for _, v in ipairs(t.vars) do use_var(v) end end
			if not t.heredoc then on_other(t) end
		elseif ty == "arith" then
			use_var(t.name)
		end
		prev = t
	end
	if not snap then take_snap(#flat) end

	return { flat = flat, commands = commands, globals = globals,
		options = options, subs = subs, snap = snap }
end

-- ------------------------------------------------------------------
-- 3. Prefix / literal / context
-- ------------------------------------------------------------------

function S.prefix(before)
	local v = before:match("%$%{?([%a_][%w_]*)$")
	if v then return v, "var" end
	if before:match("%$%{?$") then return "", "var" end
	local w = before:match("[%w_%-]*$")
	local prev = before:sub(1, #before - #w):sub(-1)
	if prev ~= "" and not prev:find("[%s()|&;{`!]") then return nil end   -- paths, values, redirects
	if w:sub(1, 1) == "-" then return w, "opt" end
	return w, "word"
end

function S.inside_literal(toks, st, before)
	local last = toks[#toks]
	if last and last.type == "comment" then return true end
	if st then
		local dollar_var = before:match("%$%{?[%w_]*$") ~= nil
		if st.hd then return not (st.hd.expand and dollar_var) end
		local top = st.ctx[#st.ctx]
		if top == "sq" then return true end
		if top == "dq" then return not dollar_var end
	end
	return false
end

function S.context(model, prefix, cursor_line, mode)
	local snap = model.snap
	if mode == "var" then return { type = "vars" } end
	if prefix == "" then return nil end
	if snap.in_array or snap.pat or snap.skip_word or snap.fn_name_next
		or snap.for_state == "var" or snap.case_state == "subject" then
		return nil
	end
	if snap.in_arith then return { type = "vars" } end
	if mode == "opt" then
		if snap.cur_cmd and not snap.cmd_pos then return { type = "options", cmd = snap.cur_cmd } end
		return nil
	end
	if snap.decl_mode then
		if snap.decl_mode == "global" or snap.decl_mode == "unset" then return { type = "vars" } end
		return nil                                     -- local/read/getopts name new variables
	end
	if snap.cmd_pos then return { type = "commands" } end
	if snap.for_state == "in" or snap.case_state == "in" then
		return { type = "keywords", list = { "in" } }
	end
	if snap.argn == 0 and snap.cur_cmd then return { type = "subs", cmd = snap.cur_cmd } end
	return nil
end

-- groups: 1 = most specific (locals, per-command options/subcommands, functions), 2 = the rest, 3 = keywords
function S.candidates(spec, model)
	local out, snap = {}, model.snap
	local function add(text, kind, group, rank)
		out[#out + 1] = { text = text, kind = kind, group = group, rank = rank }
	end
	local t = spec.type
	if t == "vars" then
		for name in pairs(snap.visible) do add(name, "variable", 1, 1e6) end
		for name, n in pairs(model.globals) do
			if not snap.visible[name] then add(name, "variable", 2, n) end
		end
	elseif t == "commands" then
		for name, r in pairs(model.commands) do
			add(name, r.func and "function" or "command", r.func and 1 or 2, r.n)
		end
		for _, kw in ipairs(CMD_KEYWORDS) do add(kw, "keyword", 3, 0) end
	elseif t == "options" then
		for opt, n in pairs(model.options[spec.cmd] or {}) do add(opt, "option", 1, n) end
	elseif t == "subs" then
		for w, n in pairs(model.subs[spec.cmd] or {}) do add(w, "subcommand", 1, n) end
	elseif t == "keywords" then
		for _, kw in ipairs(spec.list) do add(kw, "keyword", 3, 0) end
	end
	return out
end

return S
