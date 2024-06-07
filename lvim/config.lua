--[[
lvim is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general
--lvim.use_icons = false
lvim.log.level = "warn"
lvim.format_on_save.enabled = true
lvim.format_on_save.timeout = 2000
lvim.format_on_save.pattern = { "*.sh", "*.py", "*.lua" }

--lvim.colorscheme = "onedarker"
lvim.colorscheme = "sonokai"
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
lvim.keys.command_mode["<C-h>"] = ":TmuxNavigateLeft<cr>"
lvim.keys.command_mode["<C-j>"] = ":TmuxNavigateDown<cr>"
lvim.keys.command_mode["<C-k>"] = ":TmuxNavigateUp<cr>"
lvim.keys.command_mode["<C-l>"] = ":TmuxNavigateRight<cr>"
lvim.keys.normal_mode["<C-h>"] = ":TmuxNavigateLeft<cr>"
lvim.keys.normal_mode["<C-j>"] = ":TmuxNavigateDown<cr>"
lvim.keys.normal_mode["<C-k>"] = ":TmuxNavigateUp<cr>"
lvim.keys.normal_mode["<C-l>"] = ":TmuxNavigateRight<cr>"
vim.cmd([[
nnoremap <expr> n  'Nn'[v:searchforward]
nnoremap <expr> N  'nN'[v:searchforward]
]])


lvim.builtin.telescope.defaults.layout_config.width = 0.7
lvim.builtin.telescope.defaults.layout_config.preview_cutoff = 75



-- unmap a default keymapping
-- vim.keymap.del("n", "<C-Up>")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

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
lvim.builtin.cmp.formatting.source_names["tmux"] = "(Tmux)"
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
lvim.builtin.which_key.mappings["C"] = {
  name = "Python",
  c = { "<cmd>lua require('swenv.api').pick_venv()<cr>", "Choose Env" },
}
lvim.builtin.which_key.mappings["b"] = { "<cmd>lua require('fzf-lua').buffers()<cr>", "Open Buffers" }
lvim.builtin.which_key.mappings["m"] = { "<cmd>lua require('fzf-lua').oldfiles()<cr>", "Open Recent File" }
lvim.builtin.which_key.mappings["f"] = {
  name = "Find",
  a = { "<cmd>Telescope builtin<cr>", "All builtins" },
  b = { "<cmd>lua require('fzf-lua').buffers()<cr>", "Open Buffers" },
  C = { "<cmd>Telescope commands_history<cr>", "Rerun Commands" },
  c = { "<cmd>Telescope commands<cr>", "Run Commands" },
  d = { find_cwd_files, "find same dir" },
  D = { "<cmd>DiffviewOpen<cr>", "DiffviewOpen" },
  f = { "<cmd>lua require('fzf-lua').files({ resume = true })<CR>", "Find File" },
  g = { find_gitroot_files, "Find same prj" },
  h = { "<cmd>Telescope help_tags<cr>", "Help" },
  k = { "<cmd>Telescope keymaps<cr>", "keymappings" },
  m = { "<cmd>lua require('fzf-lua').oldfiles()<cr>", "Open Recent File" },
  O = { "<cmd>Telescope vim_options<cr>", "Vim Options" },
  p = { "<cmd>lua require('fzf-lua').registers({ resume = true })<cr>", "Paste registers" },
  P = { "<cmd>Telescope projects<CR>", "Projects" },
  r = { "<cmd>lua require('fzf-lua').live_grep_resume()<cr>", "Live Grep" },
  s = { "<cmd>lua require('fzf-lua').lsp_document_symbols({ resume = true })<cr>", "Buffer Symbol" },
  S = { "<cmd>ua require('fzf-lua').lsp_workspace_symbols({ resume = true })<cr>", "WorkSpace Symbol" },
  t = { "<cmd>TlistToggle<cr>", "taglist" },
  T = { "<cmd>SymbolsOutline<cr>", "Symbols" },
  w = { "<cmd>lua require('fzf-lua').grep_cword({ resume = true })<cr>", "Grep Word" },
}
lvim.builtin.which_key.mappings["Ls"] = { "<cmd>Pmsg lua print(vim.inspect(lvim))<cr>", "Show Confs" }
lvim.builtin.which_key.mappings["o"] = {
  -- toggle options
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
lvim.builtin.which_key.mappings["t"] = {
  name = "Diagnostics",
  t = { "<cmd>TroubleToggle<cr>", "trouble" },
  w = { "<cmd>TroubleToggle workspace_diagnostics<cr>", "workspace" },
  d = { "<cmd>TroubleToggle document_diagnostics<cr>", "document" },
  q = { "<cmd>TroubleToggle quickfix<cr>", "quickfix" },
  l = { "<cmd>TroubleToggle loclist<cr>", "loclist" },
  r = { "<cmd>TroubleToggle lsp_references<cr>", "references" },
}
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


-- https://github.com/neovim/nvim-lspconfig
-- pyright
-- https://github.com/microsoft/pyright/blob/main/docs/configuration.md

-- generic LSP settings
--

-- ---@usage disable automatic installation of servers
--lvim.lsp.automatic_servers_installation = false

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright", "bashls" })
--local pyright_opts = {
--  cmd = { "pyright-langserver", "--stdio" },
--  filetypes = { "python" },
--
--  single_file_support = true,
--  settings = {
--    pyright = {
--      disableLanguageServices = false,
--      disableOrganizeImports = false
--    },
--    python = {
--      analysis = {
--        autoImportCompletions = true,
--        autoSearchPaths = true,
--        --diagnosticMode = "workspace", -- openFilesOnly, workspace
--        diagnosticMode = "openFilesOnly", -- openFilesOnly, workspace
--        typeCheckingMode = "basic", -- off, basic, strict
--        useLibraryCodeForTypes = true,
--        diagnosticSeverityOverrides = {
--          reportUnusedImport = "none",
--          reportUnusedClass = "none",
--          reportUnusedFunction = "none",
--          reportUnusedVariable = "none",
--        }
--      }
--    }
--  },
--}
--require("lvim.lsp.manager").setup("pyright", pyright_opts)

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
   debug = true,
})


-- open log
-- :NullLsLog  

local linters = require "lvim.lsp.null-ls.linters"
-- pip install flake8 flake8-docstrings
linters.setup { 
  -- https://flake8.pycqa.org/en/2.5.5/warnings.html 
  -- https://pep8.readthedocs.io/en/latest/intro.html#error-codes
  --{ command = "flake8" , args = {"--max-line-length", "119", "--ignore", "F401", "--select", "E203"}, filetypes = { "python" } },
  { command = "flake8" , args = {"--max-line-length", "119", "--ignore", "F401", }, filetypes = { "python" } },
  -- https://www.pydocstyle.org/en/stable/error_codes.html
  { command = "pydocstyle" ,  args= {"--ignore=D203,D204,D213,D400,D401,D402,D403,D415,D417"}, filetypes = { "python" } },

}

-- -- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
  -- { command = "stylua", filetypes = { "lua" } }, -- cargo install stylua
  --  pip3 install click==7.1.2 'black[python2]==21.4b0'
  { command = "black", filetypes = { "python" } },
  { command = "isort",       filetypes = { "python" } },
  { command = "beautysh",       filetypes = { "sh" } },
  -- { command = "clang-format", args = { "--style={BasedOnStyle: Google, DerivePointerAlignment: false}" } },
  { command = "clang-format" },
})

lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
  return server ~= "sqlls"
end, lvim.lsp.automatic_configuration.skipped_servers)

-- require("lvim.lsp.manager").setup("sqlls", {
--   cmd = {"sql-language-server", "up", "--method", "stdio"};
--   filetypes = {"sql", "mysql"};
--   root_dir = function() return vim.loop.cwd() end;
-- })
--   {
--     -- each formatter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--     command = "prettier",
--     ---@usage arguments to pass to the formatter
--     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--     extra_args = { "--print-with", "100" },
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "typescript", "typescriptreact" },
--   },
-- }

-- -- set additional linters
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   { command = "flake8", filetypes = { "python" } },
--   {
--     -- each linter accepts a list of options identical to https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#Configuration
--     command = "shellcheck",
--     ---@usage arguments to pass to the formatter
--     -- these cannot contain whitespaces, options such as `--line-width 80` become either `{'--line-width', '80'}` or `{'--line-width=80'}`
--     extra_args = { "--severity", "warning" },
--   },
--   {
--     command = "codespell",
--     ---@usage specify which filetypes to enable. By default a providers will attach to all the filetypes it supports.
--     filetypes = { "javascript", "python" },
--   },
-- }


local function echo(text, hl_group)
  --vim.api.nvim_echo({ { string.format('[conf] %s', text), hl_group or 'Normal' } }, false, {})
  print(string.format('[conf] %s', text))
end

lvim.plugins = {
  {"AckslD/swenv.nvim"},
  { "andersevenrud/cmp-tmux", dependencies = "hrsh7th/nvim-cmp", event = "InsertEnter" },

  -- { "andymass/vim-matchup" },
  {
    "christoomey/vim-tmux-navigator",
    config = function()
      vim.g.tmux_navigator_disable_when_zoomed = 1
    end,
  },
  { "commiyou/molokai" },
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
    "AckslD/nvim-neoclip.lua",
    dependencies = {
      -- you'll need at least one of these
      { 'nvim-telescope/telescope.nvim' },
      -- {'ibhagwan/fzf-lua'},
    },
    config = function()
      require('neoclip').setup()
    end,
  },
  { "ConradIrwin/vim-bracketed-paste" },
  { "dbeniamine/cheat.sh-vim" },
  { "elzr/vim-json" },
  {
    -- https://github.com/echasnovski/mini.align
    -- ga/gA to enter split lua pattern
    -- Press s to enter split Lua pattern.
    -- Press j to choose justification side from available ones ("left", "center", "right", "none").
    -- Press m to enter merge delimiter.
    -- Press f to enter filter Lua expression to configure which parts will be affected (like "align only first column").
    -- Press i to ignore some commonly unwanted split matches.
    -- Press p to pair neighboring parts so they be aligned together.
    -- Press t to trim whitespace from parts.
    -- Press <BS> (backspace) to delete some last pre-step.
    "echasnovski/mini.align",
    version = "*",
    keys = { "ga", "gA" },
    opts = function()
      require("mini.align").setup()
    end,
  },
  {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- calling `setup` is optional for customization
      -- :edit $NVIM_LOG_FILE
      --  Vim:Failed to start server: no such file or directory
      require("fzf-lua").setup({
        fzf_opts = { ['--cycle'] = true}, 
        --keymap={builtin={["ctrl-]"]  = "preview-page-down",["ctrl-["]    = "preview-page-up",}}
      })
      vim.api.nvim_set_keymap('i', '<C-x><C-f>', '<cmd>lua require("fzf-lua").complete_path()<CR>', {noremap = true})
    end
  },
  {
    'echasnovski/mini.hipatterns',
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
  {
    -- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-bracketed.md
    -- Buffer	[B [b ]b ]B	MiniBracketed.buffer()
    -- Comment block	[C [c ]c ]C	MiniBracketed.comment()
    -- Conflict marker	[X [x ]x ]X	MiniBracketed.conflict()
    -- Diagnostic	[D [d ]d ]D	MiniBracketed.diagnostic()
    -- File on disk	[F [f ]f ]F	MiniBracketed.file()
    -- Indent change	[I [i ]i ]I	MiniBracketed.indent()
    -- Jump from jumplist inside current buffer	[J [j ]j ]J	MiniBracketed.jump()
    -- Location from location list	[L [l ]l ]L	MiniBracketed.location()
    -- Old files	[O [o ]o ]O	MiniBracketed.oldfile()
    -- Quickfix entry from quickfix list	[Q [q ]q ]Q	MiniBracketed.quickfix()
    -- Tree-sitter node and parents	[T [t ]t ]T	MiniBracketed.treesitter()
    -- Undo states from specially tracked linear history	[U [u ]u ]U	MiniBracketed.undo()
    -- Window in current tab	[W [w ]w ]W	MiniBracketed.window()
    -- Yank selection replacing latest put region	[Y [y ]y ]Y	MiniBracketed.yank()
    'echasnovski/mini.bracketed',
    version = false,
    opts = function()
      require("mini.jump").setup()
    end,
  },
  -- {
  --   --     object_scope = 'ii',
  --   -- object_scope_with_border = 'ai',

  --   -- Motions (jump to respective border line; if not present - body line)
  --   -- goto_top = '[i',
  --   -- goto_bottom = ']i',
  --   'echasnovski/mini.indentscope',
  --   version = false,
  --   opts = function()
  --     require("mini.indentscope").setup()
  --   end,
  -- },

  {
    -- forward = 'f',
    -- backward = 'F',
    -- forward_till = 't',
    -- backward_till = 'T',
    -- repeat_jump = ';',
    'echasnovski/mini.jump',
    version = false,

    opts = function()
      require("mini.jump").setup()
    end,
  },
  {
    'echasnovski/mini.fuzzy',
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
  -- { 'echasnovski/mini.completion', version = false ,
  --   opts = function()
  --     require("mini.completion").setup()
  --   end,
  -- },

  {
    "folke/trouble.nvim",
    cmd = "TroubleToggle",
  },
  { "farmergreg/vim-lastplace" },
  -- { "f-person/git-blame.nvim" }, -- too slow when big file!
  { "hnamikaw/vim-autohotkey" },
  {
    "hrsh7th/cmp-cmdline",
    dependencies = "hrsh7th/nvim-cmp",
    event = "InsertEnter"
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
    -- quick motion
    -- s/S/gs<char><char>: search forward/backward/other window
    -- s<space><space> to jump to an empty line.
    -- s{char}<space> to jump to the end of a line
    -- s<enter> to repeat the last search.
    -- s<enter><enter>... or s{char}<enter><enter>... to traverse through the matches.
    "ggandor/leap.nvim",
    dependencies = "tpope/vim-repeat",
    config = function()
      -- require('leap').add_default_mappings()
      vim.keymap.set({'n', 'x', 'o'}, 's',  '<Plug>(leap-forward-to)')
      vim.keymap.set({'n', 'x', 'o'}, 'S',  '<Plug>(leap-backward-to)')
      -- vim.keymap.set({'x', 'o'},      'x',  '<Plug>(leap-forward-till)')
      -- vim.keymap.set({'x', 'o'},      'X',  '<Plug>(leap-backward-till)')
      -- vim.keymap.set({'n', 'x', 'o'}, 'gs', '<Plug>(leap-from-window)')
    end
  },
  {
    -- TODO
    --Delete/fold/comment/etc. paragraphs without leaving your position (zfarp[leap]).
    -- Clone text objects in the blink of an eye, even from another window, by turning on paste_on_remote_yank (yaRp[leap]).
    -- Do the above stunt in Insert mode (...<C-o>yaRW[leap]...).
    -- Fix a typo with a short, atomic command sequence (cimw[leap][correction]).
    -- Operate on distant lines: drr[leap].
    -- Use count: e.g. y3rr[leap] yanks 3 lines, just as 3yy would do.

    "ggandor/leap-spooky.nvim",
    dependencies = "ggandor/leap.nvim",
  },
  {
    -- https://github.com/daipeihust/im-select install binary
    "keaising/im-select.nvim",
    enabled = function() return jit.os == "OSX" end,
    config = function()
      require("im_select").setup({})
    end,
  },
  --  {
  -- 	-- https://github.com/karb94/neoscroll.nvim
  -- 	"karb94/neoscroll.nvim",
  -- 	keys = {
  -- 		"<C-u>",
  -- 		"<C-d>",
  -- 		"<C-b>",
  -- 		"<C-f>",
  -- 		"<C-y>",
  -- 		"<C-e>",
  -- 		"zt",
  -- 		"zz",
  -- 		"zb",
  -- 	},
  -- 	config = function()
  -- 		require("neoscroll").setup()
  -- 	end,
  -- },
  { "mbbill/fencview" },
  { "mildred/vim-bufmru" },
  { "morhetz/gruvbox" },
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
  --   -- https://github.com/nathom/filetype.nvim
  --   "nathom/filetype.nvim",
  --   config = function()
  --     require("filetype").setup({
  --       overrides = {
  --         extensions = {
  --           html = "html",
  --           cts = "typescript",
  --           mts = "typescript",
  --           -- Set the filetype of *.pn files to potion
  --           pn = "potion",
  --           hbs = "html.handlebars",
  --         },
  --         literal = {
  --           ["editorconfig"] = "editorconfig",
  --           -- Set the filetype of files named "MyBackupFile" to lua
  --           MyBackupFile = "lua",

  --         },
  --         complex = {
  --           -- Set the filetype of any full filename matching the regex to gitconfig
  --           [".*git/config"] = "gitconfig", -- Included in the plugin
  --         },

  --         -- The same as the ones above except the keys map to functions
  --         function_extensions = {
  --           ["cpp"] = function()
  --             vim.bo.filetype = "cpp"
  --             -- Remove annoying indent jumping
  --             vim.bo.cinoptions = vim.bo.cinoptions .. "L0"
  --           end,
  --           ["pdf"] = function()
  --             vim.bo.filetype = "pdf"
  --             -- Open in PDF viewer (Skim.app) automatically
  --             vim.fn.jobstart("open -a skim " .. '"' .. vim.fn.expand("%") .. '"')
  --           end,
  --         },
  --         function_literal = {
  --           Brewfile = function()
  --             vim.cmd("syntax off")
  --           end,
  --         },
  --         shebang = {
  --           -- Set the filetype of files with a dash shebang to sh
  --           dash = "sh",
  --         },
  --       },
  --     })
  --   end,
  -- },
  {
    'ojroques/nvim-osc52',
    -- enabled = #(os.getenv('SSH_TTY') or "") > 0, -- if inside SSH
    -- iterm2
    config = function()
      require('osc52').setup {
        max_length = 0,          -- Maximum length of selection (0 for no limit)
        silent = true,           -- Disable message on successful copy
        trim = true,             -- Trim surrounding whitespaces before copy
        tmux_passthrough = true, -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
        --
        -- Use tmux passthrough (requires tmux: set -g allow-passthrough on)
        --tmux_passthrough = #(os.getenv('SSH_TTY') or "") > 0, -- if inside SSH
      }
      local function copy()
        -- echo(vim.v.event.operator .. vim.v.event.regname)
        -- check vim.o.clipboard not override
        if vim.v.event.operator == 'y' and (vim.v.event.regname == '' or vim.v.event.regname == '+') then
          require('osc52').copy_register('+')
        end
      end

      vim.api.nvim_create_autocmd('TextYankPost', { callback = copy })
    end
  },
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function() require "lsp_signature".on_attach() end,
  },
  {
    "romgrk/nvim-treesitter-context",
    config = function()
      require("treesitter-context").setup {
        enable = true,   -- Enable this plugin (Can be enabled/disabled later via commands)
        throttle = true, -- Throttles plugin updates (may improve performance)
        max_lines = 0,   -- How many lines the window should span. Values <= 0 mean no limit.
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
    end
  },
  -- {
  --   "phaazon/hop.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("hop").setup()
  --     vim.api.nvim_set_keymap("n", "s", ":HopChar2<cr>", { silent = true })
  --     vim.api.nvim_set_keymap("n", "S", ":HopWord<cr>", { silent = true })
  --   end,
  -- },
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
    "RRethy/vim-hexokinase",
    build = "make hexokinase",
    config = function()
      vim.g.Hexokinase_highlighters = { "backgroundfull" }
    end,
  },
  {
    "simrat39/symbols-outline.nvim",
    config = function()
      require('symbols-outline').setup()
    end
  },
  {
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim"
  },
  {
    -- https://github.com/sQVe/sort.nvim
    --   -- List of delimiters, in descending order of priority, to automatically sort on.
    -- delimiters = {
    --   ',',
    --   '|',
    --   ';',
    --   ':',
    --   's', -- Space
    --   't', -- Tab
    --   }
    --   Cmd :[range]Sort[!] [delimiter][b][i][n][o][u][x]
    --   Use [!] to reverse the sort order.
    --   Use [b] to sort based on the first binary number in the word.
    --   Use [i] to ignore the case when sorting.
    --   Use [n] to sort based on the first decimal number in the word.
    --   Use [o] to sort based on the first octal number in the word.
    --   Use [u] to only keep the first instance of words within the selection. Leading and trailing whitespace are not considered when testing for uniqueness.
    --   Use [x] to sort based on the first hexadecimal number in the word. A leading 0x or 0X is ignored.
    "sQVe/sort.nvim",
    cmd = { "Sort" },
    config = function()
      require("sort").setup({})
    end,
  },
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
  { "simrat39/symbols-outline.nvim" },
  {
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim"
  },
  { "szw/vim-maximizer" },
  {
    "sainnhe/sonokai",
    config = function()
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

        augroup SonokaiCustom
        autocmd!
        autocmd ColorScheme sonokai call s:sonokai_custom()
        augroup END
        ]])

      vim.g.sonokai_style = 'default'
      vim.g.sonokai_transparent_background = 0
      vim.g.sonokai_diagnostic_text_highlight = 1
      vim.g.sonokai_diagnostic_line_highlight = 1
      vim.g.sonokai_better_performance = 1
      -- vim.g.sonokai_enable_italic = 1
      vim.g.sonokai_disable_italic_comment = 1
    end
  },

  { "stevearc/dressing.nvim" },  -- :%Subvert/facilit{y,ies}/building{,s}/g
  { "tpope/vim-abolish" },  -- :%Subvert/facilit{y,ies}/building{,s}/g
  { "tpope/vim-fugitive" },
  { "tpope/vim-surround" }, --  https://github.com/tpope/vim-surround   cs{from_char}{to_char} / ds{char} / ys{motion}{char}
  -- yssb - wrap the entire line in parentheses
  { "tpope/vim-repeat" },   -- ysiw<em>
  -- {
  --   "tzachar/cmp-tabnine",
  --   build = "./install.sh",
  --   dependencies = "hrsh7th/nvim-cmp",
  --   event =
  --   "InsertEnter"
  -- },
  { "wellle/tmux-complete.vim" },
  { "yegappan/taglist" },
  {
    -- hint when you type
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function() require "lsp_signature".on_attach() end,
  },
}

-- local highlight = {
--     "RainbowRed",
--     "RainbowYellow",
--     "RainbowBlue",
--     "RainbowOrange",
--     "RainbowGreen",
--     "RainbowViolet",
--     "RainbowCyan",
-- }

-- local hooks = require "ibl.hooks"
-- -- create the highlight groups in the highlight setup hook, so they are reset
-- -- every time the colorscheme changes
-- hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
--     vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
--     vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
--     vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
--     vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
--     vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
--     vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
--     vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
-- end)

-- require("ibl").setup { indent = { highlight = highlight } }

local cmp = require("cmp")

cmp.setup({
  sources = {
    { name = "tmux" },
  },
})
-- cmp.setup.cmdline(":", {
--   mapping = cmp.mapping.preset.cmdline(),
--   sources = {
--     { name = "path" },
--     { name = "cmdline" },
--   },
-- })
cmp.setup.cmdline("/", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    {
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
    },
  },
})
-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- lvim.autocommands.custom_groups = {
--   { "BufWinEnter", "*.lua", "setlm.opt.relativenumber = true -- lua print(vim.o.rnu)
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


-- put({1, 2, 3})
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

nnoremap <silent><C-w>z :MaximizerToggle<CR>
vnoremap <silent><C-w>z :MaximizerToggle<CR>gv
"imap <expr> <Plug>(vimrc:copilot-dummy-map) copilot#Accept("\<Tab>")

" jump to the previous function
autocmd FileType c,cpp nnoremap <silent> [f :call
\ search('\(\(if\\|for\\|while\\|switch\\|catch\)\_s*\)\@64<!(\_[^)]*)\_[^;{}()]*\zs{', "bw")<CR>
" jump to the next function
autocmd FileType c,cpp nnoremap <silent> ]f :call
\ search('\(\(if\\|for\\|while\\|switch\\|catch\)\_s*\)\@64<!(\_[^)]*)\_[^;{}()]*\zs{', "w")<CR>
" autocmd FileType c,cpp :FencAutoDetect

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
" Enable true color 启用终端24位色
" if exists('+termguicolors')
"   let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
"   let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
"   set termguicolors
" endif

if (has("termguicolors"))
set termguicolors
endif

" Enable true color ?????ն?24λɫ
if exists('+termguicolors')
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
set termguicolors
endif

]])

local function curr_clipboard()
  return vim.o.clipboard == "unnamedplus" and "󱉫" or ""
end
local function curr_paste()
  return vim.o.paste and "" or ""
end


local components = require "lvim.core.lualine.components"
--tableMerge(lvim.builtin.lualine.sections.lualine_x, lvim.builtin.lualine.sections.lualine_x, { 'encoding' })
--
lvim.builtin.lualine.sections.lualine_c = {
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
}
-- 命令行 移动
vim.api.nvim_set_keymap('c', '<C-a>', '<Home>', {noremap = true})
vim.api.nvim_set_keymap('c', '<M-b>', '<S-Left>', {noremap = true})
vim.api.nvim_set_keymap('c', '<M-f>', '<S-Right>', {noremap = true})
vim.api.nvim_set_keymap('c', '<C-f>', '<Right>', {noremap = true})

