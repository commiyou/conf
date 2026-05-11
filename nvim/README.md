# Neovim 配置说明

基于 [AstroNvim](https://astronvim.com/) v4，附加 AI 补全、搜索增强、诊断工具等插件。

---

## 目录

- [AI 功能](#ai-功能)
- [补全 (blink.cmp)](#补全-blinkcmp)
- [缓冲区与导航](#缓冲区与导航)
- [搜索与跳转](#搜索与跳转)
- [诊断与 LSP](#诊断与-lsp)
- [代码片段](#代码片段)
- [标记 (Marks)](#标记-marks)
- [Trouble — 结构化诊断列表](#trouble--结构化诊断列表)
- [搜索替换 (grug-far)](#搜索替换-grug-far)
- [TODO 注释](#todo-注释)
- [其他工具](#其他工具)
- [命令行模式](#命令行模式)

---

## AI 功能

### Avante — AI 对话助手 (`<leader>a`)

| 快捷键 | 功能 |
|--------|------|
| `<leader>aa` | 向 AI 提问 |
| `<leader>an` | 新建 AI 对话 |
| `<leader>ae` | 编辑选中内容（visual 模式） |
| `<leader>ar` | 刷新响应 |
| `<leader>af` | 聚焦到侧边栏 |
| `<leader>aS` | 停止生成 |
| `<leader>at` | 开关侧边栏 |
| `<leader>as` | 开关 AI inline suggestion |
| `<leader>aC` | 开关选区模式 |
| `<leader>aR` | 开关 Repo Map |

侧边栏内：`A` 应用所有变更，`a` 应用光标处变更，`]p`/`[p` 翻历史提问。

Provider：OpenAI 接口 → `glm-5.1`（chat），Claude 接口 → `Claude Sonnet 4.6`。

---

### Minuet — Ghost Text 内联补全

打字停顿约 1 秒后自动触发，以虚拟文本（ghost text）显示补全建议。

| 快捷键 | 功能 |
|--------|------|
| `<A-y>` | 接受整条补全 |
| `<A-l>` | 接受一行 |
| `<A-n>` | 下一条候选 |
| `<A-p>` | 上一条候选 |
| `<A-e>` | 取消 |
| `<leader>am` | 开关当前 buffer 自动触发 |

支持的文件类型：`python lua sh bash typescript javascript tsx jsx cpp c go rust`

Provider：`Claude Haiku 4.5`（低延迟，无推理 token）。

---

### WTF — 诊断 AI 解释 (`<leader>D`)

对光标处的 LSP 诊断错误进行 AI 分析，用中文解释和修复。

| 快捷键 | 功能 |
|--------|------|
| `<leader>Dd` | AI 解释诊断 |
| `<leader>Df` | AI 修复诊断 |
| `<leader>Ds` | Google 搜索诊断 |
| `<leader>Dp` | 切换 provider |
| `<leader>Dh` | 历史记录 → quickfix |
| `<leader>Dg` | Telescope 搜索历史 |

---

## 补全 (blink.cmp)

Keymap preset：`super-tab`（Tab 接受，C-n/C-p 选择）。

| 快捷键 | 功能 |
|--------|------|
| `Tab` | 接受补全 / snippet 前进 |
| `C-n` / `C-p` | 选择下/上一条 |
| `C-space` | 手动触发 / 打开文档 |
| `C-e` | 关闭菜单 |
| `C-k` | 切换签名帮助 |

补全 source 优先级（高→低）：`minuet(AI)` → `avante` → `lsp` → `snippets` → `path` → `buffer` → `ripgrep`

文档弹窗：200ms 后自动显示。命令行 `:` 和 `/` 搜索也有补全。

---

## 缓冲区与导航

| 快捷键 | 功能 |
|--------|------|
| `L` / `H` | 下/上一个 buffer |
| `]b` / `[b` | 下/上一个 buffer |
| `<leader>c` | 关闭当前 buffer |
| `<leader>bd` | 从 tabline 选择 buffer 关闭 |
| `<C-g>` | 显示完整文件路径（`1<C-g>`） |

---

## 搜索与跳转

### Flash — 快速跳转

| 快捷键 | 模式 | 功能 |
|--------|------|------|
| `s` | n/x/o | Flash 跳转（输入字符后显示标签） |
| `S` | n/x/o | Flash Treesitter 跳转 |
| `r` | o | Remote Flash（`yr` 跨位置 yank） |
| `R` | o/x | Treesitter 范围搜索 |
| `<C-s>` | c | 在搜索时切换 Flash |

`/` 搜索不默认启用 Flash，`f`/`t` 字符跳转显示标签。

### Snacks — 词语高亮跳转

| 快捷键 | 功能 |
|--------|------|
| `]]` | 跳到下一个光标词出现位置 |
| `[[` | 跳到上一个光标词出现位置 |

光标下的词自动高亮所有出现位置（替代 `*` + `n`）。

---

## 诊断与 LSP

启动时开启 `virtual_text`，关闭 `virtual_lines`，`update_in_insert = false`。

### Trouble — 结构化诊断列表 (`<leader>x`)

| 快捷键 | 功能 |
|--------|------|
| `<leader>xx` | 全项目诊断 |
| `<leader>xd` | 当前 buffer 诊断 |
| `<leader>xs` | 文档 Symbols |
| `<leader>xl` | LSP 定义/引用（右侧分屏） |
| `<leader>xq` | Quickfix 列表 |
| `<leader>xL` | Location 列表 |
| `]q` / `[q` | 下/上一个 Trouble 条目（无 Trouble 时用 cnext/cprev） |

---

## 代码片段

| 快捷键 | 功能 |
|--------|------|
| `<leader>fs` | Telescope 搜索所有 snippet |
| `<leader>se` | Scissors 编辑 snippet |
| `<leader>sa` | Scissors 新建 snippet（visual 模式预填充内容） |

Snippet 目录：`~/.config/nvim/snippets/`（VSCode 格式，`friendly-snippets` + 自定义）。

---

## 标记 (Marks) — `<leader>m`

`vim-mark` 插件，多色高亮标记，独立于内置 mark。

| 快捷键 | 功能 |
|--------|------|
| `<leader>mm` | 标记/取消当前词或选区 |
| `<leader>mr` | 正则标记 |
| `<leader>mc` | 清除所有标记 |
| `<leader>mn` | 下一个标记（任意颜色） |
| `<leader>mp` | 上一个标记（任意颜色） |
| `]m` | 下一个同色标记 |
| `[m` | 上一个同色标记 |

---

## 搜索替换 (grug-far)

项目级搜索替换，实时预览。

| 快捷键 | 功能 |
|--------|------|
| `<leader>fr` | 打开（自动填充当前文件扩展名过滤） |
| `<leader>fR` | 打开并预填充光标词 |
| `<leader>fr`（visual） | 打开并预填充选中内容 |

---

## TODO 注释

高亮 `TODO` `FIXME` `HACK` `NOTE` `BUG` `PERF` 关键词。

| 快捷键 | 功能 |
|--------|------|
| `]t` / `[t` | 跳到下/上一个 TODO |
| `<leader>ft` | Telescope 搜索 TODO |
| `<leader>fT` | Trouble 显示所有 TODO |

---

## 其他工具

### 系统剪贴板

默认关闭（SSH 友好），按需切换：

| 快捷键 | 功能 |
|--------|------|
| `<leader>uc` | 切换系统剪贴板 |

### a.vim — 头/源文件切换

`commiyou/a.vim`，在 `.h` / `.cpp` 等对应文件间切换。用 `:A` 命令（无默认 keymap）。

---

## 命令行模式

| 快捷键 | 功能 |
|--------|------|
| `<C-a>` | 行首 |
| `<M-b>` | 向左一词 |
| `<M-f>` | 向右一词 |
| `<C-f>` | 向右一字符 |
| `<C-b>` | 向左一字符 |

---

## 编码

文件读取顺序：`ucs-bom → utf-8 → gbk → gb2312 → cp936 → latin1`（兼容 GBK 文件）。
