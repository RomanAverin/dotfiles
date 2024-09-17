# Configuration Fedora 39/40

## Drivers

- Logitech drivers and config

```
sudo dnf install logiops
sudo cp config/logid.cfg /etc/
sudo chown root:root /etc/logid.cfg
sudo systemctl enable logid.service
sudo systemctl start logid.service
```

## Environment

- Install zsh + ohmyzsh + antigen

```
sudo dnf install git zsh vim
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
curl -L git.io/antigen > antigen.zsh
cp config/.zshrc ~
```

- Install neovim
  [https://github.com/RomanAverin/neovim-dotfiles](https://github.com/RomanAverin/neovim-dotfiles)
