# Installation

Utilizing GNU Stow for dotfile management

```
git clone <repo> ~/dotfiles

cd ~/dotfiles

stow .
```

# Required Tools

## GNU Stow

For dotfile management

`sudo apt-get install stow`

## Lazygit

For nvim git management

```
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
```

## Ripgrep

For nvim word search

`sudo apt-get install ripgrep`

## Clipboard

If on WSL2, if you want your neovim clipboard to use your system clipboard:

`sudo apt install wl-clipboard`
