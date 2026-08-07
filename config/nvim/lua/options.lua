-- options.lua
local opt = vim.opt

opt.number = true              -- show line numbers
opt.relativenumber = true      -- relative line numbers (helpful for jumps)
opt.tabstop = 2                -- tab = 2 spaces
opt.shiftwidth = 2             -- indent = 2 spaces
opt.expandtab = false          -- use spaces instead of tabs
opt.wrap = false               -- don't wrap long lines
opt.mouse = "a"                -- enable mouse clicking
opt.clipboard = "unnamedplus"  -- use Windows clipboard (ctrl+c/v works)
opt.ignorecase = true          -- search is case-insensitive
opt.smartcase = true           -- ...unless you type uppercase
opt.scrolloff = 8              -- keep 8 lines visible above/below cursor
opt.termguicolors = true       -- needed for themes to look right

require("theme").apply()
