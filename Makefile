.ONESHELL:
.DEFAULT_GOAL := help

UNAME := $(shell uname -s)
CONF   := $(shell pwd)
HOME   ?= $(shell echo $$HOME)

BASE_COMMANDS  := zsh nvim tmux git jq curl wget tree htop
ZINIT_COMMANDS := eza fd bat rg fzf delta lazygit yq gron jless fx xsv sad mdcat navi cheat zoxide

# ── colours ──────────────────────────────────────────────────────────────────
GREEN  := \033[0;32m
YELLOW := \033[0;33m
CYAN   := \033[0;36m
RESET  := \033[0m

ok  = printf "  $(GREEN)✓$(RESET)  %s\n"
inf = printf "  $(CYAN)→$(RESET)  %s\n"
wrn = printf "  $(YELLOW)!$(RESET)  %s\n"

# ── help ─────────────────────────────────────────────────────────────────────
.PHONY: help
help:
	@printf "\n$(CYAN)conf dotfiles$(RESET) — $(HOME)/conf\n\n"
	@printf "  $(GREEN)make install$(RESET)        full bootstrap (zsh + nvim + tmux + git + bin)\n"
	@printf "  $(GREEN)make zsh$(RESET)             wire ZDOTDIR → this repo\n"
	@printf "  $(GREEN)make nvim$(RESET)            symlink nvim config\n"
	@printf "  $(GREEN)make tmux$(RESET)            symlink ~/.tmux.conf\n"
	@printf "  $(GREEN)make git$(RESET)             symlink ~/.gitconfig\n"
	@printf "  $(GREEN)make bin$(RESET)             ensure ~/conf/bin is in PATH\n"
	@printf "  $(GREEN)make tools$(RESET)           install base tools (auto-detect OS)\n"
	@printf "  $(GREEN)make tools-mac$(RESET)       install base tools via Homebrew\n"
	@printf "  $(GREEN)make tools-linux$(RESET)     install base tools via apt / curl\n"
	@printf "  $(GREEN)make update$(RESET)          git pull + nvim lazy sync + zinit update\n"
	@printf "  $(GREEN)make check$(RESET)           show which tools/links are present\n\n"

# ── install (meta) ────────────────────────────────────────────────────────────
.PHONY: install
install: zsh nvim tmux git bin
	@$(ok) "bootstrap complete — open a new shell to apply changes"

# ── zsh ───────────────────────────────────────────────────────────────────────
.PHONY: zsh
zsh:
	@$(inf) "configuring zsh (ZDOTDIR)"
	@# Ensure profile is sourced from ~/.zshenv so XDG + ZDOTDIR are set early
	@line='[ -f $(CONF)/profile ] && source $(CONF)/profile'; \
	  if [ -f "$(HOME)/.zshenv" ] && grep -qF "$$line" "$(HOME)/.zshenv"; then \
	    $(wrn) "~/.zshenv already has profile source — skipping"; \
	  else \
	    printf '%s\n' "$$line" >> "$(HOME)/.zshenv"; \
	    $(ok) "appended profile source to ~/.zshenv"; \
	  fi
	@# Write ZDOTDIR bootstrap (idempotent)
	@zdotdir_line='export ZDOTDIR="$(CONF)/zsh"'; \
	  if [ -f "$(HOME)/.zshenv" ] && grep -qF "$$zdotdir_line" "$(HOME)/.zshenv"; then \
	    $(wrn) "~/.zshenv already sets ZDOTDIR — skipping"; \
	  else \
	    printf '%s\n' "$$zdotdir_line" >> "$(HOME)/.zshenv"; \
	    $(ok) "wrote ZDOTDIR to ~/.zshenv"; \
	  fi

# ── nvim ──────────────────────────────────────────────────────────────────────
.PHONY: nvim
nvim:
	@$(inf) "configuring neovim"
	@# When XDG_CONFIG_HOME=~/conf, nvim is found automatically.
	@# Only create a symlink if XDG_CONFIG_HOME differs from this repo.
	@xdg=$${XDG_CONFIG_HOME:-$(HOME)/.config}; \
	  if [ "$$xdg" = "$(CONF)" ]; then \
	    $(ok) "XDG_CONFIG_HOME=~/conf — nvim already found at $(CONF)/nvim"; \
	  elif [ -e "$$xdg/nvim" ]; then \
	    $(wrn) "$$xdg/nvim already exists — skipping"; \
	  else \
	    ln -sf "$(CONF)/nvim" "$$xdg/nvim"; \
	    $(ok) "symlinked $$xdg/nvim → $(CONF)/nvim"; \
	  fi

# ── tmux ──────────────────────────────────────────────────────────────────────
.PHONY: tmux
tmux:
	@$(inf) "configuring tmux"
	@target="$(HOME)/.tmux.conf"; src="$(CONF)/tmux/.tmux.conf"; \
	  if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$src" ]; then \
	    $(wrn) "~/.tmux.conf already linked — skipping"; \
	  elif [ -e "$$target" ]; then \
	    mv "$$target" "$$target.bak.$$(date +%s)"; \
	    ln -sf "$$src" "$$target"; \
	    $(ok) "backed up old ~/.tmux.conf and linked to $(CONF)/tmux/.tmux.conf"; \
	  else \
	    ln -sf "$$src" "$$target"; \
	    $(ok) "symlinked ~/.tmux.conf → $(CONF)/tmux/.tmux.conf"; \
	  fi

# ── git ───────────────────────────────────────────────────────────────────────
.PHONY: git
git:
	@$(inf) "configuring git"
	@target="$(HOME)/.gitconfig"; src="$(CONF)/git/config"; \
	  if [ -L "$$target" ] && [ "$$(readlink "$$target")" = "$$src" ]; then \
	    $(wrn) "~/.gitconfig already linked — skipping"; \
	  elif [ -e "$$target" ]; then \
	    mv "$$target" "$$target.bak.$$(date +%s)"; \
	    ln -sf "$$src" "$$target"; \
	    $(ok) "backed up old ~/.gitconfig and linked to $(CONF)/git/config"; \
	  else \
	    ln -sf "$$src" "$$target"; \
	    $(ok) "symlinked ~/.gitconfig → $(CONF)/git/config"; \
	  fi

# ── bin ───────────────────────────────────────────────────────────────────────
.PHONY: bin
bin:
	@$(inf) "checking ~/conf/bin in PATH"
	@if echo "$$PATH" | grep -q "$(CONF)/bin"; then \
	  $(wrn) "$(CONF)/bin already in PATH — skipping"; \
	else \
	  $(wrn) "$(CONF)/bin not in PATH yet — it will be after you source profile"; \
	fi
	@# Make sure all scripts are executable
	@find "$(CONF)/bin" -type f | xargs chmod +x 2>/dev/null || true
	@$(ok) "bin scripts are executable"

# ── tools ─────────────────────────────────────────────────────────────────────
.PHONY: tools
tools:
ifeq ($(UNAME),Darwin)
	@$(MAKE) tools-mac
else
	@$(MAKE) tools-linux
endif

.PHONY: tools-mac
tools-mac:
	@$(inf) "installing base tools via Homebrew"
	@command -v brew >/dev/null 2>&1 || { \
	  $(inf) "installing Homebrew"; \
	  /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	}
	@brew install \
	  neovim \
	  tmux git zsh starship \
	  jq curl wget tree htop \
	  gnu-sed coreutils || true
	@$(ok) "Homebrew base tools installed"

.PHONY: tools-linux
tools-linux:
	@$(inf) "installing base tools on Linux"
	@# apt packages (best-effort; skip on failure)
	@if command -v apt-get >/dev/null 2>&1; then \
	  sudo apt-get install -y \
	    git tmux zsh curl wget jq tree htop unzip || true; \
	fi
	@# neovim — latest appimage
	@if ! command -v nvim >/dev/null 2>&1; then \
	  $(inf) "installing neovim appimage"; \
	  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage; \
	  chmod +x nvim-linux-x86_64.appimage; \
	  sudo mv nvim-linux-x86_64.appimage /usr/local/bin/nvim; \
	fi
	@$(ok) "Linux base tools installed"

# ── update ────────────────────────────────────────────────────────────────────
.PHONY: update
update:
	@$(inf) "pulling latest conf"
	@git -C "$(CONF)" pull --ff-only
	@$(inf) "syncing nvim plugins (lazy)"
	@nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
	@$(inf) "updating zinit plugins"
	@zsh -i -c "zinit update --all" 2>/dev/null || true
	@$(ok) "update complete"

# ── check ─────────────────────────────────────────────────────────────────────
.PHONY: check
check:
	@xdg_config=$${XDG_CONFIG_HOME:-$(HOME)/.config}; \
	printf "\n$(CYAN)── effective configuration ────────────────────$(RESET)\n"; \
	tmux_config=$$(tmux display-message -p '#{config_files}' 2>/dev/null || true); \
	if [ -n "$$tmux_config" ]; then \
	  printf "  $(GREEN)✓$(RESET)  %-12s %s\n" tmux "$$tmux_config"; \
	elif [ -r "$$xdg_config/tmux/tmux.conf" ]; then \
	  printf "  $(YELLOW)!$(RESET)  %-12s %s (server not running)\n" tmux "$$xdg_config/tmux/tmux.conf"; \
	else \
	  printf "  ✗  %-12s no effective XDG config\n" tmux; \
	fi; \
	git_config="$$xdg_config/git/config"; \
	if git config --global --show-origin --list 2>/dev/null | \
	    awk -F '\t' -v origin="file:$$git_config" '$$1 == origin { found=1 } END { exit !found }'; then \
	  printf "  $(GREEN)✓$(RESET)  %-12s %s\n" git "$$git_config"; \
	else \
	  printf "  ✗  %-12s %s is not loaded\n" git "$$git_config"; \
	fi; \
	zdotdir=$$(env -u ZDOTDIR -u XDG_CONFIG_HOME zsh -lc 'printf %s "$${ZDOTDIR:-}"' 2>/dev/null); \
	if [ "$$zdotdir" = "$(CONF)/zsh" ]; then \
	  printf "  $(GREEN)✓$(RESET)  %-12s %s\n" zsh "$$zdotdir"; \
	else \
	  printf "  ✗  %-12s expected %s, got %s\n" zsh "$(CONF)/zsh" "$${zdotdir:-unset}"; \
	fi; \
	_check_commands() { \
	  for cmd in "$$@"; do \
	    if ! command -v "$$cmd" >/dev/null 2>&1; then \
	      printf "  ✗  %-12s missing\n" "$$cmd"; \
	      continue; \
	    fi; \
	    case "$$cmd" in tmux) version_arg=-V ;; *) version_arg=--version ;; esac; \
	    if version_output=$$("$$cmd" "$$version_arg" 2>&1); then \
	      version_output=$$(printf '%s\n' "$$version_output" | head -n 1); \
	      printf "  $(GREEN)✓$(RESET)  %-12s %s\n" "$$cmd" "$$version_output"; \
	    else \
	      status=$$?; \
	      version_output=$$(printf '%s\n' "$$version_output" | head -n 1); \
	      printf "  $(YELLOW)!$(RESET)  %-12s unusable (exit %s): %s\n" "$$cmd" "$$status" "$$version_output"; \
	    fi; \
	  done; \
	}; \
	printf "\n$(CYAN)── base tools (Makefile) ──────────────────────$(RESET)\n"; \
	_check_commands $(BASE_COMMANDS); \
	printf "\n$(CYAN)── user tools (zinit) ─────────────────────────$(RESET)\n"; \
	_check_commands $(ZINIT_COMMANDS); \
	printf "\n"
