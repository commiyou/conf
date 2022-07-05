--[[
lvim is the global options object

Linters should be
filled in as strings with either
a global executable or a path to
an executable
]]
-- THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT

-- general
lvim.log.level = "warn"
lvim.format_on_save = true
lvim.colorscheme = "onedarker"
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
-- add your own keymapping
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

-- unmap a default keymapping
-- vim.keymap.del("n", "<C-Up>")
-- override a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>" -- or vim.keymap.set("n", "<C-q>", ":q<cr>" )

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
local _, actions = pcall(require, "telescope.actions")
local _, action_layout = pcall(require, "telescope.actions.layout")
local _, action_state = pcall(require, "telescope.actions.state")

lvim.builtin.telescope.defaults.dynamic_preview_title = true
-- lvim.builtin.telescope.defaults.path_display.shorten = { len = 3, exclude = { -1 } }
lvim.builtin.telescope.defaults.path_display = { "smart" }
lvim.builtin.telescope.defaults.mappings = {
	-- for input mode
	i = {
		["<C-j>"] = actions.move_selection_next,
		["<C-k>"] = actions.move_selection_previous,
		["<C-n>"] = actions.cycle_history_next,
		["<C-p>"] = actions.cycle_history_prev,
		["<C-f>"] = action_layout.toggle_preview,
		-- ["<esc>"] = actions.close,
	},
}

table.insert(lvim.builtin.cmp.sources, 1, { name = "copilot" })
table.insert(lvim.builtin.cmp.sources, 1, { name = "tmux", option = { all_panes = true } })
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
	require("telescope.builtin").find_files(opt)
end

local function run_selection(prompt_bufnr, map)
	actions.select_default:replace(function()
		actions.close(prompt_bufnr)
		local selection = action_state.get_selected_entry()
		vim.cmd([[!git log ]] .. selection[1])
	end)
	return true
end
local function git_log(prompt_bufnr)
	require("telescope.builtin").find_files({ attach_mappings = run_selection })
end

lvim.builtin.which_key.mappings["b"] = { "<cmd>Telescope buffers<cr>", "Open Buffers" }
lvim.builtin.which_key.mappings["m"] = { "<cmd>Telescope oldfiles<cr>", "Open Recent File" }
lvim.builtin.which_key.mappings["f"] = {
	name = "Find",
	a = { "<cmd>Telescope builtin<cr>", "All builtins" },
	b = { "<cmd>Telescope buffers<cr>", "Open Buffers" },
	C = { "<cmd>Telescope commands_history<cr>", "Rerun Commands" },
	c = { "<cmd>Telescope commands<cr>", "Run Commands" },
	d = { find_cwd_files, "find same dir" },
	f = { "<cmd>Telescope find_files<cr>", "Find File" },
	g = { require("lvim.core.telescope.custom-finders").find_project_files, "Find same prj" },
	h = { "<cmd>Telescope help_tags<cr>", "Help" },
	k = { "<cmd>Telescope keymaps<cr>", "keymappings" },
	l = { git_log, "Git log" },
	m = { "<cmd>Telescope oldfiles<cr>", "Open Recent File" },
	O = { "<cmd>Telescope vim_options<cr>", "Vim Options" },
	p = { "<cmd>Telescope registers<cr>", "Paste registers" },
	P = { "<cmd>Telescope projects<CR>", "Projects" },
	r = { "<cmd>Telescope live_grep<cr>", "Live Grep" },
	t = { "<cmd>Telescope tags<cr>", "Ctags" },
	T = { "<cmd>SymbolsOutline<cr>", "Symbols" },
	w = { "<cmd>Telescope grep_string<cr>", "Grep Word" },
	-- t = { "<cmd>TagbarToggle<cr>", "Tags" },
}
lvim.builtin.which_key.mappings["Ls"] = { "<cmd>Pmsg lua put(lvim)<cr>", "Show Confs" }
lvim.builtin.which_key.mappings["o"] = { -- toggle options
	p = { "<cmd>setlocal paste!<cr>", "paste" },
	c = {
		"<cmd>lua if vim.o.clipboard == '' then vim.o.clipboard = 'unnamedplus' else vim.o.clipboard = '' end<cr>",
		"clipboard",
	},
}

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.notify.active = true
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

-- generic LSP settings

-- ---@usage disable automatic installation of servers
-- lvim.lsp.automatic_servers_installation = false

-- ---configure a server manually. !!Requires `:LvimCacheReset` to take effect!!
-- ---see the full default list `:lua print(vim.inspect(lvim.lsp.automatic_configuration.skipped_servers))`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pyright", opts)

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

-- -- set a formatter, this will override the language server formatting capabilities (if it exists)
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{ command = "stylua", filetypes = { "lua" } }, -- cargo install stylua
	{ command = "black", filetypes = { "python" } },
	{ command = "isort", filetypes = { "python" } },
})
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

lvim.plugins = {
	--{ "ray-x/lsp_signature.nvim" },
	--{
	--	"vim-airline/vim-airline",
	--	requires = { "vim-airline/vim-airline-themes" },
	--	config = function()
	--		vim.g.airline_theme = "sol"
	--		vim.g["airline#extensions#wordcount#enabled"] = 0
	--		-- vim.g["airline#extensions#whitespace#enabled"] = 0
	--	end,
	--},
	-- {
	-- 	"preservim/tagbar",
	-- 	config = function()
	-- 		vim.g.tagbar_sort = 0 -- by position, press 's' to toggle by name/position
	-- 		vim.g.tarbar_show_data_type = 1
	-- 		vim.g.tagbar_show_linenumbers = 2
	-- 		vim.g.tagbar_expand = 1
	-- 	end,
	-- },
	-- {
	-- 	"github/copilot.vim",
	-- 	config = function()
	-- 		vim.g.copilot_no_tab_map = true
	-- 		vim.g.copilot_assume_mapped = true
	-- 	end,
	-- },
	-- { "hrsh7th/cmp-copilot", requires = "hrsh7th/nvim-cmp", event = "InsertEnter" },
	{ "simrat39/symbols-outline.nvim" },
	{ "andymass/vim-matchup" },
	{ "tpope/vim-fugitive" },
	{
		"RRethy/vim-hexokinase",
		run = "make hexokinase",
		config = function()
			vim.g.Hexokinase_highlighters = { "backgroundfull" }
		end,
	},
	{ "commiyou/molokai" },
	-- { "fmoralesc/molokayo"},
	-- { "f-person/git-blame.nvim" }, -- too slow when big file!
	{ "ConradIrwin/vim-bracketed-paste" },
	{ "folke/trouble.nvim" },
	{ "farmergreg/vim-lastplace" },
	{ "felipec/vim-sanegx" }, -- gx open url
	{ "itchyny/vim-cursorword" },
	{ "elzr/vim-json" },
	{ "wellle/tmux-complete.vim" },
	{ "tpope/vim-repeat" },
	{ "andersevenrud/cmp-tmux", requires = "hrsh7th/nvim-cmp", event = "InsertEnter" },
	{ "hrsh7th/cmp-cmdline", requires = "hrsh7th/nvim-cmp", event = "InsertEnter" },
	{ "tzachar/cmp-tabnine", run = "./install.sh", requires = "hrsh7th/nvim-cmp", event = "InsertEnter" },
	{ "morhetz/gruvbox" },
	{ "szw/vim-maximizer" },
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
		"christoomey/vim-tmux-navigator",
		config = function()
			vim.g.tmux_navigator_disable_when_zoomed = 1
		end,
	},
	{
		"inkarkat/vim-mark",
		requires = { "inkarkat/vim-ingo-library" },
		config = function()
			vim.cmd([[
	   let g:mwHistAdd = '@'
	   let g:mwAutoLoadMarks = 1
	   let g:mw_no_mappings = 1
	   nmap <leader>M <Plug>MarkSet
	   ]])
		end,
	},
	{
		"phaazon/hop.nvim",
		event = "BufRead",
		config = function()
			require("hop").setup()
			vim.api.nvim_set_keymap("n", "s", ":HopChar2<cr>", { silent = true })
			vim.api.nvim_set_keymap("n", "S", ":HopWord<cr>", { silent = true })
		end,
	},
}

local cmp = require("cmp")

cmp.setup.filetype({ "log" }, { enabled = false })

cmp.setup.cmdline(":", {
	sources = {
		{ name = "path" },
		{ name = "cmdline" },
	},
})
cmp.setup.cmdline("/", {
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
vim.o.eol = false -- no auto add <EOL>
vim.o.wrap = true
vim.opt.isfname = vim.opt.isfname - "="
vim.o.mouse = "h"
vim.o.splitbelow = false
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

nnoremap <silent><C-w>z :MaximizerToggle<CR>
vnoremap <silent><C-w>z :MaximizerToggle<CR>gv
"imap <expr> <Plug>(vimrc:copilot-dummy-map) copilot#Accept("\<Tab>")

" jump to the previous function
autocmd FileType c,cpp nnoremap <silent> [f :call
\ search('\(\(if\\|for\\|while\\|switch\\|catch\)\_s*\)\@64<!(\_[^)]*)\_[^;{}()]*\zs{', "bw")<CR>
" jump to the next function
autocmd FileType c,cpp nnoremap <silent> ]f :call
\ search('\(\(if\\|for\\|while\\|switch\\|catch\)\_s*\)\@64<!(\_[^)]*)\_[^;{}()]*\zs{', "w")<CR>

set tags=./tags;,tags;
nnoremap gt :ts <C-R>=expand("<cword>")<CR><CR>

]])
