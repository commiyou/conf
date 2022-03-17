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
lvim.colorscheme = "gruvbox"

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
lvim.keys.normal_mode["<C-b>"] = "<left>"
lvim.keys.normal_mode["<C-f>"] = "<right>"
lvim.keys.command_mode["<C-a>"] = "<Home>"
lvim.keys.command_mode["<C-b>"] = "<Left>"
lvim.keys.command_mode["<C-f>"] = "<Right>"
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
-- lvim.keys.normal_mode["<C-Up>"] = false
-- edit a default keymapping
-- lvim.keys.normal_mode["<C-q>"] = ":q<cr>"

-- Change Telescope navigation to use j and k for navigation and n and p for history in both input and normal mode.
-- we use protected-mode (pcall) just in case the plugin wasn't loaded yet.
local _, actions = pcall(require, "telescope.actions")
lvim.builtin.telescope.defaults.mappings = {
	-- for input mode
	i = {
		["<C-j>"] = actions.move_selection_next,
		["<C-k>"] = actions.move_selection_previous,
		["<C-n>"] = actions.cycle_history_next,
		["<C-p>"] = actions.cycle_history_prev,
		-- ["<esc>"] = actions.close,
	},
	-- for normal mode
	--n = {
	--["<C-j>"] = actions.move_selection_next,
	--["<C-k>"] = actions.move_selection_previous,
	--},
}

-- Use which-key to add extra bindings with the leader-key prefix
-- lvim.builtin.which_key.mappings["t"] = {
-- 	name = "+Trouble",
-- 	r = { "<cmd>Trouble lsp_references<cr>", "References" },
-- 	f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
-- 	d = { "<cmd>Trouble document_diagnostics<cr>", "Diagnostics" },
-- 	q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
-- 	l = { "<cmd>Trouble loclist<cr>", "LocationList" },
-- 	w = { "<cmd>Trouble workspace_diagnostics<cr>", "Diagnostics" },
-- }
lvim.builtin.which_key.mappings["m"] = { "<cmd>Telescope oldfiles<cr>", "Open Recent File" }
lvim.builtin.which_key.mappings["b"] = { "<cmd>Telescope buffers<cr>", "Open Buffers" }
lvim.builtin.which_key.mappings["f"] = {
	name = "Find",
	a = { "<cmd>Telescope builtin<cr>", "All builtins" },
	f = { require("lvim.core.telescope.custom-finders").find_project_files, "Find File" },
	m = { "<cmd>Telescope oldfiles<cr>", "Open Recent File" },
	b = { "<cmd>Telescope buffers<cr>", "Open Buffers" },
	r = { "<cmd>Telescope live_grep<cr>", "Live Grep" },
	g = { "<cmd>Telescope grep_string<cr>", "Grep Word" },
	c = { "<cmd>Telescope commands<cr>", "Run Commands" },
	C = { "<cmd>Telescope commands_history<cr>", "Rerun Commands" },
	O = { "<cmd>Telescope vim_options<cr>", "Vim Options" },
	p = { "<cmd>Telescope registers<cr>", "Paste registers" },
	P = { "<cmd>Telescope projects<CR>", "Projects" },
	k = { "<cmd>Telescope keymaps<cr>", "keymappings" },
	T = { "<cmd>Telescope treesitter<cr>", "treesitter (tags)" },
	t = { "<cmd>SymbolsOutline<cr>", "Tags" },
}

-- TODO: User Config for predefined plugins
-- After changing plugin config exit and reopen LunarVim, Run :PackerInstall :PackerCompile
lvim.builtin.dashboard.active = true
lvim.builtin.notify.active = true
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.show_icons.git = 0

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

lvim.builtin.lualine.options.theme = "gruvbox"

-- generic LSP settings

-- ---@usage disable automatic installation of servers
-- lvim.lsp.automatic_servers_installation = false

-- ---@usage Select which servers should be configured manually. Requires `:LvimCacheRest` to take effect.
-- See the full default list `:lua print(vim.inspect(lvim.lsp.override))`
-- vim.list_extend(lvim.lsp.override, { "pyright" })

-- ---@usage setup a server -- see: https://www.lunarvim.org/languages/#overriding-the-default-configuration
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pylsp", opts)

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

-- Additional Plugins
-- lvim.plugins = {
--     {"folke/tokyonight.nvim"},
--     {
--       "folke/trouble.nvim",
--       cmd = "TroubleToggle",
--     },
-- }

lvim.plugins = {
	--{ "ray-x/lsp_signature.nvim" },
	{ "simrat39/symbols-outline.nvim" },
	{ "andymass/vim-matchup" },
	{ "f-person/git-blame.nvim" },
	{ "github/copilot.vim" },
	{ "morhetz/gruvbox" },
	{ "ConradIrwin/vim-bracketed-paste" },
	{ "folke/trouble.nvim" },
	{ "farmergreg/vim-lastplace" },
	{ "felipec/vim-sanegx" }, -- gx open url
	{ "itchyny/vim-cursorword" },
	{ "elzr/vim-json" },
	-- { "wellle/tmux-complete.vim" },
	{ "tpope/vim-repeat" },
	{
		"enricobacis/a.vim",
		config = function()
			vim.cmd("let g:alternateNoDefaultAlternate = 1")
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
	{
		"AckslD/nvim-neoclip.lua",
		requires = {
			{ "tami5/sqlite.lua", module = "sqlite" },
		},
		config = function()
			require("neoclip").setup()
		end,
	},
	{ "andersevenrud/cmp-tmux" },
	{ "tzachar/cmp-tabnine", run = "./install.sh", requires = "hrsh7th/nvim-cmp", event = "InsertEnter" },
}
require("telescope").load_extension("neoclip")
-- Autocommands (https://neovim.io/doc/user/autocmd.html)
-- lvim.autocommands.custom_groups = {
--   { "BufWinEnter", "*.lua", "setlm.opt.relativenumber = true -- lua print(vim.o.rnu)
vim.o.rnu = true
vim.opt.gdefault = true -- the :substitute flag 'g' is default on
vim.opt.eol = false -- no auto add <EOL>
vim.opt.wrap = true
vim.opt.isfname = vim.opt.isfname - "="
vim.opt.mouse = "h"
vim.o.splitbelow = false

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
function! TabMessage(cmd)
  redir => message
  silent execute a:cmd
  redir END
  if empty(message)
    echoerr "no output"
  else
    " use "new" instead of "tabnew" below if you prefer split windows instead of tabs
    tabnew
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nomodified
    silent put=message
  endif
endfunction
command! -nargs=+ -complete=command TabMessage call TabMessage(<q-args>)

]])
