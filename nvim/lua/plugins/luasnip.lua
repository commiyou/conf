return {
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      -- include the default astronvim config that calls the setup call
      require "astronvim.plugins.configs.luasnip"(plugin, opts)
      -- load snippets paths
      require("luasnip.loaders.from_vscode").lazy_load {
        paths = { vim.fn.stdpath "config" .. "/snippets" },
      }
    end,
  },
  {
    "chrisgrieser/nvim-scissors",
    dependencies = { "nvim-telescope/telescope.nvim", "L3MON4D3/LuaSnip" },
    opts = {
      snippetDir = vim.fn.stdpath "config" .. "/snippets/",
    },
    keys = {
      {
        "<leader>se",
        function() require("scissors").editSnippet() end,
        desc = "Scissors: Edit Snippet",
      },
      {
        "<leader>sa",
        function() require("scissors").addNewSnippet() end,
        mode = { "n", "x" }, -- Specify modes for the keymap
        desc = "Scissors: Add New Snippet",
      },
    },
  },
}
