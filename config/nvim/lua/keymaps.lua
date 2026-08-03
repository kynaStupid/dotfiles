-- keymaps.lua
local map = vim.keymap.set

-- lleader
vim.g.mapleader = " "

-- save & quit
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })

-- mode
map("n", "o", "a") -- append
map("n", "<leader>o", "o") -- new line and insert
--i is insert
map("n", "u", "s") -- sub

-- n mode navigation
map("n", "w", "k") -- up
map("n", "a", "h") -- left
map("n", "s", "j") -- down
map("n", "d", "l") -- right
map("n", "f", "w") -- jump word
map("n", "A", "0") -- start of line
map("n", "D", "$") -- end of line
map("n", "B", "^") -- first non-whitespace in line
map("n", "F", "g_") -- last non-whitespace in line

-- n mode actions
map("n", "z", "u") -- undo
map("n", "k", "d") -- del
map("n", "kk", "dd") -- del line
map("n", "kf", "dw") -- del word
--y is copy
--yy is copy line
--p is paste

-- window navigation
map("n", "<Up>", "<C-w>k")
map("n", "<Left>", "<C-w>h")
map("n", "<Down>", "<C-w>j")
map("n", "<Right>", "<C-w>l")

-- clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- surround
map("n", "js", "<Plug>(nvim-surround-normal)")
map("n", "ks", "<Plug>(nvim-surround-delete)")
map("n", "ls", "<Plug>(nvim-surround-change)")

-- fzf

local fzf = require("fzf-lua")
map("n", "<leader>ff", fzf.files, { desc = "Find files" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
map("n", "<leader>fh", fzf.help_tags, { desc = "Help" })
map("n", "<leader>fr", fzf.oldfiles, { desc = "Recent files" })

-- nvim tree
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>")

-- v mode movement
map("v", "w", "k") -- up
map("v", "a", "h") -- left
map("v", "s", "j") -- down
map("v", "d", "l") -- right
map("v", "f", "w") -- jump word
map("v", "F", "W") -- jump to next whitespace
map("v", "<A-a>", "0") -- start of line
map("v", "<A-d>", "$") -- end of line
map("v", "<A-b>", "^") -- first non-whitespace in line
map("v", "<A-f>", "g_") -- last non-whitespace in line

-- v mode actions
map("v", "<C-w>", "<cmd>m '<-2<CR>gv=gv") -- move lines up
map("v", "<C-s>", "<cmd>m '>+1<CR>gv=gv") -- move lines down
map("v", "u", "s") -- del and insert

vim.schedule(function()
	pcall(vim.keymap.del, "n", "ds")
	pcall(vim.keymap.del, "v", "an")
	pcall(vim.keymap.del, "v", "a%")
end)

