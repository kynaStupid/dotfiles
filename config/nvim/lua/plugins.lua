-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- Catppuccin Mocha
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000,
		config = function() vim.cmd("colorscheme catppuccin-mocha") end },
	
	-- Fuzzy finder
	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
	
	-- File tree
	{ "nvim-tree/nvim-tree.lua" },
	
	-- Syntax highlighting
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
	
	-- Status line
	{ "nvim-lualine/lualine.nvim" },
	
	-- C++
	{ "neovim/nvim-lspconfig", config = function() require("config.lspconfig") end }, -- LSP setup
	{ "hrsh7th/nvim-cmp", dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
		config = function() require("config.cmp") end }, -- Completion
	--{ "nvim-lua/lsp-format.nvim", config = require("config.format") }, -- Auto-formatting
	--{ "nvim-telescope/telescope-lsp-handlers", dependencies = { "nvim-telescope/telescope.nvim" } }, -- LSP handlers for Telescope
	{ "nvim-treesitter/nvim-treesitter-textobjects", dependencies = { "nvim-treesitter/nvim-treesitter" } }, -- Text objects for C++
	{ "kylechui/nvim-surround", }, -- Surround plugin
})
