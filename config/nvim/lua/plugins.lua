-- plugins.lua
-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
	-- terminal
	{ "akinsho/toggleterm.nvim", version = "*",
		config = function() require("config.toggleterm") end },
	
	-- fzf
	{ "ibhagwan/fzf-lua", dependencies = { "nvim-tree/nvim-web-devicons", },
		config = function() require("config.fzf") end },
	
	-- file tree
	{ "nvim-tree/nvim-tree.lua" },
	
	-- syntax highlighting
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
	
	-- status line
	{ "nvim-lualine/lualine.nvim" },
	
	-- c++
	{ "neovim/nvim-lspconfig", config = function() require("config.lspconfig") end }, -- LSP setup
	{ "hrsh7th/nvim-cmp", dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
		config = function() require("config.cmp") end }, -- completion
	--{ "nvim-lua/lsp-format.nvim", config = require("config.format") }, -- auto-formatting
	{ "nvim-treesitter/nvim-treesitter-textobjects", dependencies = { "nvim-treesitter/nvim-treesitter" } }, -- text objects for C++
	{ "kylechui/nvim-surround", }, -- surround
}

local theme_dir = vim.env.HOME .. "/.local/state/theme-switcher/nvim/plugins"
if vim.fn.isdirectory(theme_dir) == 1 then
	for _, file in ipairs(vim.fn.readdir(theme_dir)) do
		if file:match("%.lua$") then
			table.insert(plugins, dofile(theme_dir .. "/" .. file))
		end
	end
end

require("lazy").setup(plugins, {
	lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
})
