# Install on the Fedora

## Drivers

- Logitech drivers and config

```bash
sudo dnf install logiops
sudo cp config/logid.cfg /etc/
sudo chown root:root /etc/logid.cfg
sudo systemctl enable logid.service
sudo systemctl start logid.service
```

## Environment

- **Install zsh and configure prompt(use zinit and powerlevel10k)**

```bash
sudo dnf install git zsh vim fzf stow zoxide
git clone https://github.com/RomanAverin/dotfiles
stow -v -R -t ~ zsh
stow -v -R -t ~ p10k.zsh
source ~/.zshrc
```

To customize the prompt

```bash
p10k configure
```

- **Install neovim**

```bash
  sudo dnf install neovim
  git clone https://github.com/RomanAverin/neovim-dotfiles ~/.config/nvim
```

- **Fix markdown-preview.nvim**

```bash
cd ~/.local/share/nvim/lazy/markdown-preview.nvim
npm install
```

- **Install some utils**

```bash
sudo dnf install htop fd-find
cargo install tlrc
```

## Troubleshooting

- **fzf problem**

```bash
fzf --zsh
unknown option: --zsh
```

Install latest version of the fzf

- **zsh compinit: insecure directories**

  Problem with permissions
  Fix it

```bash
compaudit | xargs chown -R "$(whoami)"
compaudit | xargs chmod go-w
```
