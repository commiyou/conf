return {
  -- https://github.com/daipeihust/im-select install binary
  "keaising/im-select.nvim",
  -- 只有在 macOS 或 Windows 上才启用此插件
  enabled = function()
    -- vim.fn.has("mac") 在 macOS 上返回 1
    -- vim.fn.has("win32") 在 Windows 上返回 1
    return vim.fn.has "mac" == 1 or vim.fn.has "win32" == 1
  end,
  config = function() require("im_select").setup {} end,
}
