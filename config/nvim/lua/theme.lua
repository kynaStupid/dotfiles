-- theme.lua
local M = {}
local ACTIVE_PATH = "@THEME_SWITCHER_ROOT@/active/nvim-theme.lua"

function M.apply()
	local chunk = loadfile(ACTIVE_PATH)
	pcall(chunk)
end

return M
