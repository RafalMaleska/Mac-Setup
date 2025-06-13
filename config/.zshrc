# Path to Oh My Zsh installation.
export ZSH=~/ohmyzsh

# Disable auto title and auto updates for performance.
DISABLE_AUTO_TITLE="true"
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# disable automatic updates
zstyle ':omz:update' mode disabled

# Displays red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Set the history file location
HISTFILE=~/.zsh_history
HISTSIZE=30000
SAVEHIST=$HISTSIZE

## HISTORY
#setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt APPEND_HISTORY            # Append to the history file, don't overwrite it
setopt INC_APPEND_HISTORY        # Write commands to the history file immediately
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_REDUCE_BLANKS        # Remove extra blanks from commands before saving
setopt SHARE_HISTORY              # Share history between all sessions.
## END HISTORY


# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# User configuration

plugins=(
    git
    command-not-found
    common-aliases
    encode64
    git-extras
    kubectl
    colorize
    k9s
    history
    history-substring-search
    zsh-navigation-tools
    helm
    terraform
    starship
    golang
    jsontools
    docker
    vscode
#    sudo
#    colored-man-pages
#    ssh-agent
#    zsh-output-highlighting
#    azure
#    cp
#    zsh-interactive-cd
#    kubectx
#    fast-syntax-highlighting
#    themes
#    istioctl
# Custom plugins:
    )

source $ZSH/oh-my-zsh.sh
#used for prompt customization - has to be behind source $ZSH


# Completion system optimization.
autoload -Uz compinit && compinit || {
    rm -f ~/.zcompdump;
    autoload -Uz compinit && compinit;
}

#Lazy loading for frequently used tools (e.g. kubectl):
kubectl() {
  unalias kubectl 2>/dev/null
  unfunction kubectl
  source <(kubectl completion zsh)
  kubectl "$@"
}

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Environment variables.
export KUBE_EDITOR="code --wait"
# for krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Aliases and functions.
alias kcn='kubens'
alias kc='kubectx'
alias kubectl="kubecolor"
alias k='kubecolor'
cd ~/projects/ || exit


if command -v go &>/dev/null && [[ -d ${HOME}/go/bin ]]; then
  export PATH="${HOME}/go/bin:$PATH" 
fi

ssh-add ~/.ssh/id_rsa.key 2>/dev/null
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh