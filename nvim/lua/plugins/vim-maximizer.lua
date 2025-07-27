return {
  "szw/vim-maximizer",
  keys = {
    -- 在普通模式下的映射
    { "<C-w>z", ":MaximizerToggle<CR>", mode = "n", silent = true, desc = "最大化/还原窗口" },
    -- 在可视模式下的映射，:MaximizerToggle<CR>gv 会在切换后重新选中之前的区域
    { "<C-w>z", ":MaximizerToggle<CR>gv", mode = "v", silent = true, desc = "最大化/还原窗口" },
  },
}
