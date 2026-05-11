local trigger_fts = {
  "python", "lua", "sh", "bash",
  "typescript", "javascript", "tsx", "jsx",
  "cpp", "c", "go", "rust",
}

return {
  {
    "milanglacier/minuet-ai.nvim",
    event = "VeryLazy",
    cmd = { "Minuet" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>am", function() require("minuet.virtualtext").action.toggle_auto_trigger() end, desc = "Toggle AI inline (Minuet)" },
    },
    config = function(_, opts)
      require("minuet").setup(opts)
      -- FileType autocmd only fires for *future* buffers; backfill already-open ones
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
        if vim.tbl_contains(trigger_fts, ft) then
          vim.api.nvim_buf_set_var(bufnr, "minuet_virtual_text_auto_trigger", true)
        end
      end
    end,
    opts = {
      provider = "claude",
      context_window = 4096,
      request_timeout = 8,
      throttle = 1200,
      notify = "debug",
      provider_options = {
        claude = {
          model = "Claude Haiku 4.5",
          end_point = "https://oneapi-comate.baidu-int.com/v1/messages",
          api_key = "ANTHROPIC_AUTH_TOKEN",
          stream = true,
          optional = { max_tokens = 256 },
        },
      },
      virtualtext = {
        auto_trigger_ft = trigger_fts,
        keymap = {
          accept      = "<A-y>",
          accept_line = "<A-l>",
          next        = "<A-n>",
          prev        = "<A-p>",
          dismiss     = "<A-e>",
        },
      },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        default = { "minuet" },
        providers = {
          minuet = { name = "minuet", module = "minuet.blink", score_offset = 8 },
        },
      },
    },
    opts_extend = { "sources.default" },
  },
}
