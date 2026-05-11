# Tmux 配置说明

---

## 基本设置

| 项目 | 值 |
|------|----|
| **Prefix 键** | `M-;`（Alt+;） |
| **鼠标** | 关闭 |
| **窗口编号** | 从 1 开始 |
| **历史行数** | 10000 |
| **状态栏** | 本地在顶部，SSH 连接时在底部 |
| **默认 shell** | zsh |
| **剪贴板** | OSC 52 透传，支持远端复制 |

---

## 前缀键说明

所有需要 prefix 的命令先按 `M-;`（Alt+;），再按后续键。  
下表中 `<prefix>` 表示此组合。

---

## Session / Window / Pane

### Session

| 快捷键 | 功能 |
|--------|------|
| `<prefix> C` | 在当前路径新建 session |
| `<prefix> d` | detach 当前 session |
| `<prefix> D` | detach 其他所有 session |
| `M-s`（无 prefix） | 交互选择 session / window 树 |

### Window

| 快捷键 | 功能 |
|--------|------|
| `C-0` ~ `C-9` | 直接跳到对应编号的 window（无需 prefix） |
| `<prefix> M-;` | 切换到上一个活跃 window |
| `<prefix> a` | 同上（last-window） |
| `<prefix> C-[` | 上一个 window |
| `<prefix> C-]` | 下一个 window |
| `<prefix> e` | 用 `$EDITOR` 编辑 tmux.conf，保存后自动 reload |
| `<prefix> r` | reload tmux.conf |
| `<prefix> C-s` | 显示/隐藏状态栏 |

### Pane 分割

| 快捷键 | 功能 |
|--------|------|
| `M--`（无 prefix） | 水平分割（上下），继承当前路径 |
| `M-\`（无 prefix） | 垂直分割（左右），继承当前路径 |
| `<prefix> -` | 水平分割，打开 bash |
| `<prefix> \` 或 `\|` | 垂直分割，打开 bash |
| `<prefix> q` | 关闭当前 pane |

### Pane 导航

| 快捷键 | 功能 |
|--------|------|
| `<prefix> [` | 选择上一个 pane |
| `<prefix> ]` | 选择下一个 pane |
| `<prefix> >` | 与下一个 pane 交换位置 |
| `<prefix> <` | 与上一个 pane 交换位置 |
| `<prefix> \` | 将当前 pane 与第 1 个 pane 互换 |
| `<prefix> C-o` | 轮换 pane（swap -D） |

### Pane 大小调整（可连续按）

| 快捷键 | 功能 |
|--------|------|
| `<prefix> H` | 向左扩展 2 格 |
| `<prefix> J` | 向下扩展 2 格 |
| `<prefix> K` | 向上扩展 2 格 |
| `<prefix> L` | 向右扩展 2 格 |

### Layout

| 快捷键 | 功能 |
|--------|------|
| `M-=`（无 prefix） | 均匀分布（垂直） |
| `<prefix> M-=` | 均匀分布（水平） |
| `M-z`（无 prefix） | 最大化/还原当前 pane（zoom） |
| `<prefix> M-z` | 切换为 main-horizontal 布局 |

---

## Copy 模式

| 快捷键 | 功能 |
|--------|------|
| `<prefix> Enter` | 进入 copy 模式 |
| `v` | 开始选择（vi 风格） |
| `C-v` | 矩形选择 |
| `y` | 复制并退出 |
| `H` / `L` | 行首 / 行尾 |
| `Escape` | 取消 |

---

## Paste Buffer

| 快捷键 | 功能 |
|--------|------|
| `<prefix> b` | 列出所有 paste buffer |
| `<prefix> p` | 粘贴最新 buffer |
| `<prefix> C-p` | 交互选择 buffer 粘贴 |

---

## 嵌套会话（本地+远端）

SSH 到远端时，本地和远端都运行 tmux，可用 F4 切换前缀键的归属：

| 按键 | 效果 |
|------|------|
| `F4` | 挂起本地 prefix，按键直接发给远端 tmux |
| `F4`（再次） | 恢复本地 prefix |

状态栏右侧显示 `OFF` 表示本地 prefix 已挂起。

---

## vim-tmux-navigator

与 Neovim 集成，在 pane 和 nvim split 之间无缝跳转：

| 快捷键 | 功能 |
|--------|------|
| `C-h` | 向左跳（pane 或 nvim window） |
| `C-j` | 向下跳 |
| `C-k` | 向上跳 |
| `C-l` | 向右跳 |

---

## 状态栏说明

```
 ❐ session名  [prefix高亮]          窗口列表          Google: Ok  2026-05-11 14:30
```

- 左侧：黄底黑字显示当前 session 名，激活 prefix 时粉色高亮
- 右侧：网络状态（Google 可达性）+ 当前时间
- 当前 window：蓝色背景加粗
- 上一个 window：蓝色字体

---

## 插件

| 插件 | 功能 |
|------|------|
| `tmux-plugins/tpm` | 插件管理器 |
| `christoomey/vim-tmux-navigator` | Neovim ↔ tmux pane 无缝跳转 |
| `tmux-plugins/tmux-prefix-highlight` | 状态栏显示 prefix 激活状态 |
| `tmux-plugins/tmux-online-status` | 状态栏网络状态 |

更新插件：`<prefix> U`（tpm 内置）
