local cmp = require("cmp")
cmp.setup({
  completion = {
    complete = true,
  },
  mapping = {
	["<C-Space>"] = cmp.mapping.complete(),
    ["<C-a>"] = cmp.mapping.select_next_item(),
    ["<C-d>"] = cmp.mapping.select_prev_item(),
    ["<Tab>"] = cmp.mapping.confirm({ select = true }),
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  },
})
