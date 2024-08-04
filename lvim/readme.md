<leader>+,/. |  swap sibling left/right | Wansmer/sibling-swap.nvim
cx{motion}/cxc | select and then swap | tommcdo/vim-exchange
:UndotreeToggle | undo tree | 
| | tpope/vim-unimpaired
av/iv | a variable (snake case/ camel case)|  Julian/vim-textobj-variable-segment
:Spectre | search and replace | nvim-pack/nvim-spectre
text obj: b(brace), q(quote), ?(manual input char), t(tag), a(argument), f (funtion signature), digits/punctuation/whitespace | |echasnovski/mini.ai
:DiffConflicts | |  whiteinge/diffconflicts
 gS / gJ  | split or join | AndrewRadev/splitjoin.vim
 ["x]gr{motion}/grr| replace with register  | vim-scripts/ReplaceWithRegister
w/e/b| spider motion | chrisgrieser/nvim-spider
m{alpha} | buffer markers | chentoast/marks.nvim
m{digits} | global marker | chentoast/marks.nvim
m; | toggle buffer marker | 
:MarksListBuf/ :MarksListAll | |
:IncRename | inc rename |smjonas/inc-rename.nvim
<leader>lr/R | inc rename|
gR|gD | glance lsp ref/def |dnlhc/glance.nvim
<leader>* | search cw and show in qf | kevinhwang91/nvim-bqf
<leader>gs | search and show in qf | kevinhwang91/nvim-bqf
<leader>KB  | for current line, :Cheat + question |
<M-h/j/k/l> | move line | echasnovski/mini.move
:[range]Sort[!] [delimiter][b][i][n][o][u][x] | sort | sQVe/sort.nvim
:DiffviewOpen HEAD~4..HEAD~2 | | sindrets/diffview.nvim
:MCstart | multi cursor selection | smoka7/multicursors.nvim
:Subvert/child{,ren}/adult{,s}/g  | Child to Adult |tpope/vim-abolish
crs/crm/crc/cru/cr-/cr.| coerce to snake_case, MixedCase,camelCase,UPPER_CASE,dash-case,dot.case |tpope/vim-abolish
ys{motion}{char} | | kylechui/nvim-surround
visual S{char} | visual surrond | kylechui/nvim-surround
ds{char} | |kylechui/nvim-surround
cs{fromchar}{tochar}|| kylechui/nvim-surround
yss{char}| add on line level |
ySS{char} | add tag on new line  on line level|


## register
https://www.brianstorti.com/vim-registers/
`ctrl-r <reg>` | reg content in insert/command
`:reg ` | show reg content
`""` | delete or yank
`"0 - 9` | number register, yank content from new to old
`".`  |  last inserted text
`"%` | current file path, starting from the directory where vim was first opened.
`":` | most recently executed command.
`"=` | expresion restult, `ctrl-r = system('ls')`
`:/` | last searched text
`:let @W='i;'` | upcased `W`, append 'i;' to macro register `w`
`:let @w='<Ctrl-r w>` | show and then edit register w
`"+` | clipboard regsiter and macro
`ivim is awesome` | copy and then `<ctrl-w>+` or '@+'

## usefual
`verbose map <C-L>`

