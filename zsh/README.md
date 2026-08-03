# Zsh 配置说明

插件管理器：[zinit](https://github.com/zdharma-continuum/zinit)，主题：Powerlevel10k，Vi 模式：zsh-vi-mode。

---

## 目录

- [插件列表](#插件列表)
- [自动安装的二进制工具](#自动安装的二进制工具)
- [快捷键](#快捷键)
- [全局 alias（管道用）](#全局-alias管道用)
- [常用 alias](#常用-alias)
- [Git alias](#git-alias)
- [Named Directory](#named-directory)
- [补全行为](#补全行为)

---

## 插件列表

| 插件 | 功能 |
|------|------|
| `romkatv/powerlevel10k` | 提示符主题，即时渲染 |
| `jeffreytse/zsh-vi-mode` | 完整 Vi 模式，INSERT 模式启动 |
| `Aloxaf/fzf-tab` | Tab 补全用 fzf 弹窗展示 |
| `zsh-users/zsh-autosuggestions` | 历史命令灰色提示 |
| `zdharma-continuum/fast-syntax-highlighting` | 命令语法高亮 |
| `zsh-users/zsh-completions` | 扩展补全规则 |
| `ajeetdsouza/zoxide` | 智能 `cd`（`z` 命令） |
| `wfxr/forgit` | fzf 增强 git 操作（`glog` `gdca` 等） |
| `junegunn/fzf` | 模糊搜索核心 |
| `popstas/zsh-command-time` | 慢命令自动显示耗时（vim 除外） |
| `z-shell/zsh-diff-so-fancy` | git diff 美化 |
| `Tarrasch/zsh-autoenv` | 进入目录自动执行 `.env` 文件 |
| `OMZP::extract` / `x` | 万能解压命令 |
| `OMZP::thefuck` / `fuck` | 自动修正上一条错误命令（需另行安装 `thefuck`） |
| `OMZP::fancy-ctrl-z` | `Ctrl-Z` 在前台/后台间切换 |
| `OMZP::colored-man-pages` | man 页着色 |
| `reegnz/jq-zsh-plugin` | jq 补全 |
| `Freed-Wu/fzf-tab-source` | fzf-tab 预览增强（文件/进程等） |

---

## 自动安装的二进制工具

工具采用明确的混合归属：`make tools` 只安装系统和基础工具；下表中的用户态 CLI 在系统中不存在时由 zinit 从 GitHub Release 安装。两边不重复安装同一命令。

| 命令 | 说明 |
|------|------|
| `eza` | 现代 ls |
| `fd` | 现代 find |
| `bat` | 现代 cat（语法高亮） |
| `rg` | ripgrep 全文搜索 |
| `fzf` | 模糊搜索 |
| `delta` | Git diff 分页与语法高亮 |
| `lazygit` | Git 终端界面 |
| `yq` | YAML 查询与转换 |
| `gron` | JSON 转 greppable 格式 |
| `jless` | JSON 分页浏览 |
| `fx` | JSON 交互浏览 |
| `xsv` | CSV 命令行工具 |
| `sad` | 批量 sed 替换（带 diff 预览） |
| `mdcat` | 终端渲染 Markdown |
| `navi` | 命令速查手册（交互） |
| `cheat` | 速查 cheatsheet |
| `git-extras` | `git-summary` `git-undo` 等扩展命令 |

更新所有插件：`zupdate`

---

## 快捷键

### 行内编辑（INSERT 模式）

| 快捷键 | 功能 |
|--------|------|
| `^f` / `^b` | 前/后移一字符 |
| `^a` / `^e` | 行首 / 行尾 |
| `^[b` / `^[f` | 前/后移一词（Alt-b/f） |
| `^p` / `^n` | 上/下条历史 |
| `↑` / `↓` | 前缀匹配历史搜索 |
| `^y` | 粘贴（yank） |
| `^u` | 删除至行首（vi-kill-line） |
| `^w` | 删除前一个词 |
| `^t` | 交换前两字符 |
| `^[T` | 交换前两词 |
| `^_` | 撤销 |
| `^o` | 执行并拉取下一条历史 |
| `^[a` | 执行当前行并保留在 buffer（accept-and-hold） |
| `^Q` | 暂存当前行（push-line） |
| `^[m` | 复制上一命令的最后一词 |
| `^[.` | 插入上一命令的最后参数（NORMAL 模式） |
| `.` | 输入 `..` 时自动展开为 `../..` |

### 扩展功能键

| 快捷键 | 功能 |
|--------|------|
| `^x^e` | 在 `$EDITOR` 中编辑当前命令行 |
| `^xs` | 在命令前加 `sudo` |
| `^x^a` | 插入当天日期（`YYYYMMDD`） |
| `^x^l` | 执行 `ls -lrt .` |
| `^x^x` | 用 fzf 选择文件并用 `fno` 打开 |
| `^x^n` | 搜索历史中与当前行匹配的下一条 |
| `^[?` | 显示命令说明（which-command） |
| `^[o` | 在命令前加 `nohup`、末尾加 `&` 后台执行 |
| `^[T` (fzf) | 文件搜索插入（fzf 重映射） |
| `^[C` (fzf) | 目录跳转（fzf 重映射） |

### Vi NORMAL 模式补充

| 快捷键 | 功能 |
|--------|------|
| `^[.` | 插入上一命令最后参数 |
| `^[m` | 复制更早的词 |

---

## 全局 alias（管道用）

在命令的任意位置使用，如 `cat file G pattern`。

| alias | 展开 |
|-------|------|
| `L` | `\| less`（UTF-8） |
| `LC` | `\| less -R`（保留颜色） |
| `G` | `\| grep -i --color -a` |
| `EG` | `\| egrep -i --color -a` |
| `H` | `\| head` |
| `T` | `\| tail` |
| `F` | `\| fzf --tmux` |
| `P` | `\| fx`（JSON 交互查看） |
| `NE` | `2>/dev/null` |
| `NUL` | `>/dev/null 2>&1` |
| `GBK` | `\| iconv -f utf8 -t gb18030` |
| `UTF` | `\| iconv -f gb18030 -t utf8` |
| `LU` | 转 GBK 后 less |
| `LG` | 转 UTF-8 后 less |
| `TR1` | `\| tr '' '\t'`（SOH→tab） |
| `TR,` | `\| tr ',' '\t'` |
| `CSV` | `\| tr '\t' ','` |
| `NF` | glob：当前目录最新文件 |
| `ND` | glob：当前目录最新目录 |

---

## 常用 alias

### 文件操作

| alias | 说明 |
|-------|------|
| `l` | `ls -lhF` |
| `ll` | `ls -lF` |
| `la` | `ls -lhFa` |
| `lrt` | `ls -lrth`（按时间倒序） |
| `lrs` | `ls -lrSh`（按大小倒序） |
| `lss` | `ls` 过滤掉 tsv/xlsx/jsonl/json |
| `md` | `mkdir -p` |
| `mdc DIR` | `mkdir -p DIR && cd DIR` |
| `rm` | `rm -i` |
| `rmr` | `rm -rf` |
| `cp` | `cp -i` |
| `mv` | `mv -i` |
| `ln` | `ln -si` |
| `lnf` | `ln -sf` |

### 搜索

| alias | 说明 |
|-------|------|
| `fdf PATTERN` | `find . -type f -name PATTERN` |
| `fdd PATTERN` | `find . -type d -name PATTERN` |
| `rgcpp` | `rg -t cpp -t protobuf -t c` |
| `rgpy` | `rg -t py` |
| `rgsh` | `rg -t sh` |
| `rgall` | `rg --no-ignore`（包含 gitignore 文件） |
| `fd` | `fd -I`（不忽略隐藏文件） |

### 文本处理

| alias | 说明 |
|-------|------|
| `awkt` | `awk -F'\t' -v OFS='\t'` |
| `cutt` | `cut -d$'\t'` |
| `sortt` | `sort -t$'\t'` |
| `sort` | `LC_ALL=C sort` |
| `grep` | `LC_ALL=C grep --color -a` |
| `wcl` | `wc -l` |
| `dud` | `du -m -h -s -c -- * \| sort -h` |

### 其他

| alias | 展开 |
|-------|------|
| `z` | zoxide 智能跳转（`z foo` 跳到含 foo 的历史目录） |
| `t` | `tail -f` |
| `r` | 重复/替换上一条命令（`fc -e -`，支持 `r old=new`） |
| `vn` | vim 打开当前目录最新文件 |
| `..` / `...` / `....` | 逐级向上 cd |
| `rpath PATH` | 显示相对路径（`realpath --relative-to=.`） |
| `recently_changed` | 15 分钟内修改的文件 |
| `gdmsg` | 用 sgpt 生成符合 Conventional Commits 的 commit message |

---

## Git alias

| alias | 命令 |
|-------|------|
| `ga` | `git add` |
| `gau` | `git add --update` |
| `gb` / `gba` | `git branch` / `git branch -a` |
| `gc` | `git commit -v` |
| `gc!` | `git commit --amend` |
| `gcn!` | `git commit --amend --no-edit` |
| `gcmsg` | `git commit -m` |
| `gcb` | `git checkout -b` |
| `gco` | `git checkout` |
| `gcl` | `git clone --recurse-submodules` |
| `gclm REPO` | clone 自己 GitHub 的仓库并 cd 进去 |
| `gd` | `git diff` |
| `gds` | `git diff --staged --ignore-all-space` |
| `gdf` | `git diff -U999999`（完整上下文） |
| `gr` / `grs` | `git restore` / `git restore --staged` |
| `gl` | `git pull` |
| `gup` | `git pull --rebase` |
| `gupa` | `git pull --rebase --autostash` |
| `gp` | `git push` |
| `gpcr` | `git push origin HEAD:当前分支` |
| `glog` | forgit 交互式 log（`--oneline --graph`） |
| `gdca` / `gds` | forgit 交互式 diff（staged） |
| `gsb` | `git status -sb` |
| `gst` | `git status` |
| `gstt` | `git status -uno`（只看已追踪文件） |
| `grb` / `grba` / `grbc` | rebase / abort / continue |
| `grhh` | `git reset --hard` |
| `grt` | cd 到 git 根目录 |
| `gcp` / `gcpa` / `gcpc` | cherry-pick / abort / continue |
| `gsh` | `git show` |
| `gconfig EMAIL` | 交互式配置 git user.name/email，同时设常用 alias |

---

## Named Directory

`~conf` `~zsh` `~tmux` `~vim` `~rc` 等可直接在 cd/路径中使用：

```
cd ~zsh        # ~/.config/zsh
cd ~conf       # ~/.config
cd ~cheat      # cheatsheets 目录
```

---

## 补全行为

- Tab 补全通过 **fzf-tab** 展示为弹窗（tmux popup）
- 文件补全按**修改时间**排序
- `vim`/`vi` 补全优先显示代码文件，忽略 `.o` `.pyc`
- `rm`/`cp`/`mv` 等命令忽略已在命令行中的参数（避免重复）
- 历史大小：290000 条，按用户名分文件保存
