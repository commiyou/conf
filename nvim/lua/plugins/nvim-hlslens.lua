return {
  --enabled = false,
  "kevinhwang91/nvim-hlslens",
  -- config 函数保留，用于调用 setup
  config = function()
    require("hlslens").setup {
      -- 你可以在这里添加或修改 hlslens 的其他设置
      calm_down = true,
      virt_priority = 10,
    }
  end,
  -- 将所有的 vim.api.nvim_set_keymap 转换为 keys 表中的条目
  keys = {
    {
      "n",
      -- 这个复杂的映射是为了在执行 n 的同时保留 v:count1 (比如 3n)
      [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
      { mode = "n", silent = true, desc = "下一个搜索结果 (Hlslens)", noremap = true },
    },
    {
      "N",
      [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
      { mode = "n", silent = true, desc = "上一个搜索结果 (Hlslens)", noremap = true },
    },
    {
      "*",
      [[*<Cmd>lua require('hlslens').start()<CR>]],
      { mode = "n", silent = true, desc = "向后搜索光标词 (Hlslens)", noremap = true },
    },
    {
      "#",
      [[#<Cmd>lua require('hlslens').start()<CR>]],
      { mode = "n", silent = true, desc = "向前搜索光标词 (Hlslens)", noremap = true },
    },
    {
      "g*",
      [[g*<Cmd>lua require('hlslens').start()<CR>]],
      { mode = "n", silent = true, desc = "向后搜索光标词(部分) (Hlslens)", noremap = true },
    },
    {
      "g#",
      [[g#<Cmd>lua require('hlslens').start()<CR>]],
      { mode = "n", silent = true, desc = "向前搜索光标词(部分) (Hlslens)", noremap = true },
    },
  },
}
