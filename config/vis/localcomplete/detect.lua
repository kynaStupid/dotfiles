-- Which language module should a file use?  Pure functions, no vis calls, so it is
-- unit-tested headless (test_detect.lua).
--
-- Most scripts have no extension, only a `#!` line, so that comes FIRST:
--   #!/bin/sh   #!/usr/bin/env bash   #!/usr/bin/env -S bash -e   #!/bin/busybox sh
--   #!/usr/bin/lua5.4   #!/usr/bin/env nix-shell + `#! nix-shell -i bash`
-- then editor/linter hints (`# shellcheck shell=bash`, `# vim: ft=sh`),
-- then vis's own syntax guess, then file name (.bashrc, PKGBUILD ...), then extension.

local D = {}

-- interpreter / filetype word -> language key
local names = {
	lua = "lua", luajit = "lua",
	sh = "sh", bash = "sh", dash = "sh", ash = "sh", ksh = "sh", mksh = "sh",
	zsh = "sh", yash = "sh", posh = "sh", shell = "sh", busybox = "sh",
	nix = "nix",
}

local filenames = {
	[".bashrc"] = "sh", [".bash_profile"] = "sh", [".bash_login"] = "sh",
	[".bash_logout"] = "sh", [".bash_aliases"] = "sh", [".profile"] = "sh",
	[".zshrc"] = "sh", [".zshenv"] = "sh", [".zprofile"] = "sh", [".zlogin"] = "sh",
	[".zlogout"] = "sh", [".kshrc"] = "sh", [".xinitrc"] = "sh", [".xprofile"] = "sh",
	[".xsession"] = "sh", [".envrc"] = "sh", ["PKGBUILD"] = "sh", ["APKBUILD"] = "sh",
}

local function lang_name(word)                      -- "lua5.4" -> lua, "ksh93" -> sh
	if not word then return nil end
	word = word:lower():gsub("[%d%.]+$", "")
	return names[word]
end

local function lines_of(head)
	local out = {}
	for l in (head .. "\n"):gmatch("(.-)\n") do out[#out + 1] = l end
	return out
end

local function shebang_language(lines)
	local line = lines[1] and lines[1]:match("^#!%s*(.*)")
	if not line then return nil end
	local words = {}
	for w in line:gmatch("%S+") do words[#words + 1] = w end
	if #words == 0 then return nil end
	local i = 1
	local prog = words[1]:match("([^/]+)$")
	if prog == "env" then
		i = 2
		while words[i] and (words[i]:sub(1, 1) == "-" or words[i]:find("=", 1, true)) do
			if words[i] == "-u" or words[i] == "--unset" then i = i + 1 end
			i = i + 1
		end
		prog = words[i] and words[i]:match("([^/]+)$")
	end
	if prog == "nix" then return nil end            -- `#!/usr/bin/env nix`: a shell script run by nix
	if prog == "busybox" and words[i + 1] then prog = words[i + 1]:match("([^/]+)$") end
	if prog == "nix-shell" then
		for n = 2, math.min(#lines, 8) do
			local interp = lines[n]:match("^#!%s*nix%-shell.-%s%-i%s+(%S+)")
			if interp then return lang_name(interp:match("([^/]+)$")) end
		end
		return nil
	end
	return lang_name(prog)
end

local function directive_language(lines)
	for n = 1, math.min(#lines, 5) do
		local l = lines[n]
		if l:find("^%s*[#%-;]") then
			local s = l:match("shellcheck%s+.-shell=(%w+)") or l:match("%f[%w]ft=(%w+)")
				or l:match("filetype=(%w+)") or l:match("mode:%s*(%w+)")
			local k = lang_name(s)
			if k then return k end
		end
	end
	return nil
end

-- head: first ~512 bytes of the buffer; name: file name or path (or nil);
-- syntax: vis's own guess for the window (or nil).  Returns "lua" | "sh" | nil.
function D.language_key(head, name, syntax)
	local lines = lines_of(head or "")
	local key = shebang_language(lines) or directive_language(lines) or lang_name(syntax)
	if key then return key end
	name = name or ""
	local base = name:match("([^/]+)$") or name
	return filenames[base] or lang_name(base:match("%.(%w+)$"))
end

return D
