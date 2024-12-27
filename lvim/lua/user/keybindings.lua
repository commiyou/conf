local M = {}
M.config = function()
  -- add your own keymapping
  lvim.keys.normal_mode["H"] = ":BufferLineCyclePrev<cr>"
  lvim.keys.normal_mode["L"] = ":BufferLineCycleNext<cr>"
  lvim.keys.normal_mode["<C-s>"] = ":w<cr>"
  lvim.keys.normal_mode["<C-b>"] = "<left>"
  lvim.keys.normal_mode["<C-f>"] = "<right>"

  lvim.keys.normal_mode["<c-g>"] = "1<c-g>"
  lvim.keys.normal_mode["0"] = "^"

  if vim.fn.has "mac" == 1 then
    lvim.keys.normal_mode["gx"] =
    [[<cmd>lua os.execute("open " .. vim.fn.shellescape(vim.fn.expand "<cWORD>")); vim.cmd "redraw!"<cr>]]
  elseif vim.fn.has "linux" then
    lvim.keys.normal_mode["gx"] =
    [[<cmd>lua os.execute("xdg-open " .. vim.fn.shellescape(vim.fn.expand "<cWORD>")); vim.cmd "redraw!"<cr>]]
  end

  lvim.keys.normal_mode["Y"] = "y$"
  lvim.keys.normal_mode["gV"] =
  "<cmd>vsplit | lua vim.lsp.buf.definition({on_list = function(items) vim.fn.setqflist({}, 'r', items) vim.cmd('cfirst') end})<cr>"



  -- :h cmdline-editing,  <c-f>
  vim.cmd([[
nnoremap <expr> n  'Nn'[v:searchforward]
nnoremap <expr> N  'nN'[v:searchforward]
]])
  lvim.keys.command_mode["w!!"] = "execute 'silent! write !sudo tee % >/dev/null' <bar> edit!"

  -- binding for switching
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
  lvim.builtin.which_key.mappings["t"] = { "<cmd>Outline<CR>", "Toggle outline" }
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
    -- https://github.com/ibhagwan/fzf-lua/issues/441
    s = { "<cmd>lua require('fzf-lua').lsp_document_symbols({  regex_filter = 'F.*' })<cr>", "Buffer Symbol" },
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
  -- lvim.builtin.luasnip.loaders.from_vscode.lazy_load {
  --   paths = { "$XDG_CONFIG_HOME/lvim/snips/" },
  -- }
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
  --

  -- copy from https://github.com/yetone/avante.nvim/wiki/Recipe-and-Tricks
  local prefill_edit_window = function(request)
    require('avante.api').edit()
    local code_bufnr = vim.api.nvim_get_current_buf()
    local code_winid = vim.api.nvim_get_current_win()
    if code_bufnr == nil or code_winid == nil then
      return
    end
    vim.api.nvim_buf_set_lines(code_bufnr, 0, -1, false, { request })
    -- Optionally set the cursor position to the end of the input
    vim.api.nvim_win_set_cursor(code_winid, { 1, #request + 1 })
    -- Simulate Ctrl+S keypress to submit
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-s>', true, true, true), 'v', true)
  end
  local avante_code_readability_analysis = [[
You must identify any readability issues in the code snippet.
Some readability issues to consider:
- Unclear naming
- Unclear purpose
- Redundant or obvious comments
- Lack of comments
- Long or complex one liners
- Too much nesting
- Long variable names
- Inconsistent naming and code style.
- Code repetition
You may identify additional problems. The user submits a small section of code from a larger file.
Only list lines with readability issues, in the format <line_num>|<issue and proposed solution>
If there's no issues with code respond with only: <OK>
]]
  local avante_optimize_code = 'Optimize the following code'
  local avante_explain_code = 'Explain the following code'
  local avante_complete_code = 'Complete the following codes written in ' .. vim.bo.filetype
  local avante_add_docstring = 'Add docstring to the following codes'
  local avante_fix_bugs = 'Fix the bugs inside the following codes if any'
  local avante_add_tests = 'Implement tests for the following code'
  lvim.builtin.which_key.mappings["a"] = {
    name = "Avante", -- Group name
    l = { function() require('avante.api').ask { question = avante_code_readability_analysis } end, "Code Readability Analysis(ask)" },
    o = { function() require('avante.api').ask { question = avante_optimize_code } end, "Optimize Code(ask)" },
    x = { function() require('avante.api').ask { question = avante_explain_code } end, "Explain Code(ask)" },
    c = { function() require('avante.api').ask { question = avante_complete_code } end, "Complete Code(ask)" },
    d = { function() require('avante.api').ask { question = avante_add_docstring } end, "Docstring(ask)" },
    b = { function() require('avante.api').ask { question = avante_fix_bugs } end, "Fix Bugs(ask)" },
    u = { function() require('avante.api').ask { question = avante_add_tests } end, "Add Tests(ask)" },
  }
  lvim.builtin.which_key.vmappings["a"] = {
    name = "Avante", -- Group name
    O = { function() prefill_edit_window(avante_optimize_code) end, "Optimize Code(edit)" },
    C = { function() prefill_edit_window(avante_complete_code) end, "Complete Code(edit)" },
    D = { function() prefill_edit_window(avante_add_docstring) end, "Docstring(edit)" },
    B = { function() prefill_edit_window(avante_fix_bugs) end, "Fix Bugs(edit)" },
    U = { function() prefill_edit_window(avante_add_tests) end, "Add Tests(edit)" },
  }
  lvim.builtin.which_key.mappings["lp"] = {
    name = "Peek",
    d = { "<cmd>lua require('user.peek').Peek('definition')<cr>", "Definition" },
    t = { "<cmd>lua require('user.peek').Peek('typeDefinition')<cr>", "Type Definition" },
    i = { "<cmd>lua require('user.peek').Peek('implementation')<cr>", "Implementation" },
  }
  lvim.builtin.which_key.mappings["lh"] = {
    "<cmd>hi LspReferenceRead cterm=bold ctermbg=red guibg=#24283b<cr><cmd>hi LspReferenceText cterm=bold ctermbg=red guibg=#24283b<cr><cmd>hi LspReferenceWrite cterm=bold ctermbg=red guibg=#24283b<cr>",
    "Clear HL",
  }
   -- Navigate merge conflict markers
  local whk_status, whk = pcall(require, "which-key")
  if not whk_status then
    return
  end
  whk.register {
    ["]n"] = { "[[:call search('^(@@ .* @@|[<=>|]{7}[<=>|]@!)', 'W')<cr>]]", "next merge conflict" },
    ["[n"] = { "[[:call search('^(@@ .* @@|[<=>|]{7}[<=>|]@!)', 'bW')<cr>]]", "prev merge conflict" },
  }
end

return M
