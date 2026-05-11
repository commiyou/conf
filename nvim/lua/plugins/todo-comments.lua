-- Highlight TODO/FIXME/HACK/NOTE/BUG/PERF and search them via Telescope.
-- ]t / [t   jump to next/prev TODO
-- <leader>ft  Telescope TODO search
-- <leader>fT  Trouble TODO list
return {
  {
    "folke/todo-comments.nvim",
    event = "BufRead",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = true },
  },
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["]t"] = { function() require("todo-comments").jump_next() end, desc = "Next TODO" },
          ["[t"] = { function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
          ["<leader>ft"] = { "<cmd>TodoTelescope<cr>",  desc = "Find TODOs" },
          ["<leader>fT"] = { "<cmd>TodoTrouble<cr>",    desc = "Trouble TODOs" },
        },
      },
    },
  },
}
