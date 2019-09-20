这份配置有在`centos4.3`/`centos6.3`/`macOS Mojave`上运行OK。

为zsh、vim、tmux等的配置自定义了目录，是由于公司服务器一账号多人使用，为了不破坏服务器环境，也为了能每人一份自己的配置。



## Requirements
- `zsh`: 5.0 or higher
- `tmux`: 2.2 ~ 2.6
- `vim`: 8.0 or higher

## INSTALL
```sh
git clone https://github.com/commiyou/conf .
ZDOTDIR=$(pwd)/conf/zsh zsh
```

## zsh

`zsh`相关配置在[zsh](zsh)目录下。[zsh/.zshrc](zsh/.zshrc)会依次Load[zsh/zsh.before](zsh/zsh.before)、[zsh/zshrc.d](zsh/zshrc.d)、[zsh/zsh.after](zsh/zsh.after)中各.zsh后缀文件

其中[zsh/zshrc.d/zplug.zsh](zsh/zshrc.d/zplug.zsh)是[zplug](https://github.com/zplug/zplug)配置，第一次运行时会自动安装相关工具。

###  常用工具
- [z](https://github.com/rupa/z):  <kbd>tab</kbd>补全
- [v](https://github.com/rupa/v):  <kbd>tab</kbd>补全
- [fzf](https://github.com/junegunn/fzf): 用来补全，有<kbd>C</kbd>+<kbd>R</kbd>, 有命令`f`查看当前目录
- [zsh/bin](zsh/bin)目录下的一些工具
	- [csbk](zsh/bin/csbk): Calc Sum By Key
	- [slbk](zsh/bin/slbk): Select Line By Key
	- [fno](zsh/bin/fno): File column NO of one line
	- [pprint](zsh/bin/pprint): Pretty PRINT json。
	- [luit](https://linux.die.net/man/1/luit):  Luit is a filter that can be run between an arbitrary application and a UTF-8 terminal emulator.
	- [distcp](zsh/bin/distcp): hadoop distcp khan/taihang/mulan
	- [divide](zsh/bin/divide)
- [fd](https://github.com/sharkdp/fd): `cheat fd`
- [rg](https://github.com/BurntSushi/ripgrep): `rg -t sh `寻找当前sh后缀文件

### tips
- `sip <iterm-profile-name>` 可以切换itemr2的配置，可以设置一个配置utf8编码，一个配置gb18030编码

## vim
`vim`相关配置在[vim](vim)目录下。[vim/.vimrc](vim/.vimrc)会加载[vim/vimrc.d](vim/vimrc.d)下的.vim后缀文件

其中[vim/vimrc.d/plugins.vim](vim/vimrc.d/plugins.vim)是[vim-plug](https://github.com/junegunn/vim-plug)的配置。

第一次运行时，需要键入`:PlugInstall` 来安装相关配置

### keybindings
`mapleader` 为`space`
- `<Leader>`+<kbd>gg</kbd>: 设置文件编码为gbk
- `<Leader>`+<kbd>uu</kbd>: 设置文件编码为utf8
- `<Leader>`+<kbd>M</kbd>: color/uncolor current word
- `<Leader>`+<kbd>b</kbd>: buffers/opened files
- `<Leader>`+<kbd>m</kbd>: recent opened files
- `<Leader>`+<kbd>ff</kbd>: file under cwd
- `<Leader>`+<kbd>fg</kbd>: file under git dir
- `<Leader>`+<kbd>fd</kbd>: file under dir of current file  
- `<Leader>`+<kbd>rr</kbd>: search lines under cwd
- `<Leader>`+<kbd>rg</kbd>: search lines under git dir
- `<Leader>`+<kbd>rd</kbd>: search lines under dir of current file  


### 常用工具


## tmux
`tmux`相关配置在[tmux](tmux)目录下。[tmux/.tmux.conf](tmux/.tmux.conf)使用[tpm](https://github.com/tmux-plugins/tpm)来管理相关插件。

第一次运行时，需要键入`prefix`+ <kbd>I</kbd>来安装相关插件，安装完成后可能需要关闭tmux server重新进入。


### keybindings
`prefix`设置为 <kbd>M</kbd>+<kbd>;</kbd>，其中<kbd>M</kbd>为`meta`键，`iTerm2`可以load[mac/com.googlecode.iterm2.plist](mac/com.googlecode.iterm2.plist)配置，里面已经设置好
- <kbd>M</kbd>+<kbd>s</kbd>: list sessions
- `prefix`+<kbd>c</kbd>: new pane
- <kbd>M</kbd>+<kbd>-</kbd>: split window
- <kbd>M</kbd>+<kbd>\\</kbd>: split window -h
- `prefix`+<kbd>C</kbd>: new session
- `prefix`+<kbd>d</kbd>: detach
- `prefix`+<kbd>D</kbd>: detach other users
- <kbd>C</kbd>+<kbd>h/j/k/l</kbd>: select pane
- <kbd>C</kbd>+<kbd>1..9</kbd>: select window


## docker
`docker`目录里存放的有build base环境的[docker/Dockerfile](docker/Dockerfile)，

### docker常用操作
```zsh
docker images
docker ps
docker attach <container>
docker run -ti <image>
docker system prune
```

### build
```zsh
cd ~conf/docker
docker-compose build . -t env
```

### run
仅第一次才需要运行，后面每次run都会创建一个新的contaniner
```zsh
cd ~conf/docker
docker-compose run env bash
```

### attach
```zsh
docker attach <kbd>tab</kbd>  # tab查看已有contaniner
```
