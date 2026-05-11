--if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

--@type LazySpec
-- return {
--   "AstroNvim/astrocommunity",
--   { import = "astrocommunity.completion.avante-nvim" },
--   {
--     "yetone/avante.nvim",
--     build = "make",
--     opts = {
--       provider = "openai",
--       providers = {
--         openai = {
--           endpoint = "http://10.12.215.17:8000/v1",
--           model = "gpt-4.1",
--           timeout = 30000, -- Timeout in milliseconds
--           extra_request_body = {
--             temperature = 0.75,
--             max_tokens = 32768,
--           },
--         },
--       },
--     },
--   },
-- }

return {
  {
    "yetone/avante.nvim",
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- ⚠️ must add this setting! ! !
    --build = vim.fn.has "win32" and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" or "make",
    build = "make",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      -- add any opts here
      -- for example
      provider = "openai",
      providers = {
        claude = {
          endpoint = "https://oneapi-comate.baidu-int.com",
          model = "Claude Sonnet 4.6",
          api_key_name = "ANTHROPIC_AUTH_TOKEN",
          timeout = 30000,
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
        },
        openai = {
          endpoint = "https://oneapi-comate.baidu-int.com/v1",
          model = "glm-5.1",
          api_key_name = "ANTHROPIC_AUTH_TOKEN",
          timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 32768,
          },
        },
      },
      behaviour = {
        auto_check_diagnostics = false,
        auto_suggestions = false,
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "echasnovski/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "stevearc/dressing.nvim", -- for input provider dressing
      "folke/snacks.nvim", -- for input provider snacks
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      -- {
      --   -- support for image pasting
      --   "HakonHarnes/img-clip.nvim",
      --   event = "VeryLazy",
      --   opts = {
      --     -- recommended settings
      --     default = {
      --       embed_image_as_base64 = false,
      --       prompt_for_file_name = false,
      --       drag_and_drop = {
      --         insert_mode = true,
      --       },
      --       -- required for Windows users
      --       --use_absolute_path = true,
      --     },
      --   },
      -- },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "Kaiser-Yang/blink-cmp-avante",
    },
    opts = {
      sources = {
        default = { "avante" },
        providers = {
          avante = {
            module = "blink-cmp-avante",
            name = "Avante",
            opts = {},
          },
        },
      },
      snippets = {
        preset = "luasnip",
      },
    },
    opts_extend = { "sources.default" },
  },
}
