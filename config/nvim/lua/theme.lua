-- theme.lua
local M = {}
local ACTIVE_PATH = vim.env.HOME .. "/.local/state/theme-switcher/active/nvim-theme.lua"

function M.apply()
	local chunk = loadfile(ACTIVE_PATH)
	pcall(chunk)
end

return M
