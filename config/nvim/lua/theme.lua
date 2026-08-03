local M = {}

function M.apply()
	package.loaded["theme_active"] = nil
	local ok, name = pcall(require, "theme_active")
	if ok then
		vim.schedule(function() pcall(vim.cmd.colorscheme, name) end)
	end
end

return M
