-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = true
lvim.format_on_save.timeout = 2000
lvim.format_on_save.pattern = { "*.sh", "*.py", "*.lua" }

-- to disable icons and use a minimalist setup, uncomment the following
lvim.use_icons = false

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["H"] = ":BufferLineCyclePrev<cr>"
lvim.keys.normal_mode["L"] = ":BufferLineCycleNext<cr>"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-b>"] = "<left>"
lvim.keys.normal_mode["<C-f>"] = "<right>"

lvim.keys.normal_mode["<c-g>"] = "1<c-g>"
lvim.keys.normal_mode["0"] = "^"
-- :h cmdline-editing,  <c-f>
vim.cmd([[
nnoremap <expr> n  'Nn'[v:searchforward]
nnoremap <expr> N  'nN'[v:searchforward]
]])


lvim.builtin.telescope.defaults.layout_config.width = 0.7
lvim.builtin.telescope.defaults.layout_config.preview_cutoff = 75
lvim.builtin.cmp.experimental.ghost_text = true


-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
local _, actions = pcall(require, "telescope.actions")
local _, action_layout = pcall(require, "telescope.actions.layout")
local _, action_state = pcall(require, "telescope.actions.state")

-- lvim.builtin.bufferline.options.mode = "tabs"
-- lvim.builtin.bufferline.options.sort_by = function (buffer_a, buffer_b)
--   return buffer_a.mo
-- end
lvim.builtin.telescope.defaults.dynamic_preview_title = true
-- lvim.builtin.telescope.defaults.path_display.shorten = { len = 3, exclude = { -1 } }
lvim.builtin.telescope.defaults.path_display = { "smart" }
lvim.builtin.telescope.defaults.mappings = {
  -- for input mode
  i = {
    ["<C-j>"] = actions.move_selection_next,
    ["<C-k>"] = actions.move_selection_previous,
    --["<C-n>"] = actions.cycle_history_next,
    --["<C-p>"] = actions.cycle_history_prev,
    ["<C-f>"] = action_layout.toggle_preview,
    -- ["<esc>"] = actions.close,
  },
}

-- https://github.com/jose-elias-alvarez/null-ls.nvim/issues/428
local notify = vim.notify
vim.notify = function(msg, ...)
  if msg:match("warning: multiple different client offset_encodings") then
    return
  end

  notify(msg, ...)
end

-- lvim.builtin.illuminate.active = false
-- table.insert(lvim.builtin.cmp.sources, 1, { name = "tmux", option = { all_panes = true } })

for _i, _data in ipairs(lvim.builtin.cmp.sources) do
  if _data["name"] == "buffer" then
    lvim.builtin.cmp.sources[_i] = {
      name = "buffer",
      option = {
        get_bufnrs = function()
          local buf = vim.api.nvim_get_current_buf()
          local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
          print(vim.api.nvim_buf_line_count(buf))
          -- io.open("/home/bin.you/debug.txt", "w+"):write
          if byte_size > 1024 * 1024 then -- 1 Megabyte max
            return {}
          end
          return { buf }
        end,
      },
    }
  end
end

local function find_cwd_files(prompt_bufnr)
  local opt = {
    cwd = vim.fn.expand("%:p:h"),

  }
  require('fzf-lua').files(opt)
  -- https://github.com/ibhagwan/fzf-lua/wiki/Advanced#fzf-exec-acts
  -- require 'fzf-lua'.fzf_exec("fd --no-ignore --color=never --type f --hidden --follow --exclude .git",
  --   {
  --     actions = require 'fzf-lua'.defaults.actions.files,
  --     cwd = vim.fn.expand("%:p:h"),

  --   })
end

local function find_gitroot_files(prompt_bufnr)
  local file_dir = vim.fn.expand('%:p:h')
  local result = vim.fn.system("cd " .. file_dir .. "; git rev-parse --show-toplevel 2>/dev/null || pwd")
  local opt = {
    cwd = vim.trim(result)
  }
  require('fzf-lua').files(opt)
end
-- binding for switching
lvim.builtin.which_key.mappings["b"] = { "<cmd>lua require('fzf-lua').buffers()<cr>", "Open Buffers" }
lvim.builtin.which_key.mappings["m"] = { "<cmd>lua require('fzf-lua').oldfiles()<cr>", "Open Recent File" }
lvim.builtin.which_key.mappings["f"] = {
  name = "Find",
  a = { "<cmd>lua require('fzf-lua').builtin()<cr>", "All builtins" },
  b = { "<cmd>lua require('fzf-lua').buffers()<cr>", "Open Buffers" },
  C = { "<cmd>lua require('fzf-lua').command_history()<cr>", "Rerun Commands" },
  c = { "<cmd>lua require('fzf-lua').commands()<cr>", "Run Commands" },
  d = { find_cwd_files, "find same dir" },
  D = { "<cmd>DiffviewOpen<cr>", "DiffviewOpen" },
  f = { "<cmd>lua require('fzf-lua').files({ resume = true })<CR>", "Find File" },
  g = { find_gitroot_files, "Find same prj" },
  h = { "<cmd>Telescope help_tags<cr>", "Help" },
  k = { "<cmd>Telescope keymaps<cr>", "keymappings" },
  m = { "<cmd>lua require('fzf-lua').oldfiles({ file_ignore_patterns = {'COMMIT_EDITMSG'} } )<cr>", "Open Recent File" },
  O = { "<cmd>Telescope vim_options<cr>", "Vim Options" },
  p = { "<cmd>lua require('fzf-lua').registers({ resume = true })<cr>", "Paste registers" },
  P = { "<cmd>Telescope projects<CR>", "Projects" },
  r = { "<cmd>lua require('fzf-lua').live_grep_resume()<cr>", "Live Grep" },
  R = { '<cmd>lua require("spectre").open_visual({select_word=true})<cr>', "Search files & Replace" },
  s = { "<cmd>lua require('fzf-lua').lsp_document_symbols({ resume = true })<cr>", "Buffer Symbol" },
  S = { "<cmd>lua require('fzf-lua').lsp_workspace_symbols({ resume = true })<cr>", "WorkSpace Symbol" },
  t = { "<cmd>TlistToggle<cr>", "taglist" }, -- yegappan/taglist
  w = { "<cmd>lua require('fzf-lua').grep_cword({ resume = true })<cr>", "Grep Word" },
}
lvim.builtin.which_key.mappings["Ls"] = { "<cmd>Pmsg lua print(vim.inspect(lvim))<cr>", "Show Confs" }
lvim.builtin.which_key.mappings["o"] = {
  -- toggle options
  C = { "<cmd>lua require('swenv.api').pick_venv()<cr>", "Choose Python Env" }, -- AckslD/swenv.nvim
  p = { "<cmd>setlocal paste!<cr>", "paste" },
  g = { "<cmd>e ++enc=gbk<cr>", "fenc gbk" },
  u = { "<cmd>e ++enc=utf8<cr>", "fenc utf8" },
  c = {
    "<cmd>lua if vim.o.clipboard == '' then vim.o.clipboard = 'unnamedplus' else vim.o.clipboard = '' end<cr>",
    "clipboard",
  },
}
lvim.builtin.which_key.mappings["[b"] = { "<cmd>BufMRUPrev<cr>", "BufMRUPrev" }
lvim.builtin.which_key.mappings["]b"] = { "<cmd>BufMRUNext<cr>", "BufMRUNext" }
lvim.builtin.which_key.mappings["l"]["f"] = {
  function()
    require("lvim.lsp.utils").format { timeout_ms = 2000 }
  end,
  "Format",
}

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
}

lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enabled = true

require("nvim-treesitter.install").prefer_git = true

-- generic LSP settings
-- https://www.lunarvim.org/docs/configuration/language-features/language-servers
-- https://github.com/tamago324/nlsp-settings.nvim/blob/main/schemas/_generated/pyright.json
-- :LspSettings pyright
-- :LspSettings update pyright



-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. !!Requires `:LvimCacheReset` to take effect!!
-- ---`:LvimInfo` lists which server(s) are skiipped for the current filetype
-- vim.tbl_map(function(server)
--   return server ~= "emmet_ls"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

--local linters = require "lvim.lsp.null-ls.linters"
--linters.setup { { command = "pyright", filetypes = { "python" } } }
--
require("null-ls").setup({
  debug = false,
})

-- :LvimCacheReset
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })



-- open log
-- :NullLsLog

-- local linters = require "lvim.lsp.null-ls.linters"
-- -- pip install flake8 flake8-docstrings
-- linters.setup {
--   -- https://flake8.pycqa.org/en/2.5.5/warnings.html
--   -- https://pep8.readthedocs.io/en/latest/intro.html#error-codes
--   --{ command = "flake8" , args = {"--max-line-length", "119", "--ignore", "F401", "--select", "E203"}, filetypes = { "python" } },
--   { command = "flake8" , args = {"--max-line-length", "119", "--ignore", "F401", }, filetypes = { "python" } },
--   -- https://www.pydocstyle.org/en/stable/error_codes.html
--   { command = "pydocstyle" ,  args= {"--ignore=D203,D204,D213,D400,D401,D402,D403,D415,D417"}, filetypes = { "python" } },

-- }

-- -- -- set a formatter, this will override the language server formatting capabilities (if it exists)
-- local formatters = require("lvim.lsp.null-ls.formatters")
-- formatters.setup({
--   -- { command = "stylua", filetypes = { "lua" } }, -- cargo install stylua
--   --  pip3 install click==7.1.2 'black[python2]==21.4b0'
--   --{ command = "black", filetypes = { "python" } },
--   --{ command = "isort",       filetypes = { "python" } },
--   { command = "beautysh",       filetypes = { "sh" } },
--   -- { command = "clang-format", args = { "--style={BasedOnStyle: Google, DerivePointerAlignment: false}" } },
--   { command = "clang-format" },
-- })



-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   -- { command = "ruff", "-n", "-e", "--stdin-filename", "$FILENAME", "-" },
--   -- { command = "flake8", filetypes = { "python" } },
--   -- {
--   --   -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--   --   command = "shellcheck",
--   --   ---@usage arguments to pass to the formatter
--   --   -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--   --   extra_args = { "--severity", "warning" },
--   -- },
--   -- {
--   --   command = "codespell",
--   --   ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--   --   filetypes = { "javascript", "python" },
--   -- },
-- }


local function echo(text, hl_group)
  --vim.api.nvim_echo({ { string.format('[conf] %s', text), hl_group or 'Normal' } }, false, {})
  print(string.format('[conf] %s', text))
end

lvim.plugins = {
  {
    'Wansmer/sibling-swap.nvim',
    dependencies = { 'nvim-treesitter' },
    opts = { { highlight_node_at_cursor = true } },
  },
  {
    "cameron-wags/rainbow_csv.nvim",
    config = true,
    ft = {
      'csv',
      'tsv',
      'csv_semicolon',
      'csv_whitespace',
      'csv_pipe',
      'rfc_csv',
      'rfc_semicolon'
    },
    cmd = {
      'RainbowDelim',
      'RainbowDelimSimple',
      'RainbowDelimQuoted',
      'RainbowMultiDelim'
    }

  },
  { 'mbbill/undotree' }, -- :UndotreeToggle
  { "tpope/vim-unimpaired" },
  {
    "Julian/vim-textobj-variable-segment", --  iv / av for variable segments.(snake case/camel case)
    dependencies = {
      "kana/vim-textobj-user",
    }
  },
  {
    'nvim-pack/nvim-spectre', -- :Spectre, search and replace
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  {
    'echasnovski/mini.ai', -- text obj,
    version = false,
    config = function()
      require('mini.ai').setup()
    end
  },
  {
    "whiteinge/diffconflicts",
  }, -- :DiffConflicts
  {
    "AndrewRadev/splitjoin.vim",
  }, -- gS / gJ  split or join
  {
    'echasnovski/mini.operators',
    version = false,
    opts = {},
  },
  {
    "folke/neodev.nvim",
    opts = {},
  }, --  Neovim setup for init.lua and plugin development with full signature help, docs and completion for the nvim lua API.
  -- { # TODO
  --   "chrisgrieser/nvim-spider", -- w/e/b
  --   lazy = true,
  --   opts = { consistentOperatorPending = false },
  --   keys = {
  --     {
  --       "e",
  --       "<cmd>lua require('spider').motion('e')<CR>",
  --       mode = { "n", "x" },
  --     },
  --     {
  --       "w",
  --       "<cmd>lua require('spider').motion('w')<CR>",
  --       mode = { "n", "x" },
  --     },
  --     -- {
  --     --   "cw",
  --     --   "c<cmd>lua require('spider').motion('e')<CR>",
  --     --   mode = { "n" },
  --     -- },
  --     {
  --       "b",
  --       "<cmd>lua require('spider').motion('b')<CR>",
  --       mode = { "n", "x" },
  --     }
  --   }
  -- },
  -- {
  --   'abecodes/tabout.nvim',
  --   lazy = false,
  --   config = function()
  --     require('tabout').setup {
  --       tabkey = '<Tab>',             -- key to trigger tabout, set to an empty string to disable
  --       backwards_tabkey = '<S-Tab>', -- key to trigger backwards tabout, set to an empty string to disable
  --       act_as_tab = true,            -- shift content if tab out is not possible
  --       act_as_shift_tab = false,     -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
  --       default_tab = '<C-t>',        -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
  --       default_shift_tab = '<C-d>',  -- reverse shift default action,
  --       enable_backwards = true,      -- well ...
  --       completion = false,           -- if the tabkey is used in a completion pum
  --       tabouts = {
  --         { open = "'", close = "'" },
  --         { open = '"', close = '"' },
  --         { open = '`', close = '`' },
  --         { open = '(', close = ')' },
  --         { open = '[', close = ']' },
  --         { open = '{', close = '}' }
  --       },
  --       ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
  --       exclude = {} -- tabout will ignore these filetypes
  --     }
  --   end,
  --   dependencies = { -- These are optional
  --     "nvim-treesitter/nvim-treesitter",
  --     "L3MON4D3/LuaSnip",
  --     "hrsh7th/nvim-cmp"
  --   },
  --   lazy = true,             -- Set this to true if the plugin is optional
  --   event = 'InsertCharPre', -- Set the event to 'InsertCharPre' for better compatibility
  --   priority = 1000,

  -- },
  {
    "tenxsoydev/tabs-vs-spaces.nvim",
    config = function()
      require("tabs-vs-spaces").setup()
      lvim.autocommands = {
        {
          "BufEnter",                                       -- see `:h autocmd-events`
          {                                                 -- this table is passed verbatim as `opts` to `nvim_create_autocmd`
            pattern = { "*.py", "*.sh", "*.cpp", "*.lua" }, -- see `:h autocmd-events`
            command = "TabsVsSpacesToggle",
          }
        },
      }
    end
  },
  {
    "AckslD/swenv.nvim",
    config = function()
      lvim.builtin.which_key.mappings["o"]["C"] = { "<cmd>lua require('swenv.api').pick_venv()<cr>",
        "Choose Python Env" }
    end
  },
  {
    'chentoast/marks.nvim', -- mx Set mark x, m] Move to next mark; dm<space> Delete all marks in the current buffer
    opts = {}               -- m0, global marker, MarksListBuf, MarksListAll
  },
  {
    "smjonas/inc-rename.nvim",
    config = function()
      require("inc_rename").setup({
        input_buffer_type = "dressing",
      })
      lvim.builtin.which_key.mappings["l"]["r"] = { ":IncRename ", "Rename" }
      lvim.builtin.which_key.mappings["l"]["R"] = {
        function()
          return ":IncRename " .. vim.fn.expand "<cword>"
        end,
        "Rename keep",
        expr = true,
      }
    end,
  },
  {
    "dnlhc/glance.nvim",
    config = function()
      require('glance').setup()
      vim.keymap.set('n', 'gD', '<CMD>Glance definitions<CR>')
      vim.keymap.set('n', 'gR', '<CMD>Glance references<CR>')
      vim.keymap.set('n', 'gY', '<CMD>Glance type_definitions<CR>')
      vim.keymap.set('n', 'gM', '<CMD>Glance implementations<CR>')
    end,

  },
  {
    'mrjones2014/legendary.nvim', -- TODO:
    priority = 10000,
    lazy = false,
    -- sqlite is only needed if you want to use frecency sorting
    -- dependencies = { 'kkharji/sqlite.lua' }
    config = function()
      require('legendary').setup({ extensions = { lazy_nvim = true } })
    end
  },
  {
    url = "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    config = function()
      require("lsp_lines").setup()
      -- Disable virtual_text since it's redundant due to lsp_lines.
      vim.diagnostic.config({
        virtual_text = true,
        virtual_lines = false,
      })
      lvim.builtin.which_key.mappings["lb"] = { "<cmd>lua require('lsp_lines').toggle()<cr>", "Toggle lsp_lines" }
    end,
  },
  {
    "kevinhwang91/nvim-bqf",
    event = "WinEnter",
    dependencies = { 'mhinz/vim-grepper' },
    config = function()
      local cmd = vim.cmd
      vim.g.grepper = { tools = { 'rg', 'grep' }, searchreg = 1 }
      -- cmd(([[
      --     aug Grepper
      --         au!
      --         au User Grepper ++nested %s
      --     aug END
      -- ]]):format([[call setqflist([], 'r', {'context': {'bqf': {'pattern_hl': '\%#' . getreg('/')}}})]]))

      cmd([[
        nmap <leader>gs  <plug>(GrepperOperator)
        xmap <leader>gs  <plug>(GrepperOperator)
        nnoremap <leader>* :Grepper -cword -noprompt -buffers<cr>
        ]])
    end,
  },
  {
    "andersevenrud/cmp-tmux",
    dependencies = "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    config = function()
      lvim.builtin.cmp.formatting.source_names["tmux"] = "(Tmux)"
      table.insert(lvim.builtin.cmp.sources, {
        {
          name = "tmux",
          option = {
            all_panes = false, -- 防止太卡
            capture_history = true
          }
        },

      }
      )
      -- require("cmp").setup({
      --   sources = {
      --     {
      --       name = "tmux",
      --       option = {
      --         all_panes = false, -- 防止太卡
      --         capture_history = true
      --       }
      --     },
      --   },
      -- })
    end
  },

  {
    "christoomey/vim-tmux-navigator",
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>",  mode = { "n", "c" } },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>",  mode = { "n", "c" } },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>",    mode = { "n", "c" } },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", mode = { "n", "c" } },
    },
    config = function()
      vim.g.tmux_navigator_disable_when_zoomed = 1
      -- vim.g.tmux_navigator_preserve_zoom = 1
    end,
  },
  -- { "commiyou/molokai" },
  {
    "commiyou/a.vim",
    config = function()
      vim.g.alternateNoDefaultAlternate = 1
      vim.g.alternateNoDefaultMapping = 1
      vim.g.alternateRelativeFiles = 1
      vim.g.alternateNoFindBuffer = 1
    end,
  },
  {
    "danymat/neogen", -- doc gene
    config = function()
      require('neogen').setup({
        snippet_engine = "luasnip",
        languages = {
          python = {
            template = {
              annotation_convention = "numpydoc"
            }
          }
        }
      })
    end
  },
  { "ConradIrwin/vim-bracketed-paste" }, -- automatic `:set paste`
  { "dbeniamine/cheat.sh-vim" },         -- <leader>KB for current line, :Cheat + question
  { "elzr/vim-json" },
  {
    "ibhagwan/fzf-lua", -- TODO:
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- calling `setup` is optional for customization
      -- :edit $NVIM_LOG_FILE
      --  Vim:Failed to start server: no such file or directory
      local _, actions = pcall(require, "telescope.actions")
      local actions = require "fzf-lua".actions
      require("fzf-lua").setup({
        fzf_opts = { ['--cycle'] = true },
        actions = {
          files = {
            ["default"] = actions.file_edit_or_qf,
            ["ctrl-x"]  = actions.file_split,
            ["ctrl-v"]  = actions.file_vsplit,
            ["ctrl-t"]  = actions.file_tabedit,
            ["alt-q"]   = actions.file_sel_to_qf,
            ["alt-l"]   = actions.file_sel_to_ll,

          },
          buffers = {
          },
        },
        files = {
          fd_opts = [[--no-ignore --color=never --type f --hidden --follow --exclude .git]],
          gd_opts = [[--no-ignore --color=never --files --hidden --follow -g "!.git"]],
        },
        buffers = {
          actions = {
            ["ctrl-x"] = require 'fzf-lua'.actions.buf_split,
            --["ctrl-i"] = { fn = actions.buf_del, reload = true },
          }
        }
        --keymap={builtin={["ctrl-]"]  = "preview-page-down",["ctrl-["]    = "preview-page-up",}}
      })
      vim.api.nvim_set_keymap('i', '<C-x><C-f>', '<cmd>lua require("fzf-lua").complete_path()<CR>',
        { noremap = true })
    end
  },
  {
    'echasnovski/mini.hipatterns', -- TODO:
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    opts = function()
      local hi = require("mini.hipatterns")
      return {
        highlighters = {
          -- fixme     = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
          -- hack      = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
          -- todo      = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
          -- note      = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

          -- Highlight hex color strings (`#rrggbb`) using that color
          hex_color = hi.gen_highlighter.hex_color(),
        },
      }
    end,
  },
  -- { 'echasnovski/mini.move',   version = false, config = true }, -- <M-h/j/k/l> move line; TODO:

  --{"romainl/vim-cool"}, -- no hlserach
  {
    'echasnovski/mini.fuzzy', -- fuzzy for telescope
    version = false,
    opts = function()
      require("mini.fuzzy").setup()
      require('telescope').setup({
        defaults = {
          generic_sorter = require('mini.fuzzy').get_telescope_sorter
        }
      })
    end,
  },
  -- {
  --   "folke/trouble.nvim",
  --   cmd = "TroubleToggle",
  -- },
  { "farmergreg/vim-lastplace" },
  -- { "f-person/git-blame.nvim" }, -- too slow when big file!
  { "hnamikaw/vim-autohotkey" },
  {
    "hrsh7th/cmp-cmdline",
    dependencies = "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    config = function()
      local cmp = require("cmp")
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          {
            name = "buffer",
            option = {
              get_bufnrs = function()
                local buf = vim.api.nvim_get_current_buf()
                local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
                -- print(vim.api.nvim_buf_line_count(buf))
                -- io.open("/home/bin.you/debug.txt", "w+"):write
                if byte_size > 1024 * 1024 then -- 1 Megabyte max
                  return {}
                end
                return { buf }
              end,
            },
          },
        },
      })
    end
  },
  -- { "itchyny/vim-cursorword" },
  {
    "commiyou/vim-mark",
    dependencies = { "inkarkat/vim-ingo-library" },
    config = function()
      vim.cmd([[
     let g:mwDefaultHighlightingPalette = 'extended'
     let g:mwHistAdd = '@'
     let g:mwAutoLoadMarks = 1
     let g:mw_no_mappings = 1
     nmap <leader>M <Plug>MarkSet
     ]])
    end,
  },
  {
    'kevinhwang91/nvim-hlslens',
    config = function()
      require('hlslens').setup({ calm_down = true })
      local kopts = { noremap = true, silent = true }
      vim.api.nvim_set_keymap('n', 'n',
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', 'N',
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        kopts)
      vim.api.nvim_set_keymap('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
      vim.api.nvim_set_keymap('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
    end
  },
  {
    "mireq/large_file",
    config = function()
      require("large_file").setup({
        size_limit = 50 * 1024 * 1024,
      }
      )
    end
  },
  {
    "folke/flash.nvim", -- navigate your code with search labels, enhanced character motions, and Treesitter integration.
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
      modes = {
        search = {
          enabled = false,
        },
        char = {
          jump_labels = true
        },
      },

    },
    -- stylua: ignore
    keys = {
      { "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
      { "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
      { "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
      { "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
    },
  },
  {
    -- https://github.com/daipeihust/im-select install binary
    "keaising/im-select.nvim",
    enabled = function() return jit.os == "OSX" end,
    config = function()
      require("im_select").setup({})
    end,
  },
  --{ "mildred/vim-bufmru" },
  {
    -- https://github.com/xeho91/.dotfiles/blob/main/editors/nvim/lazyvim/lua/plugins/dial.lua
    "monaqa/dial.nvim",
    -- stylua: ignore
    keys = {
      { mode = "n", "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" },
      { mode = "n", "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" },
      { mode = "v", "<C-a>", function() return require("dial.map").inc_visual() end, expr = true, desc = "Increment" },
      { mode = "v", "<C-x>", function() return require("dial.map").dec_visual() end, expr = true, desc = "Decrement" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.decimal_int,
          augend.integer.alias.hex,
          augend.integer.alias.octal,
          augend.integer.alias.binary,
          augend.date.alias["%Y/%m/%d"],
          augend.date.alias["%m/%d/%Y"],
          augend.date.alias["%d/%m/%Y"],
          augend.date.alias["%m/%d/%y"],
          augend.date.alias["%d/%m/%y"],
          augend.date.alias["%m/%d"],
          augend.date.alias["%-m/%-d"],
          augend.date.alias["%Y-%m-%d"],
          augend.date.alias["%Y年%-m月%-d日"],
          augend.date.alias["%Y年%-m月%-d日(%ja)"],
          augend.date.alias["%H:%M:%S"],
          augend.date.alias["%H:%M"],
          augend.constant.alias.ja_weekday,
          augend.constant.alias.ja_weekday_full,
          augend.constant.alias.bool,
          augend.constant.alias.alpha,
          augend.constant.alias.Alpha,
          augend.constant.new({
            elements = { "enable", "disable" },
            word = true,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "Enable", "Disable" },
            word = true,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "ENABLE", "DISABLE" },
            word = true,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "on", "off" },
            word = true,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "On", "Off" },
            word = true,
            cyclic = true,
          }),
          augend.constant.new({
            elements = { "ON", "OFF" },
            word = true,
            cyclic = true,
          }),
          augend.semver.alias.semver,
        },

        typescript = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.constant.new({ elements = { "let", "const" } }),
        },

        visual = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.date.alias["%Y/%m/%d"],
          augend.constant.alias.alpha,
          augend.constant.alias.Alpha,
        },
      })
    end,
  },
  -- {
  --   'ojroques/nvim-osc52', -- copy from ssh , for nvim let 0.10
  --   -- enabled = #(os.getenv('SSH_TTY') or "") > 0, -- if inside SSH
  --   -- iterm2
  --   config = function()
  --     require('osc52').setup {
  --       max_length = 0,          -- Maximum length of selection (0 for no limit)
  --       silent = true,           -- Disable message on successful copy
  --       trim = true,             -- Trim surrounding whitespaces before copy
  --       tmux_passthrough = true, -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
  --       --
  --       -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
  --       --tmux_passthrough = #(os.getenv('SSH_TTY') or "") > 0, -- if inside SSH
  --     }
  --     local function copy()
  --       -- echo(vim.v.event.operator .. vim.v.event.regname)
  --       -- check vim.o.clipboard not override
  --       if vim.v.event.operator == 'y' and (vim.v.event.regname == '' or vim.v.event.regname == '+') then
  --         require('osc52').copy_register('+')
  --       end
  --     end

  --     vim.api.nvim_create_autocmd('TextYankPost', { callback = copy })
  --   end
  -- },
  {
    "romgrk/nvim-treesitter-context",
    config = function()
      require("treesitter-context").setup {
        enable = true,   -- Enable this plugin (Can be enabled/disabled later via commands)
        throttle = true, -- Throttles plugin updates (may improve performance)
        max_lines = 5,   -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 15,
        patterns = {     -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
          -- For all filetypes
          -- Note that setting an entry here replaces all other patterns for this entry.
          -- By setting the 'default' entry below, you can control which nodes you want to
          -- appear in the context window.
          default = {
            'class',
            'function',
            'method',
          },
        },
      }
      vim.keymap.set("n", "[c", function()
        require("treesitter-context").go_to_context(vim.v.count1)
      end, { silent = true })
    end
  },
  {
    "rmagatti/goto-preview",
    config = function()
      require('goto-preview').setup {
        width = 120,              -- Width of the floating window
        height = 25,              -- Height of the floating window
        default_mappings = false, -- Bind default mappings
        debug = false,            -- Print debug information
        opacity = nil,            -- 0-100 opacity level of the floating window where 100 is fully transparent.
        post_open_hook = nil      -- A function taking two arguments, a buffer and a window to be ran as a hook.
        -- You can use "default_mappings = true" setup option
        -- Or explicitly set keybindings
        -- vim.cmd("nnoremap gpd <cmd>lua require('goto-preview').goto_preview_definition()<CR>")
        -- vim.cmd("nnoremap gpi <cmd>lua require('goto-preview').goto_preview_implementation()<CR>")
        -- vim.cmd("nnoremap gP <cmd>lua require('goto-preview').close_all_win()<CR>")
      }
    end
  },
  {
    "RRethy/vim-hexokinase", -- show color
    build = "make hexokinase",
    config = function()
      vim.g.Hexokinase_highlighters = { "backgroundfull" }
    end,
  },
  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline", "OutlineOpen" },
    keys = { -- Example mapping to toggle outline
      { "<leader>ot", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    config = function()
      require("outline").setup(
        {
          preview_window = {
            auto_preview = true,
          },
          outline_items = {
            show_symbol_lineno = true,
          },
        }
      )
    end,
  },

  {
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim"
  },
  -- {
  --   -- https://github.com/sQVe/sort.nvim
  --   --   -- List of delimiters, in descending order of priority, to automatically sort on.
  --   -- delimiters = {
  --   --   ',',
  --   --   '|',
  --   --   ';',
  --   --   ':',
  --   --   's', -- Space
  --   --   't', -- Tab
  --   --   }
  --   --   Cmd :[range]Sort[!] [delimiter][b][i][n][o][u][x]
  --   --   Use [!] to reverse the sort order.
  --   --   Use [b] to sort based on the first binary number in the word.
  --   --   Use [i] to ignore the case when sorting.
  --   --   Use [n] to sort based on the first decimal number in the word.
  --   --   Use [o] to sort based on the first octal number in the word.
  --   --   Use [u] to only keep the first instance of words within the selection. Leading and trailing whitespace are not considered when testing for uniqueness.
  --   --   Use [x] to sort based on the first hexadecimal number in the word. A leading 0x or 0X is ignored.
  --   "sQVe/sort.nvim",
  --   cmd = { "Sort" },
  --   config = function()
  --     require("sort").setup({})
  --   end,
  -- },
  {
    "smoka7/multicursors.nvim",
    event = "VeryLazy",
    dependencies = {
      'smoka7/hydra.nvim',
    },
    opts = {},
    cmd = { 'MCstart', 'MCvisual', 'MCclear', 'MCpattern', 'MCvisualPattern', 'MCunderCursor' },
    keys = {
      {
        mode = { 'v', 'n' },
        '<Leader>ee',
        '<cmd>MCstart<cr>',
        desc = 'Create a selection for selected text or word under the cursor',
      },
    },
  },
  {
    "szw/vim-maximizer",
    config = function()
      vim.cmd([[
        nnoremap <silent><C-w>z :MaximizerToggle<CR>
        vnoremap <silent><C-w>z :MaximizerToggle<CR>gv
        ]])
    end
  },
  {
    "sainnhe/sonokai",
    lazy = false,
    priority = 1000,
    config = function()
      require 'lualine'.setup { options = { theme = 'sonokai' } }

      vim.cmd([[
        function! s:sonokai_custom() abort
        " Link a highlight group to a predefined highlight group.
        " See `colors/sonokai.vim` for all predefined highlight groups.
        " highlight! link groupA groupB
        " highlight! link groupC groupD

        " Initialize the color palette.
        " The first parameter is a valid value for `g:sonokai_style`,
        " and the second parameter is a valid value for `g:sonokai_colors_override`.
        let l:palette = sonokai#get_palette('default', {})
        " Define a highlight group.
        " The first parameter is the name of a highlight group,
        " the second parameter is the foreground color,
        " the third parameter is the background color,
        " the fourth parameter is for UI highlighting which is optional,
        " and the last parameter is for `guisp` which is also optional.
        " See `autoload/sonokai.vim` for the format of `l:palette`.
        " call sonokai#highlight('NonText', l:palette.red, l:palette.none, 'undercurl', l:palette.red)

        "
        " The "NonText" highlighting will be used for "eol", "extends" and "precedes".  "Whitespace" for "nbsp", "tab" and "trail".
        " SpecialKey Unprintable characters: Text displayed differently from what it realy is. But not 'listchars' whitespace
        call sonokai#highlight('NonText', l:palette.grey, l:palette.none)
        call sonokai#highlight('SpecialKey', l:palette.grey, l:palette.none)
        call sonokai#highlight('Whitespace', l:palette.grey, l:palette.none)

        endfunction

        " TODO:
        " augroup SonokaiCustom
        " autocmd!
        " autocmd ColorScheme sonokai call s:sonokai_custom()
        " augroup END
        ]])

      vim.g.sonokai_transparent_background = 0
      vim.g.sonokai_diagnostic_text_highlight = 1
      vim.g.sonokai_diagnostic_line_highlight = 1
      -- -- The configuration options should be placed before `colorscheme sonokai`.
      vim.g.sonokai_better_performance = 1
      -- vim.g.sonokai_enable_italic = 1
      vim.g.sonokai_disable_italic_comment = 1
      vim.g.sonokai_style = 'default'
      lvim.colorscheme = "sonokai"
    end
  },
  { "stevearc/dressing.nvim" },
  { "tpope/vim-abolish" }, -- :%Subvert/facilit{y,ies}/building{,s}/g
  { "tpope/vim-fugitive" },
  {
    -- ys{motion}{char} / dst / dss
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end
  },
  { "tpope/vim-repeat" }, -- ysiw<em>
  --{ "wellle/tmux-complete.vim" },
  { "yegappan/taglist" },
  {
    "ray-x/lsp_signature.nvim",
    -- event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      require 'lsp_signature'.setup(opts)
      vim.keymap.set({ 'n' }, '<Leader>k', function()
        vim.lsp.buf.signature_help()
      end, { silent = true, noremap = true, desc = 'toggle signature' })
    end
  },
  -- { -- TODO:

  --   'ray-x/navigator.lua',
  --   dependencies = {
  --     { 'ray-x/guihua.lua',     build = 'cd lua/fzy && make' },
  --     { 'neovim/nvim-lspconfig' },
  --   },
  --   config = function()
  --     require 'navigator'.setup({
  --       default_mapping = false,
  --       lsp = {
  --         disable_lsp = { 'pylsd', 'sqlls', "pylsp", "pyright" },
  --       }
  --     })
  --   end
  -- },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
  -- {
  --   "chrisgrieser/cmp_yanky",
  --   config = function()
  --     require "cmp_yanky".setup {}

  --     lvim.builtin.cmp.formatting.source_names["cmp_yanky"] = "(Yanky)"
  --     table.insert(lvim.builtin.cmp.sources, {
  --       name = "cmp_yanky"
  --     })
  --   end
  -- },
  {
    'tzachar/highlight-undo.nvim',
    opts = {
    },
  },
  -- {
  --   "Exafunction/codeium.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "hrsh7th/nvim-cmp",
  --   },
  --   config = function()
  --     require("codeium").setup({
  --     })
  --     lvim.builtin.cmp.formatting.source_names["codeium"] = "(Codeium)"
  --     table.insert(lvim.builtin.cmp.sources, {
  --       name = "codeium"
  --     })
  --     require('cmp').setup {
  --       mapping = require("cmp").mapping.preset.insert({
  --         ["<c-x><c-y>"] = require('codieium').make_cmp_map()
  --       }),
  --     }
  --   end
  -- },
  -- {
  --   'milanglacier/minuet-ai.nvim',
  --   dependencies = { 'nvim-lua/plenary.nvim', 'hrsh7th/nvim-cmp' },
  --   config = function()
  --     require('minuet').setup {
  --       -- Your configuration options here
  --       provider = "gemini",
  --     }

  --     require('cmp').setup {
  --       mapping = require("cmp").mapping.preset.insert({
  --         ["<c-x><c-y>"] = require('minuet').make_cmp_map()
  --       }),
  --     }
  --   end
  -- },
  -- {
  --   "jackMort/ChatGPT.nvim",
  --   event = "VeryLazy",
  --   config = function()
  --     require("chatgpt").setup({ model = "gpt-4o" })
  --   end,
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "folke/trouble.nvim",
  --     "nvim-telescope/telescope.nvim"
  --   }
  -- },
  -- {
  --   "yetone/avante.nvim",
  --   event = "VeryLazy",
  --   lazy = false,
  --   opts = {
  --     -- add any opts here
  --     provider = "openai",
  --     endpoint = "http://10.12.215.17:8000/v1/chat/completions",
  --     parse_curl_args = function(opts, code_opts)
  --       return {
  --         url = opts.endpoint,
  --         headers = {
  --           ["Accept"] = "application/json",
  --           ["Content-Type"] = "application/json",
  --           ["Authorization"] = "Bearer " .. os.getenv(opts.api_key_name),
  --         },
  --         body = {
  --           model = opts.model,
  --           messages = { -- you can make your own message, but this is very advanced
  --             { role = "system", content = code_opts.system_prompt },
  --             { role = "user",   content = require("avante.providers.openai").get_user_message(code_opts) },
  --           },
  --           temperature = 0,
  --           max_tokens = 4096,
  --           stream = true, -- this will be set by default.
  --         },
  --       }
  --     end,
  --     parse_response_data = function(data_stream, event_state, opts)
  --       require("avante.providers").openai.parse_response(data_stream, event_state, opts)
  --     end,
  --     --api_key_name = "OPENAI_API_KEY"
  --   },
  --   build = ":AvanteBuild", -- This is optional, recommended tho. Also note that this will block the startup for a bit since we are compiling bindings in Rust.
  --   dependencies = {
  --     "stevearc/dressing.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "MunifTanjim/nui.nvim",
  --     --- The below dependencies are optional,
  --     "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
  --     --"zbirenbaum/copilot.lua",    -- for providers='copilot'
  --     {
  --       -- support for image pasting
  --       "HakonHarnes/img-clip.nvim",
  --       event = "VeryLazy",
  --       opts = {
  --         -- recommended settings
  --         default = {
  --           embed_image_as_base64 = false,
  --           prompt_for_file_name = false,
  --           drag_and_drop = {
  --             insert_mode = true,
  --           },
  --           -- required for Windows users
  --           use_absolute_path = true,
  --         },
  --       },
  --     },
  --     {
  --       -- Make sure to setup it properly if you have lazy=true
  --       'MeanderingProgrammer/render-markdown.nvim',
  --       opts = {
  --         file_types = { "markdown", "Avante" },
  --       },
  --       ft = { "markdown", "Avante" },
  --     },
  --   },
  -- },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim", -- Optional
      {
        "stevearc/dressing.nvim",      -- Optional: Improves the default Neovim UI
        opts = {},
      },
    },
    opts = {
      --log_level = "DEBUG"
    },
    config = function()
      require("codecompanion").setup({
        -- log_level = "DEBUG", -- or "TRACE"
        adapters = {
          openai = function()
            return require("codecompanion.adapters").extend("openai", {
              env = {
                url = "http://10.12.215.17:8000/v1/chat/completions",
                --api_key =
                --sk-
                --2r3aBJdY1C83D1AyQuK0T3BlbkFJgC8twJCaURWvTwFSyuOS
              },
            })
          end,
        },
      })

      --vim.api.nvim_set_keymap("n", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
      --vim.api.nvim_set_keymap("v", "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<LocalLeader>a", "<cmd>CodeCompanionToggle<cr>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("v", "<LocalLeader>a", "<cmd>CodeCompanionToggle<cr>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("v", "ga", "<cmd>CodeCompanionAdd<cr>", { noremap = true, silent = true })

      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanionToggle]])
    end
  },
  {
    'ZSaberLv0/ZFVimIM', -- ;; 开启或关闭输入法, ;: 切换词库, - 和 = 翻页,[ 和 ] 快速从词组选字,
    dependencies = { 'ZSaberLv0/ZFVimJob', 'ZSaberLv0/ZFVimIM_openapi', 'ZSaberLv0/ZFVimIM_english_base', 'ZSaberLv0/ZFVimIM_pinyin' },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require 'nvim-treesitter.configs'.setup {
        textobjects = {
          select = {
            enable = true,

            -- Automatically jump forward to textobj, similar to targets.vim
            --lNvimTreeookahead = true,

            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              -- You can optionally set descriptions to the mappings (used in the desc parameter of
              -- nvim_buf_set_keymap) which plugins like which-key display
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
              -- You can also use captures from other query groups like `locals.scm`
              ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
            },
            -- You can choose the select mode (default is charwise 'v')
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * method: eg 'v' or 'o'
            -- and should return the mode ('v', 'V', or '<c-v>') or a table
            -- mapping query_strings to modes.
            selection_modes = {
              ['@parameter.outer'] = 'v', -- charwise
              ['@function.outer'] = 'V',  -- linewise
              ['@class.outer'] = '<c-v>', -- blockwise
            },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`.
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * selection_mode: eg 'v'
            -- and should return true or false
            include_surrounding_whitespace = false,
          },
        },
      }
    end

  },
  {
    "kiyoon/treesitter-indent-object.nvim",
    keys = {
      {
        "ai",
        function() require 'treesitter_indent_object.textobj'.select_indent_outer() end,
        mode = { "x", "o" },
        desc = "Select context-aware indent (outer)",
      },
      {
        "aI",
        function() require 'treesitter_indent_object.textobj'.select_indent_outer(true) end,
        mode = { "x", "o" },
        desc = "Select context-aware indent (outer, line-wise)",
      },
      {
        "ii",
        function() require 'treesitter_indent_object.textobj'.select_indent_inner() end,
        mode = { "x", "o" },
        desc = "Select context-aware indent (inner, partial range)",
      },
      {
        "iI",
        function() require 'treesitter_indent_object.textobj'.select_indent_inner(true, 'V') end,
        mode = { "x", "o" },
        desc = "Select context-aware indent (inner, entire range) in line-wise visual mode",
      },
    },
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    tag = "v2.20.8", -- Use v2
    event = "BufReadPost",
    config = function()
      vim.opt.list = true
      require("indent_blankline").setup {
        space_char_blankline = " ",
        show_current_context = true,
        show_current_context_start = true,
      }
    end,
  },
  -- {
  --   "yioneko/nvim-yati", -- indent
  --   version = "*",
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  --   config = function()
  --     require("nvim-treesitter.configs").setup {
  --       yati = {
  --         enable = true,
  --         -- Disable by languages, see `Supported languages`
  --         --disable = { "python" },

  --         -- Whether to enable lazy mode (recommend to enable this if bad indent happens frequently)
  --         default_lazy = true,

  --         -- Determine the fallback method used when we cannot calculate indent by tree-sitter
  --         --   "auto": fallback to vim auto indent
  --         --   "asis": use current indent as-is
  --         --   "cindent": see `:h cindent()`
  --         -- Or a custom function return the final indent result.
  --         default_fallback = "auto"
  --       },
  --       indent = {
  --         enable = false -- disable builtin indent module
  --       }
  --     }
  --   end
  -- },
  {
    "voldikss/vim-skylight",
    keys = {
      { "gp", "<cmd>Skylight!<cr>", mode = { "n", "x" } },
    },
  },
  {
    "unblevable/quick-scope",
    config = function()
      vim.cmd([[
      " Trigger a highlight in the appropriate direction when pressing these keys:
      let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
      ]])
    end
  },
  {
    "simrat39/symbols-outline.nvim",
    opts = { show_relative_numbers = true, show_symbol_details = false, autofold_depth = 1 },

  },

  -- {
  --   "tris203/hawtkeys.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  --   config = {}
  -- }

  -- @@@@@@end

}


local highlight = {
  "RainbowRed",
  "RainbowYellow",
  "RainbowBlue",
  "RainbowOrange",
  "RainbowGreen",
  "RainbowViolet",
  "RainbowCyan",
}

-- local hooks = require "indent_blankline.hooks"
-- -- create the highlight groups in the highlight setup hook, so they are reset
-- -- every time the colorscheme changes
-- hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
--   vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
--   vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
--   vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
--   vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
--   vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
--   vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
--   vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
-- end)

-- require("indent_blankline").setup { indent = { highlight = highlight } }


vim.o.rnu = true
vim.o.gdefault = true -- the :substitute flag 'g' is default on
vim.o.eol = false     -- no auto add <EOL>
vim.o.wrap = true
vim.opt.isfname = vim.opt.isfname - "="
vim.o.mouse = "h"
vim.o.splitbelow = false
--vim.o.clipboard = #(os.getenv('SSH_TTY') or "") > 0 and "unnamedplus" or "" -- if inside SSH enable
vim.o.clipboard = ""
vim.o.et = true


vim.cmd [[:command! -nargs=1 I lua inspectFn(<f-args>)]]
function inspectFn(obj)
  vim.print(vim.fn.luaeval(obj))
end

--:lua put({1, 2, 3})
function _G.put(...)
  local objects = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, "\n"))
  return ...
end

vim.cmd([[
function! s:pmsg(cmd)
  redir => message
  silent execute a:cmd
  redir END
  if empty(message)
    echoerr "no output"
  else
    " use "new" instead of "tabnew" below if you prefer split windows instead of tabs
    new
    setlocal buftype=nofile bufhidden=hide noswapfile nomodified
    silent put=message
  endif
endfunction

command! -nargs=+ -complete=command Pmsg call s:pmsg(<q-args>)

set ttm=10
set tm=500
set fileencodings=utf8,gb18030

"imap <expr> <Plug>(vimrc:copilot-dummy-map) copilot#Accept("\<Tab>")

"set tags=./tags;,tags;../tags;
set tags=./tags;$HOME
nnoremap <C-\> :tab split<CR>:exec("tag ".expand("<cword>"))<CR>
set list
" set lcs=tab:>-,trail:·,eol:$   " listchars
set lcs=tab:>-,trail:·
nnoremap gt :ts <C-R>=expand("<cword>")<CR><CR>
if filereadable(expand("~/.self.vimrc"))
source ~/.self.vimrc
endif

" https://github.com/tmux/tmux/issues/1246
" Enable true color
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif


" copy from http://howivim.com/2016/damian-conway/

" Make BS/DEL work as expected in visual modes (i.e. delete the selected text)...
xmap <BS> x
" Make vaa select the entire file...
xmap aa VGo1G

" Make q extend to the surrounding string...
xmap  q   "_y:call ExtendVisualString()<CR>

let s:closematch = [ '', '', '}', ']', ')', '>', '/', "'", '"', '`' ]
let s:ldelim = '\< \%(q [qwrx]\= \| [smy] \| tr \) \s*
\               \%(
\                   \({\) \| \(\[\) \| \((\) \| \(<\) \| \(/\)
\               \)
\               \|
\                   \(''\) \| \("\) \| \(`\)
\'
let s:ldelim = substitute(s:ldelim, '\s\+', '', 'g')

function! ExtendVisualString ()
    let [lline, lcol, lmatch] = searchpos(s:ldelim, 'bWp')
    if lline == 0
        return
    endif
    let rdelim = s:closematch[lmatch]
    normal `>
    let rmatch = searchpos(rdelim, 'W')
    normal! v
    call cursor(lline, lcol)
endfunction


" Make v<motions>Y act like an incremental v<motion>y
vnoremap <silent>       Y  <ESC>:silent let @y = @"<CR>gv"Yy:silent let @" = @y<CR>

" Make Y<motion> act like an incremental y<motion>
nnoremap <silent><expr> Y  Incremental_Y()

function! Incremental_Y ()
    " After the Y operator, read in the associated motion
    let motion = nr2char(getchar())

    " If it's a (slowly typed) YY, do the optimized version instead (see below)
    if motion == 'Y'
        call Incremental_YY()
        return

    " If it's a text object, read in the associated motion
    elseif motion =~ '[ia]'
        let motion .= nr2char(getchar())
    endif

    " If it's a search, read in the associated pattern
    elseif motion =~ '[/?]'
        let motion .= input(motion) . "\<CR>"
    endif

    " Copy the current contents of the default register into the 'y register
    let @y = @"

    " Return a command sequence that yanks into the 'Y register,
    " then assigns that cumulative yank back to the default register
    return '"Yy' . motion . ':let @" = @y' . "\<CR>"
endfunction


" Make YY act like an incremental yy
nnoremap <silent>  YY  :call Incremental_YY()<CR>

function! Incremental_YY () range
    " Grab all specified lines and append them to the default register
    let @" .= join(getline(a:firstline, a:lastline), "\n") . "\n"
endfunction

]])

local function curr_clipboard()
  return vim.o.clipboard == "unnamedplus" and "󱉫" or ""
end
local function curr_paste()
  return vim.o.paste and "" or ""
end

local current_signature = function(width) -- TODO: ray-x/lsp_signature.nvim
  if not pcall(require, 'lsp_signature') then return end
  local sig = require("lsp_signature").status_line(width)
  return sig.label .. "🐼" .. sig.hint
end


local components = require "lvim.core.lualine.components"
--tableMerge(lvim.builtin.lualine.sections.lualine_x, lvim.builtin.lualine.sections.lualine_x, { 'encoding' })
--
lvim.builtin.lualine.sections.lualine_c = {
  current_signature,
  components.diff,
  components.python_env,
  curr_clipboard,
  curr_paste,
  'searchcount',
}
lvim.builtin.lualine.sections.lualine_x = {
  'hostname',
  'encoding',
  components.diagnostics,
  components.lsp,
  components.spaces,
  components.filetype,
  'swenv'
}
-- 命令行 移动
vim.api.nvim_set_keymap('c', '<C-a>', '<Home>', { noremap = true })
vim.api.nvim_set_keymap('c', '<M-b>', '<S-Left>', { noremap = true })
vim.api.nvim_set_keymap('c', '<M-f>', '<S-Right>', { noremap = true })
vim.api.nvim_set_keymap('c', '<C-f>', '<Right>', { noremap = true })
vim.api.nvim_set_keymap('v', '<Leader>y', '"+y', { noremap = true, silent = true }) -- TODO: not work


-- vi(gq
vim.api.nvim_set_keymap('x', 'gq', ':s/\\v(\\w+)/"\\1"/<cr>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('n', 'gq', ':set opfunc=v:lua.format_operator<cr>g@', { noremap = true, silent = true })

-- function _G.format_operator(type)
--   local start_row, start_col, end_row, end_col = unpack(vim.fn.getpos("'<"))
--   local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
--   for i, line in ipairs(lines) do
--     line = string.gsub(line, '(\\w+)', '"%1"')
--     lines[i] = line
--   end
--   vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, lines)
-- end
