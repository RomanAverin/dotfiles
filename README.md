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

- Install zsh + ohmyzsh + antigen

```bash
sudo dnf install git zsh vim
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
curl -L git.io/antigen > antigen.zsh
cp config/.zshrc ~
```

- Install neovim

```bash
  sudo dnf install neovim
  git clone https://github.com/RomanAverin/neovim-dotfiles ~/.config/nvim
```

- Fix markdown-preview.nvim

```bash
cd ~/.local/share/nvim/lazy/markdown-preview.nvim
npm install
```

- Install some utils

```bash
sudo dnf install htop fd-find fzf
cargo install tlrc
```
