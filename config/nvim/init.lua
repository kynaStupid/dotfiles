-- init.lua

local sock_dir = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/nvim-theme-sockets"
vim.fn.mkdir(sock_dir, "p")
vim.fn.serverstart(sock_dir .. "/" .. vim.fn.getpid() .. ".sock")

require("theme").apply()

require("plugins") -- plugin manager + plugins
require("options") -- general settings
require("keymaps") -- your keybindings
