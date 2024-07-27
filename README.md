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

## Shell aliases

#### /etc/sudoers.d/40-nopasswd

```
# dnf.upgrade
%wheel ALL = NOPASSWD: /usr/bin/dnf upgrade --assumeyes
# dnf.search
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly search *
# dnf.provides
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly provides *
# dnf.list_installed
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly list installed
# dnf.repolist
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repolist
# dnf.list_package_files
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repoquery --list
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repoquery --list *
# dnf.history_list
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly history list --reverse
# dnf.history_info
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly history info
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly history info *
# dnf.requires
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repoquery --requires --resolve
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly repoquery --requires --resolve *
# dnf.info
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly info
%wheel ALL = NOPASSWD: /usr/bin/dnf --cacheonly info *
# dnf.whatrequires
%wheel ALL = NOPASSWD: /usr/bin/dnf repoquery --installed --whatrequires *
```
