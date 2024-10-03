export ZSH=$HOME/.oh-my-zsh

ZSH_THEME="agnoster"

plugins=(git minikube npm nvm rust skaffold gh aws kubectl helm)

source $ZSH/oh-my-zsh.sh

# User configuration

source ~/antigen.zsh
# Initialize antigen using the configuration from ~/.antigenrc
antigen init $HOME/.antigenrc

# Disabling conflicting oh-my-zsh aliases
unalias ls 2>/dev/null
unalias la 2>/dev/null
unalias ll 2>/dev/null

# ls and ll are functions aliased to use exa by the ls plugin
alias llt='ll --tree'
alias llti='ll --tree --git-ignore'
alias lla='ll -a'

# Tmux color configuration
export TERM=xterm-256color

# Setup environment variables

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$PATH:/home/dev/.local/bin"


#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# bun completions
[ -s "/home/dev/.bun/_bun" ] && source "/home/dev/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Android SDK
export ANDROID_HOME="$HOME/Android/sdk"
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin

# NVIM
export PATH="/opt/nvim-linux64/bin:$PATH"

# Go
export PATH=$PATH:/usr/local/go/bin
