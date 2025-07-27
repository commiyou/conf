---@module "lazy"
---
---https://github.com/nvim-lualine/lualine.nvim/wiki/Component-snippets
-- #### start Changing filename color based on modified status
local custom_fname = require("lualine.components.filename"):extend()
local highlight = require "lualine.highlight"
local default_status_colors = { saved = "#228B22", modified = "#C70039" }

function custom_fname:init(options)
  custom_fname.super.init(self, options)
  self.status_colors = {
    saved = highlight.create_component_highlight_group(
      { bg = default_status_colors.saved },
      "filename_status_saved",
      self.options
    ),
    modified = highlight.create_component_highlight_group(
      { bg = default_status_colors.modified },
      "filename_status_modified",
      self.options
    ),
  }
  if self.options.color == nil then self.options.color = "" end
end

function custom_fname:update_status()
  local data = custom_fname.super.update_status(self)
  data = highlight.component_format_highlight(
    vim.bo.modified and self.status_colors.modified or self.status_colors.saved
  ) .. data
  return data
end
-- #### end Changing filename color based on modified status

-- Formats a fraction so the numerator and denominator have the same number of digits.
local function format_fraction(numerator, denominator)
  local number_of_digits = string.len(tostring(denominator))
  local formatted_numerator = string.format("%" .. number_of_digits .. "d", numerator)
  return formatted_numerator .. "/" .. denominator
end

local function location()
  local current_line = vim.fn.line "."
  local number_of_lines = vim.fn.line "$"
  return format_fraction(current_line, number_of_lines)
end

local function format_search_count(search_count) return search_count:gsub("[[%]]", "") end

local function recording()
  local rec = vim.fn.reg_recording()
  if rec == "" then return "" end
  return " " .. rec -- 直接返回带图标的字符串
end

-- A nicer status line.
---@type LazySpec
return {
  { "AstroNvim/astrocommunity" },
  { import = "astrocommunity.bars-and-lines.lualine-nvim" },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },

    opts = {
      options = {
        -- 使用 'auto' 主题来自动匹配你的 colorscheme
        theme = "auto",
        -- Nerd Font 风格的箭头分隔符
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        -- 禁用某些文件类型的 lualine
        disabled_filetypes = {
          statusline = { "dashboard", "alpha" },
        },
        -- 开启图标支持
        icons_enabled = true,
      },
      sections = {
        -- lualine_a = { "mode" },
        -- lualine_b = { "branch" },
        lualine_c = {
          --{ "filename", color = {}, cond = nil, left = 0, right = 0, file_status = false },
          --{ "filetype", left = 0, right = 0 },
          --custom_fname,
          { "filename", file_status = true, path = 1 }, -- path=1 显示父文件夹
          --{ "diff", symbols = { added = " ", modified = " ", removed = " " } },

          --{ "diff" },
          function() return vim.o.paste and "" or "" end, -- 粘贴模式图标
          function() return vim.o.clipboard == "unnamedplus" and "󱉫" or "" end, -- 系统剪贴板图标
          { "searchcount", icon = "" },
        },
        lualine_x = {
          "hostname",
          { recording, icon = "", color = "Constant" },
          --{ "searchcount", icon = "", color = "Function", fmt = format_search_count },
          "encoding",
          "lsp_status",
          "spaces",
          "filetype",
          "fileformat",
        },
        -- lualine_y = { "diagnostics" },
        lualine_z = { { location, icon = "" } },
      },
    },
  },
}
