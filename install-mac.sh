#!/bin/bash

export repository=https://github.com/RafalMaleska/Mac-Setup
export username=rafal

function essentials {
  echo "Installing xcode-stuff"
  xcode-select --install

  # Check for Homebrew,
  # Install if we don't have it
  if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}

# Add User
function add-user {
  sudo -i
  sudo echo "$username ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/sudoers
  sudo chmod 0440 /etc/sudoers.d/sudoers
  su $username
}


# Add SSH
# Important: copy SSH Key into ~/.ssh before
function add-ssh {
  sudo mkdir -p /Users/$username/.ssh
  sudo chmod 0700 $HOME/.ssh
  sudo touch ~/.ssh/config
  sudo chmod 666 ~/.ssh/config
  sudo echo "ForwardAgent yes" >> ~/.ssh/config
  sudo echo "IdentityFile ~/.ssh/id_rsa_key" >> ~/.ssh/config
  sudo chmod 600 ~/.ssh/id_rsa.key
  sudo ssh-add ~/.ssh/id_rsa.key
  su -i
  ssh-keygen -y -f /Users/${username}/.ssh/id_rsa.key > /Users/${username}/.ssh/id_rsa.pub
  chmod 666 /Users/${username}/.ssh/id_rsa.pub
  eval `ssh-agent -s`
  su ${username}
  sudo touch ~/.ssh/known_hosts
  sudo chown -v $USER ~/.ssh/known_hosts
}


function basics {
  # Update homebrew recipes
  echo "Updating homebrew..."
  brew update
  
  echo "Installing Git..."
  brew install git
  echo "Git config"
  git config --global user.name "Rafał Manhart"
  git config --global user.email rafal.manhart@gmail.com
  
  echo "Installing brew git utilities..."
  brew install git-extras
  brew install legit
  brew install git-flow
  brew install tree
  brew install wget
  brew install tmux
  brew install jq
  brew install yq
  brew install htop
  brew install pstree
  brew install nmap
  brew install unrar
  # Installing Cask for GUI Apps Install
  brew install cask

  echo "Cleaning up brew"
  brew cleanup
}

function shell {
  brew install zsh
  brew install zsh-completions
  brew install zsh-syntax-highlighting
  brew install binutils
  brew install gnu-sed
  brew install gnu-getopt

  # add to path
  PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
  PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
  PATH="/usr/local/opt/gnu-getopt/bin:$PATH"

  sudo rm -rf ~/.zsh-suite
  git clone https://github.com/RafalMaleska/shell.git ~/projects/VM-Setup/shell
  ~/projects/VM-Setup/shell/install.zsh
  git clone https://github.com/powerline/fonts.git
  ./fonts/install.sh
  zsh

  sudo cp ~/projects/VM-Setup/config/.bashrc ~/.bashrc
  sudo cp ~/projects/VM-Setup/config/.gitconfig ~/.gitconfig
}


function dev-tools {
  # Update homebrew recipes
  echo "Updating homebrew..."
  brew update
  
  brew install --cask visual-studio-code
  # install vscode extensions
  code --install-extension ms-python.python
  code --install-extension ms-vscode.Go
  code --install-extension donjayamanne.githistory
  code --install-extension erd0s.terraform-autocomplete
  code --install-extension huizhou.githd mauve.terraform
  code --install-extension ms-azuretools.vscode-docker
  code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
  code --install-extension redhat.vscode-yaml
  code --install-extension stayfool.vscode-asciidoc
  code --install-extension yzhang.markdown-all-in-one
  code --install-extension fabiospampinato.vscode-diff
  code --install-extension mads-hartmann.bash-ide-vscode
  code --install-extension rusnasonov.vscode-hugo
  brew install --cask iterm2
  brew install --cask virtualbox
  brew install --cask virtualbox-extension-pack
#  brew install --cask rancher
  brew install --cask docker
  brew install --cask google-cloud-sdk
  brew install hugo
  brew install go
  brew install awscli
  brew install shellcheck
  brew install python3 pipenv
  brew install docker
  brew install minikube
  brew install kubectl
  brew install skaffold
  brew install kind
  brew install helm
  helm plugin install https://github.com/chartmuseum/helm-push
  brew install helmfile
  brew install kustomize
  brew install argocd
  brew install kubebuilder
  brew install k9s
  brew install krew
  kubectl krew install get-all
  kubectl krew install score
  kubectl krew install sniff
  kubectl krew install tree
  kubectl krew install oidc-login
  kubectl krew install view-secret
  kubectl krew install neat
  kubectl krew install hns
  brew install --cask wireshark
  echo "Cleaning up brew"
  brew cleanup
}


function tools {
  brew install --cask caffeine
  brew install --cask vlc
  brew install --cask google-chrome
  brew install --cask google-drive
  brew install --cask bartender
  brew install --cask cleanmymac
  brew install --cask licecap
  brew install --cask sourcetree
  brew install --cask spotify
  brew install --cask transmission
  #"Hide the donate message"
  defaults write org.m0k.transmission WarningDonate -bool false
  #"Hide the legal disclaimer"
  defaults write org.m0k.transmission WarningLegal -bool false
  #"Use `~/Downloads/Incomplete` to store incomplete downloads"
  defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
  defaults write org.m0k.transmission IncompleteDownloadFolder -string "${HOME}/Downloads/Incomplete"
  brew install --cask cyberduck
  brew install --cask drawio
  brew install --cask slack
  brew install --cask zoom
  brew cleanup
}


function mac-setup {
  #"Disabling system-wide resume"
  defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false

  #"Automatically quit printer app once the print jobs complete"
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

  #"Saving to disk (not to iCloud) by default"
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

  #"Check for software updates daily, not just once per week"
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

  #"Showing icons for hard drives, servers, and removable media on the desktop"
  defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

  #"Showing all filename extensions in Finder by default"
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  #"Disabling the warning when changing a file extension"
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  #"Avoiding the creation of .DS_Store files on network volumes"
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  #"Enabling snap-to-grid for icons on the desktop and in other icon views"
  /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
  /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

  #"Setting Dock to auto-hide and removing the auto-hiding delay"
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0

  #"Enabling UTF-8 ONLY in Terminal.app and setting the Pro theme by default"
  defaults write com.apple.terminal StringEncodings -array 4
  defaults write com.apple.Terminal "Default Window Settings" -string "Pro"
  defaults write com.apple.Terminal "Startup Window Settings" -string "Pro"

  #"Preventing Time Machine from prompting to use new hard drives as backup volume"
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

  #"Setting screenshots location to ~/Desktop"
  defaults write com.apple.screencapture location -string "$HOME/Desktop"

  #"Setting screenshot format to PNG"
  defaults write com.apple.screencapture type -string "jpg"

  # Don’t automatically rearrange Spaces based on most recent use
  defaults write com.apple.dock mru-spaces -bool false
}


function main {
  essentials
  add-user
  add-ssh
  basics
  shell
  dev-tools
  tools
  mac-setup
}

main