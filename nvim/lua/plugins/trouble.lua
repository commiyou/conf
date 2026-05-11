-- Structured diagnostics, LSP references, quickfix list.
-- <leader>xx  toggle workspace diagnostics
-- <leader>xd  current buffer diagnostics
-- <leader>xs  document symbols
-- <leader>xl  LSP definitions / references
-- <leader>xq  quickfix list
return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {},
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",                        desc = "Diagnostics" },
    { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",           desc = "Buffer Diagnostics" },
    { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>",                desc = "Symbols" },
    { "<leader>xl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<cr>",                             desc = "Quickfix" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>",                            desc = "Location List" },
    -- navigate trouble items with [q / ]q
    {
      "[q",
      function()
        if require("trouble").is_open() then
          require("trouble").prev { skip_groups = true, jump = true }
        else
          vim.cmd.cprev()
        end
      end,
      desc = "Prev trouble/quickfix",
    },
    {
      "]q",
      function()
        if require("trouble").is_open() then
          require("trouble").next { skip_groups = true, jump = true }
        else
          vim.cmd.cnext()
        end
      end,
      desc = "Next trouble/quickfix",
    },
  },
}
