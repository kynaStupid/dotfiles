-- lua/config/lspconfig.lua
local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config('clangd', {
  cmd = { "clangd", "--background-index", "--clang-tidy" },
  filetypes = { "c", "cpp" },
  root_markers = { "compile_commands.json", ".git" },
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    local map = vim.keymap.set
    map("n", "<leader>rn", vim.lsp.buf.rename,      { buffer = bufnr })
    map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr })
    map("n", "gd",         vim.lsp.buf.definition,  { buffer = bufnr })
    map("n", "gh",         vim.lsp.buf.hover,        { buffer = bufnr })
  end,
})

vim.lsp.enable('clangd')