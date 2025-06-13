#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
USERNAME="rafal"
REPO_URL="https://github.com/RafalMaleska/Mac-Setup"
DOTFILES_REPO="git@github.com:RafalMaleska/dotfiles.git"
OHMYZSH_REPO="https://github.com/ohmyzsh/ohmyzsh.git"

# --- LOGGING FUNCTION ---
log() { echo -e "\033[1;32m[INFO]\033[0m $1"; }

# --- CHECKS & UTILS ---
require() { command -v "$1" >/dev/null 2>&1 || { log "Missing $1, aborting."; exit 1; }; }

# --- ESSENTIALS ---
install_essentials() {
  log "Checking Xcode Command Line Tools..."
  xcode-select -p &>/dev/null || xcode-select --install

  log "Checking Homebrew..."
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

# --- USER SETUP (optional, for automation only) ---
# See note below on user creation

# --- SSH SETUP ---
setup_ssh() {
  log "Configuring SSH..."
  local ssh_dir="$HOME/.ssh"
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
  touch "$ssh_dir/config"
  chmod 600 "$ssh_dir/config"

  # Prompt for SSH key path if not given
  local key_path="${1:-}"
  if [[ -z "$key_path" ]]; then
    read -rp "Enter path to your SSH private key: " key_path
  fi
  cp "$key_path" "$ssh_dir/id_rsa"
  chmod 600 "$ssh_dir/id_rsa"
  ssh-add --apple-use-keychain "$ssh_dir/id_rsa" || ssh-add "$ssh_dir/id_rsa"

  curl https://github.com/${USERNAME}.keys >> "$ssh_dir/authorized_keys"
  chmod 600 "$ssh_dir/authorized_keys"
}

# --- HOMEBREW BASICS ---
function basics {
  echo "Installing core CLI tools:"
  cat <<EOF
  - git
  - bat (cat replacement)
  - exa (ls replacement)
  - dust (du replacement)
  - procs (ps replacement)
  - bottom (top replacement)
  - broot (file explorer)
  - git-flow
  - xcp (cd replacement)
  - tree
  - wget
  - tmux
  - jq
  - yq
  - htop
  - grep
  - pstree
  - nmap
  - unrar
  - ack
  - httpie
  - libyaml
  - watch
  - fzf
EOF

  # Now install all at once for efficiency
  brew install git bat exa dust procs bottom broot git-flow xcp tree wget tmux jq yq htop grep pstree nmap unrar ack httpie libyaml watch fzf
  brew cleanup
}


# --- SHELL SETUP ---
setup_shell() {
  log "Setting up Zsh and Oh My Zsh..."
  brew install zsh zsh-completions zsh-syntax-highlighting pygments binutils gnu-sed gnu-getopt starship

  [[ -d "$HOME/.oh-my-zsh" ]] || git clone "$OHMYZSH_REPO" "$HOME/.oh-my-zsh"
  cp config/starship.toml ~/.config/
  cp config/topgrade.toml ~/.config/
  cp config/.zshrc ~/
  git clone --depth=1 https://github.com/powerline/fonts.git
  ./fonts/install.sh
  rm -rf fonts
}

# --- DEV TOOLS ---
function dev-tools {
  echo "Installing developer tools:"
  cat <<EOF
  - Visual Studio Code
  - iTerm2
  - Docker
  - Rancher
  - Hyperkit
  - Minikube
  - Google Cloud SDK
  - Terraform
  - Hugo
  - Go
  - AWS CLI
  - Localstack
  - EKSCTL
  - ShellCheck
  - Python3 & Pipenv
  - Kubectl & related Kubernetes tools
  - Helm & plugins
  - ArgoCD
  - K9s
  - Ngrok
  - Wireshark
  - Postman
  - Fork
  - Sourcetree
EOF

  # Install with Homebrew (grouped for efficiency)
  brew install --cask visual-studio-code iterm2 docker rancher hyperkit minikube google-cloud-sdk wireshark postman fork sourcetree
  brew install k3d devspace terraform hugo go awscli localstack eksctl shellcheck python3 pipenv kubectl kubectx kubecolor stern istioctl skaffold kind helm helmfile kustomize argocd kubebuilder kubeseal k9s vendir skopeo velero minio-mc kpt krew ngrok
  brew cleanup
}


# --- GUI TOOLS ---
function tools {
  echo "Installing GUI applications:"
  cat <<EOF
  - Caffeine
  - OBS
  - VLC
  - Google Chrome
  - Google Drive
  - Dozer
  - CleanMyMac
  - Licecap
  - Spotify
  - Alfred
  - Transmission
  - Cyberduck
  - Draw.io
  - Slack
  - Zoom
  - Microsoft Office Suite (Outlook, Teams, PowerPoint, Word, Excel)
  - Android File Transfer
  - Signal
  - Cool Retro Term
  - GIMP
  - Paintbrush
  - Keka
EOF

  brew install --cask caffeine obs vlc google-chrome google-drive dozer cleanmymac licecap spotify alfred transmission cyberduck drawio slack zoom microsoft-outlook microsoft-teams microsoft-powerpoint microsoft-word microsoft-excel android-file-transfer signal cool-retro-term gimp paintbrush keka
  brew cleanup
}


# --- NON-BREW TOOLS ---
install_nonbrew() {
  log "Installing non-Homebrew tools..."
  wget -O kfilt https://github.com/ryane/kfilt/releases/download/v0.0.8/kfilt_0.0.8_darwin_all
  chmod 755 kfilt
  sudo mv kfilt /usr/local/bin/
  curl -Lo mizu github.com/up9inc/mizu/releases/latest/download/mizu_darwin_amd64
  chmod 755 mizu
  sudo mv mizu /usr/local/bin/
}

# --- DOTFILES & MACKUP ---
setup_dotfiles() {
  log "Setting up Mackup and dotfiles..."
  brew install mackup
  git clone "$DOTFILES_REPO" ~/dotfiles
  cp ~/dotfiles/Mackup/.mackup.cfg ~/.mackup.cfg
  mackup restore
}

# --- MACOS DEFAULTS ---
configure_macos() {
  log "Configuring macOS defaults..."
  # Add your `defaults write` commands here, as in your original script
}

# --- MAIN INSTALLER ---
main() {
  install_essentials
  # add_user  # Only if you need to automate user creation (see note below)
  setup_ssh "$@"
  install_basics
  setup_shell
  install_dev_tools
  install_gui_tools
  install_nonbrew
  setup_dotfiles
  configure_macos
  log "All done! Please restart your terminal."
}

main "$@"
