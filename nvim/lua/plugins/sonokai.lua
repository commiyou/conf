return {
  {
    "sainnhe/sonokai",
    priority = 100,
    init = function() -- init function runs before the plugin is loaded
      -- TODO: some highlight to copy ../../lvim/config.lua
      --vim.g.sonokai_style = "shusia"
      vim.g.sonokai_transparent_background = 0
      vim.g.sonokai_diagnostic_text_highlight = 1
      vim.g.sonokai_diagnostic_line_highlight = 1
      -- vim.g.sonokai_enable_italic = 1
      vim.g.sonokai_disable_italic_comment = 1
      vim.g.sonokai_style = "default"
    end,
  },
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      colorscheme = "sonokai",
    },
  },
}
