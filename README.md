# My dotfiles

> [!WARNING]
> Please be careful. You use the configurations at your own risk. It is possible that something may not work as described. This tool is for internal use and is subject to rapid change.
> If you have any questions or problems, please post them in the discussions.

## **Install some packages (Fedora)**

```bash
sudo dnf install htop fd-find fzf zoxide ripgrep golang zsh git
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh # Rust installation
cargo install tlrc
```

## Install a dotfiles

```
stow tmux vim startship zsh

```

### Zsh PATH

Keep static `PATH` setup in `zsh/.zshenv`, not `.zshrc`, so every zsh invocation sees it. Login shells initialize the selected Node.js version through `fnm` in `zsh/.zprofile`; restart the tmux server after changing that environment.

## Neovim configurations in a separate repository

```bash
# Clone repository with nvim configurations
git clone https://github.com/RomanAverin/neovim-dot ~/config/nvim
```

[https://github.com/RomanAverin/neovim-dot](https://github.com/RomanAverin/neovim-dot)

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
