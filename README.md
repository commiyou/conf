# conf

Personal dotfiles — lives at `~/conf` (doubles as `XDG_CONFIG_HOME`).

## Design

The repo is the config directory.  Setting `XDG_CONFIG_HOME=~/conf` means tools
that respect XDG (neovim, zsh, etc.) find their configs automatically with no
symlinks needed.  Only a handful of tools that hard-code `~/.foo` paths require
a one-time symlink.

```
~/conf/
├── nvim/           → picked up by neovim via XDG_CONFIG_HOME
├── zsh/            → ZDOTDIR set in ~/.zshenv
├── tmux/.tmux.conf → symlinked to ~/.tmux.conf
├── git/config      → symlinked to ~/.gitconfig
├── bin/            → added to PATH via profile
├── profile         → sets XDG vars, PATH, ZDOTDIR
└── Makefile        → bootstrap targets
```

## Quick start

```sh
git clone https://github.com/youbin/conf ~/conf
cd ~/conf
make install          # wire everything up
exec zsh              # reload shell
```

## Make targets

| Target | What it does |
|---|---|
| `make install` | Full bootstrap: zsh + nvim + tmux + git + bin |
| `make zsh` | Append `ZDOTDIR` and `profile` source to `~/.zshenv` |
| `make nvim` | Symlink `~/.config/nvim` if `XDG_CONFIG_HOME` isn't already `~/conf` |
| `make tmux` | Symlink `~/.tmux.conf → ~/conf/tmux/.tmux.conf` |
| `make git` | Symlink `~/.gitconfig → ~/conf/git/config` |
| `make bin` | Mark all scripts in `bin/` executable |
| `make tools` | Install CLI tools (auto-detect macOS/Linux) |
| `make tools-mac` | Install tools via Homebrew |
| `make tools-linux` | Install tools via apt + direct downloads |
| `make update` | `git pull` + `Lazy! sync` + `zinit update --all` |
| `make check` | Show which links/tools are present or missing |

## Components

### ZSH (`zsh/`)

- **Plugin manager**: [zinit](https://github.com/zdharma-continuum/zinit)
- **Prompt**: [powerlevel10k](https://github.com/romkatv/powerlevel10k)
- **Vi mode**: [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode)
- **Completions**: fzf-tab, fast-syntax-highlighting, zsh-autosuggestions
- **Key files**: `zsh/zshrc.d/zinit.zsh`, `zsh/zshrc.d/aliases.zsh`

### Neovim (`nvim/`)

Built on [AstroNvim v4](https://astronvim.com/) with custom plugins:

| Plugin | Purpose |
|---|---|
| `minuet.lua` | Inline AI ghost-text completion (Claude Haiku via oneapi) |
| `avante.lua` | AI chat panel (Claude Sonnet) |
| `blink-cmp.lua` | Fast completion engine with cmdline support |
| `grug-far.lua` | Project-wide search & replace (`<leader>fr/fR`) |
| `todo-comments.lua` | Highlight + jump TODO/FIXME/NOTE (`]t/[t`, `<leader>ft`) |
| `trouble.lua` | Structured diagnostics & LSP lists (`<leader>xx`) |
| `snacks.lua` | Word highlight + `]]`/`[[` navigation |
| `telescope-luasnip.lua` | Browse snippets (`<leader>fs`) |
| `vim-mark.lua` | Multi-colour marks (`<leader>mm/mr/mc`) |
| `wtf.lua` | AI explain diagnostic (`<leader>Dw`) |

### Tmux (`tmux/`)

Static config at `tmux/.tmux.conf`.

### Git (`git/`)

Shared aliases and colour config at `git/config`.  Machine-local identity
(`user.name`, `user.email`) goes in `~/.gitconfig.local` which is included at
the bottom of `git/config`.

### Bin (`bin/`)

Personal scripts on `PATH`.  All made executable by `make bin`.

## Cross-platform notes

| Tool | macOS | Linux |
|---|---|---|
| Package manager | Homebrew | apt / direct download |
| `ls` replacement | eza | eza |
| `cat` replacement | bat | bat |
| `find` replacement | fd | fd (or fdfind) |
| `grep` replacement | ripgrep | ripgrep |
| Nerd Font | Install manually or via `brew install --cask font-*` | Copy `.ttf` to `~/.local/share/fonts/` |

## Termux (Android)

See `rc.d/termux.setup.sh` for the mobile bootstrap.
