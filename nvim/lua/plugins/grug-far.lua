-- Project-wide search & replace with live preview.
-- <leader>fr  open (auto-prefills current file extension filter)
-- <leader>fR  open with word under cursor
-- <leader>fr in visual  open with selection as search term
return {
  "MagicDuck/grug-far.nvim",
  cmd = "GrugFar",
  keys = {
    {
      "<leader>fr",
      function()
        local grug = require "grug-far"
        local ext = vim.bo.buftype == "" and vim.fn.expand "%:e"
        grug.open {
          transient = true,
          prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
        }
      end,
      mode = { "n", "v" },
      desc = "Find & Replace",
    },
    {
      "<leader>fR",
      function()
        require("grug-far").open {
          transient = true,
          prefills = { search = vim.fn.expand "<cword>" },
        }
      end,
      desc = "Find & Replace word",
    },
  },
  opts = { headerMaxWidth = 80 },
}
