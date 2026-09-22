---@type LazySpec
return {
  "stevearc/aerial.nvim",
  opts = {
    -- Aerial 2.7's Tree-sitter backend still expects Neovim's pre-0.12
    -- single-node query matches. Its native Markdown backend provides the same
    -- heading outline without touching that compatibility path.
    backends = {
      _ = { "lsp", "treesitter", "man" },
      markdown = { "markdown" },
    },
  },
}
