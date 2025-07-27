return {
  "commiyou/vim-mark",
  dependencies = { "inkarkat/vim-ingo-library" },
  -- 使用 init 函数设置需要在插件加载前生效的全局变量
  init = function()
    vim.g.mwDefaultHighlightingPalette = "extended"
    vim.g.mwHistAdd = "@"
    vim.g.mwAutoLoadMarks = 1
    -- 禁用插件的默认映射，以便在下面自定义
    vim.g.mw_no_mappings = 1
  end,
  keys = {
    { "<leader>M", "<Plug>MarkSet", mode = "n", desc = "设置标记 (MarkSet)" },
    -- 你可以在这里添加该插件的其他快捷键
    -- 例如:
    -- { "<leader>mj", "<Plug>MarkNext", mode = "n", desc = "下一个标记" },
    -- { "<leader>mk", "<Plug>MarkPrev", mode = "n", desc = "上一个标记" },
  },
}
