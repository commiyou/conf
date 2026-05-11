-- Search and preview all available snippets via Telescope.
-- <leader>fs  fuzzy-find snippets (friendly-snippets + custom python.json)
return {
  {
    "benfowler/telescope-luasnip.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "L3MON4D3/LuaSnip",
    },
    config = function() require("telescope").load_extension "luasnip" end,
  },
  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<leader>fs"] = { "<cmd>Telescope luasnip<cr>", desc = "Find Snippets" },
        },
      },
    },
  },
}
