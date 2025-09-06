---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.search.nvim-hlslens" },
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.cpp" },
  { import = "astrocommunity.pack.bash" },
  { import = "astrocommunity.pack.docker" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.html-css" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.pack.proto" },
  { import = "astrocommunity.pack.python-ruff" },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
      python = { "ruff_organize_imports", "ruff_format" },
    },
    -- Set default options
    default_format_opts = {
      lsp_format = "fallback",
    },
    -- Set up format-on-save
    format_on_save = { timeout_ms = 500 },
    },
  },
  --{ import = "astrocommunity.pack.sql" },
  { import = "astrocommunity.pack.toml" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.register.nvim-neoclip-lua" }, -- <Leader>fy
  { import = "astrocommunity.bars-and-lines.lualine-nvim" },
  { import = "astrocommunity.recipes.astrolsp-no-insert-inlay-hints" },
  { import = "astrocommunity.colorscheme.sonokai" },
  { import = "astrocommunity.recipes.vscode" },
  { import = "astrocommunity.lsp.actions-preview-nvim" }, -- :TSInstall diff
  { import = "astrocommunity.lsp.lsp-signature-nvim" },
  --{import = "astrocommunity.editing-support.nvim-context-vt" },
  { import = "astrocommunity.editing-support.nvim-treesitter-context" },
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      --mode = "topline",
      enable = true,     -- Enable this plugin (Can be enabled/disabled later via commands)
      throttle = true,   -- Throttles plugin updates (may improve performance)
      max_lines = 5,     -- How many lines the window should span. Values <= 0 mean no limit.
      min_window_height = 15,
      patterns = {       -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
        -- For all filetypes
        -- Note that setting an entry here replaces all other patterns for this entry.
        -- By setting the 'default' entry below, you can control which nodes you want to
        -- appear in the context window.
        default = {
          'class',
          'function',
          'method',
        },
      },
    },
  },
}
