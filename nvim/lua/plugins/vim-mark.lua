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
    { "<leader>mm", "<Plug>MarkSet",               mode = { "n", "v" }, desc = "Mark toggle word/selection" },
    { "<leader>mr", "<Plug>MarkRegex",             mode = { "n", "v" }, desc = "Mark by regex" },
    { "<leader>mc", "<Plug>MarkAllClear",          mode = "n",          desc = "Mark clear all" },
    { "<leader>mn", "<Plug>MarkSearchNext",        mode = "n",          desc = "Next mark (any)" },
    { "<leader>mp", "<Plug>MarkSearchPrev",        mode = "n",          desc = "Prev mark (any)" },
    { "]m",         "<Plug>MarkSearchCurrentNext", mode = "n",          desc = "Next current mark" },
    { "[m",         "<Plug>MarkSearchCurrentPrev", mode = "n",          desc = "Prev current mark" },
  },
}
