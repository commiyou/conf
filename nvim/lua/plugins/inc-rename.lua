return {
  {
    "smjonas/inc-rename.nvim",
    event = "VeryLazy",
    config = function()
      require("inc_rename").setup {
        input_buffer_type = "dressing",
      }
      -- lvim.builtin.which_key.mappings["l"]["r"] = { ":IncRename ", "Rename" }
      -- lvim.builtin.which_key.mappings["l"]["R"] = {
      --   function() return ":IncRename " .. vim.fn.expand "<cword>" end,
      --   "Rename keep",
      --   expr = true,
      -- }
    end,
  },
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      mappings = {
        -- first key is the mode
        n = {
          -- second key is the lefthand side of the map
          -- mappings seen under group name "Buffer"
          ["<Leader>lr"] = {
            function() return ":IncRename " .. vim.fn.expand "<cword>" end,
            desc="Rename current symbol",
          },
        },
      },
    },
  },
}
