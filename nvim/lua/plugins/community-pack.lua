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
  {import = "astrocommunity.lsp.lsp-signature-nvim" },
  {import = "astrocommunity.editing-support.nvim-context-vt" },
  {import = "astrocommunity.editing-support.nvim-treesitter-context" },
}
