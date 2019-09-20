#!/usr/bin/env zsh
abs_path() {
  perl -MCwd -le '
    for (@ARGV) {
      if ($p = Cwd::abs_path $_) {
        print $p;
      } else {
        warn "abs_path: $_: $!\n";
        $ret = 1;
      }
    }
    exit $ret' "$@"
}

export ZDOTDIR=$(dirname $(abs_path ${(%):-%x}))

# zmodload zsh/zprof
if [ -d $ZDOTDIR/zsh.before/ ]; then
  if [ "$(ls -A $ZDOTDIR/zsh.before/)" ]; then
    for config_file ($ZDOTDIR/zsh.before/*.zsh) source $config_file
  fi
fi

if [ -d $ZDOTDIR/zshrc.d/ ]; then
  if [ "$(ls -A $ZDOTDIR/zshrc.d/)" ]; then
    for config_file ($ZDOTDIR/zshrc.d/*.zsh) source $config_file
  fi
fi


if [ -d $ZDOTDIR/zsh.after/ ]; then
  if [ "$(ls -A $ZDOTDIR/zsh.after/)" ]; then
    for config_file ($ZDOTDIR/zsh.after/*.zsh) source $config_file
  fi
fi
#zprof
