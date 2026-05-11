-- Extend AstroNvim's built-in snacks.nvim with words highlight.
-- snacks.words: auto-highlights all occurrences of word under cursor,
-- ]] / [[ to jump between them (replaces having to use * then n/N).
return {
  "folke/snacks.nvim",
  opts = {
    words = { enabled = true },
  },
  keys = {
    { "]]", function() require("snacks").words.jump(1,  true) end, desc = "Next word occurrence" },
    { "[[", function() require("snacks").words.jump(-1, true) end, desc = "Prev word occurrence" },
  },
}
