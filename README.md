# My dotfiles are managed by a dotfiles management system

![Test Dotfiles Manager](https://github.com/RomanAverin/dotfiles/actions/workflows/test-dotfiles-manager.yml/badge.svg)
![Pylint](https://github.com/RomanAverin/dotfiles/actions/workflows/pylint.yml/badge.svg)

> [!WARNING]
> Please be careful. You use the configurations and manager at your own risk. It is possible that something may not work as described. This tool is for internal use and is subject to rapid change.
> If you have any questions or problems, please post them in the discussions.

## **Install some packages (Fedora)**

```bash
sudo dnf install htop fd-find fzf zoxide ripgrep golang zsh git
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh # Rust installation
cargo install tlrc
```

## Neovim configurations in a separate repository

```bash
# Clone repository with nvim configurations
git clone https://github.com/RomanAverin/neovim-dot ~/config/nvim
```

[https://github.com/RomanAverin/neovim-dot](https://github.com/RomanAverin/neovim-dot)

## Dotfiles Manager

Use the `dotfiles-manager.py` Python script to simplify dotfiles management.

- **Requirements**: Python 3.6+ (pre-installed on Fedora/Ubuntu)
- **Dependencies**: None! Works immediately after `git clone`

### Quick Start

```bash
# Clone repository
git clone https://github.com/RomanAverin/dotfiles
cd dotfiles

# Install configs for zsh and kitty
./dotfiles-manager/dotfiles-manager.py install zsh p10k.zsh kitty

# Check status of all packages
./dotfiles-manager/dotfiles-manager.py status

# Move existing configs to dotfiles (with git integration)
./dotfiles-manager/dotfiles-manager.py adopt ghostty

# Remove symlinks
./dotfiles-manager/dotfiles-manager.py uninstall kitty

# Install all packages
./dotfiles-manager/dotfiles-manager.py install --all
```

### Available Commands

- `install` - Install symlinks for packages
- `uninstall` - Remove symlinks
- `restow` - Reinstall symlinks
- `adopt` - Move existing configs to dotfiles (with git diff)
- `status` - Show status of all packages
- `list` - List available packages
- `check` - Check symlink integrity

### Options

- `-a, --all` - Apply to all packages
- `-n, --dry-run` - Simulate without changes
- `-v, --verbose` - Verbose output
- `--no-git` - Disable git integration for adopt

### Safety

The script always:

- Shows preview of changes before execution
- Requests confirmation for each operation
- Automatically creates backup files on conflicts in `.backups/`
- Logs all actions to `.logs/`
- Uses dry-run before actual changes

### Git Integration

When using `adopt` the script automatically:

1. Shows `git diff` with changes
2. Prompts to create a commit
3. Formats commit following Conventional Commits

## Development & Testing

The dotfiles-manager includes comprehensive test coverage with automated CI/CD.

### Running Tests Locally

```bash
cd dotfiles-manager

# Install test dependencies
pip install -r requirements-dev.txt

# Run all tests
pytest

# Run with coverage report
pytest --cov=. --cov-report=html

# Run only unit tests
pytest -m unit

# Run specific test file
pytest tests/test_validation.py
```

### Continuous Integration

Automated workflows run on every push to `dotfiles-manager/`:

- **Pylint**: Code quality checks (Python 3.8, 3.10, 3.12)
- **Pytest**: Full test suite
- **Triggers**: Only when `dotfiles-manager/**` files change

Status badges show current build status at the top of this README.

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
