--if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  { import = "astrocommunity.pack.lua" },
  -- import/override with your plugins folder
  --
  { import = "astrocommunity.recipes.astrolsp-no-insert-inlay-hints" },
  { import = "astrocommunity.colorscheme.sonokai" },
  { import = "astrocommunity.recipes.vscode" },
  { import = "astrocommunity.register.nvim-neoclip-lua" }, -- <Leader>fy
  { import = "astrocommunity.bars-and-lines.lualine-nvim" }, -- <Leader>fy
}
