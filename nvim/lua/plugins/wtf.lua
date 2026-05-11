return {
  "piersolenski/wtf.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-telescope/telescope.nvim", -- Optional: For WtfGrepHistory
  },
  opts = {
    provider = "openai",
    providers = {
      openai = {
        url = "http://10.12.215.17:8800/v1/chat/completions",
        model_id = "gpt-4.1"
      },
    },
    language = "chinese",
  },
  keys = {
    { "<leader>Dd", mode = { "n", "x" }, function() require("wtf").diagnose() end,      desc = "Diagnose with AI" },
    { "<leader>Df", mode = { "n", "x" }, function() require("wtf").fix() end,           desc = "Fix with AI" },
    { "<leader>Ds", mode = "n",          function() require("wtf").search() end,        desc = "Search on Google" },
    { "<leader>Dp", mode = "n",          function() require("wtf").pick_provider() end, desc = "Pick provider" },
    { "<leader>Dh", mode = "n",          function() require("wtf").history() end,       desc = "History → quickfix" },
    { "<leader>Dg", mode = "n",          function() require("wtf").grep_history() end,  desc = "Grep history" },
  },
}
