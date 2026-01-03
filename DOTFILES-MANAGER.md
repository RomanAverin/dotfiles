# Dotfiles Manager

Python-based dotfiles manager using GNU Stow for symlink management.

## Features

- **Automated symlink management** via GNU Stow
- **Safety first** - dry-run, confirmations, automatic backups
- **Full logging** - all operations logged to `.logs/`
- **Git integration** - automatic diff and commits for adopt
- **Colored output** - clear visual feedback
- **Zero dependencies** - only Python 3.6+ stdlib
- **JSON configuration** - externalized settings

## Requirements

- Python 3.6+
- GNU Stow
- Git (optional, for adopt integration)

```bash
sudo dnf install stow git
```

## Quick Start

```bash
# List available packages
./dotfiles-manager.py list

# Check current status
./dotfiles-manager.py status

# Install packages (dry-run first)
./dotfiles-manager.py install zsh kitty --dry-run

# Install for real
./dotfiles-manager.py install zsh kitty

# Install all packages
./dotfiles-manager.py install --all
```

## Commands

### `install` - Install symlinks

```bash
./dotfiles-manager.py install <packages>
./dotfiles-manager.py install zsh p10k.zsh kitty
./dotfiles-manager.py install --all              # All packages
./dotfiles-manager.py install vim --dry-run      # Simulate only
```

### `uninstall` - Remove symlinks

```bash
./dotfiles-manager.py uninstall <packages>
./dotfiles-manager.py uninstall kitty
./dotfiles-manager.py uninstall --all
```

### `restow` - Reinstall symlinks

```bash
./dotfiles-manager.py restow <packages>
./dotfiles-manager.py restow zsh kitty
```

### `adopt` - Move existing configs to dotfiles

```bash
# Moves existing files to dotfiles repo and creates symlinks
./dotfiles-manager.py adopt ghostty

# Shows git diff and prompts for commit
./dotfiles-manager.py adopt wezterm --no-git     # Skip git
```

### `status` - Show symlink status

```bash
./dotfiles-manager.py status                     # All packages
./dotfiles-manager.py status zsh kitty          # Specific packages
```

### `check` - Check symlink integrity

```bash
./dotfiles-manager.py check                      # All packages
./dotfiles-manager.py check zsh                 # Specific package
```

### `list` - List available packages

```bash
./dotfiles-manager.py list
```

### `new` - Create new package

```bash
# Create package and automatically adopt existing config (recommended)
./dotfiles-manager.py new alacritty --from ~/.config/alacritty

# Create package for directory in HOME root
./dotfiles-manager.py new aider --from ~/.aider

# Create package for file in HOME root
./dotfiles-manager.py new bashrc --from ~/.bashrc

# Create empty package structure (add files manually later)
./dotfiles-manager.py new neovim

# Create sudo package
./dotfiles-manager.py new logid --from /etc/logid.cfg --sudo

# Dry-run to preview
./dotfiles-manager.py new firefox --from ~/.mozilla/firefox --dry-run
```

**Features:**
- Automatically detects structure type from `--from` path (XDG for `~/.config/`, simple for `~/`)
- Creates directory structure and updates configuration
- Optionally adopts existing files if `--from` is specified
- No need to know about stow internals - just specify where your config is!

## Options

- `-a, --all` - Apply to all packages
- `-n, --dry-run` - Simulate without changes
- `-v, --verbose` - Verbose output
- `--no-git` - Skip git integration (adopt only)
- `-h, --help` - Show help

## Package Structure

Packages must follow XDG Base Directory structure:

```
dotfiles/
  packagename/
    .config/
      packagename/
        config-files...
```

**Example for starship:**

```
starship/
  .config/
    starship.toml
```

Creates: `~/.config/starship.toml`

**Example for zsh:**

```
zsh/
  .zshrc
```

Creates: `~/.zshrc`

## Configuration

Edit `.dotfiles-config.json` to customize:

```json
{
  "default_target": "~",
  "all_packages": ["zsh", "kitty", "starship"],
  "sudo_packages": ["etc"],
  "package_targets": {
    "custom-pkg": "~/.local/share"
  }
}
```

### Custom Target Directories

To install a package to a different location:

```json
{
  "package_targets": {
    "mypackage": "~/.local/share"
  }
}
```

## Safety Features

### Automatic Backups

Conflicting files are automatically backed up to `.backups/YYYYMMDD-HHMMSS/`

### Dry-Run Mode

Always test changes first:

```bash
./dotfiles-manager.py install kitty --dry-run
```

### Interactive Confirmations

Every operation requires confirmation with detailed preview:

```
Preview: INSTALL
Operation: install
Packages: zsh, kitty
Target: /home/user

✓ Package 'zsh' ready
⚠ Package 'kitty' - Found conflicts: 2

Continue? [y/N]:
```

### Logging

All operations logged to `.logs/stow-manager-YYYYMMDD.log`

## Examples

### Initial Setup on New System

```bash
git clone https://github.com/yourusername/dotfiles
cd dotfiles

# Review what will be installed
./dotfiles-manager.py install --all --dry-run

# Install everything
./dotfiles-manager.py install --all
```

### Adding New Package

**Recommended way (using `new` command):**

```bash
# Automatically create structure and adopt existing config
./dotfiles-manager.py new alacritty --from ~/.config/alacritty

# For configs in HOME root
./dotfiles-manager.py new aider --from ~/.aider

# The command will:
# 1. Detect structure type automatically (XDG for ~/.config/, simple for ~/)
# 2. Create directory structure
# 3. Update .dotfiles-config.json
# 4. Adopt existing files
# 5. Create symlinks
```

**Manual way (old method, not recommended):**

```bash
# Create package structure inside dotfiles
mkdir -p newpackage/.config/newpackage
cp ~/.config/newpackage/config newpackage/.config/newpackage/

# Add to config
# Edit .dotfiles-config.json and add "newpackage" to all_packages

# Install
./dotfiles-manager.py install newpackage
```

### Adopting Existing Configs

**Using `new` command (recommended):**

```bash
# One command does everything!
./dotfiles-manager.py new alacritty --from ~/.config/alacritty
```

**Using `adopt` command (if package structure already exists):**

```bash
# You have ~/.config/alacritty/alacritty.yml
# Want to move it to dotfiles

# Create package structure (empty)
mkdir -p alacritty/.config/alacritty

# Add to .dotfiles-config.json
# Then adopt
./dotfiles-manager.py adopt alacritty

# This will:
# 1. Move ~/.config/alacritty/alacritty.yml to dotfiles/alacritty/.config/alacritty/
# 2. Create symlink from ~/.config/alacritty/alacritty.yml to dotfiles
# 3. Show git diff
# 4. Prompt to commit changes
```

### Checking Installation

```bash
# Check all packages
./dotfiles-manager.py status

# Output:
# zsh:
#   ✓ .zshrc
# kitty:
#   ✓ .config/kitty/kitty.conf
#   ✗ .config/kitty/theme.conf (file exists, not symlink)
#   ○ .config/kitty/custom.conf (not installed)
```

### Updating Dotfiles

```bash
# After editing configs in dotfiles repo
git add .
git commit -m "update: kitty color scheme"
git push

# On another machine
git pull
./dotfiles-manager.py restow kitty
```

## Status Indicators

- `✓` - Correctly symlinked
- `⚠` - Symlink exists but points to wrong target
- `✗` - File exists but is not a symlink
- `○` - Not installed

## Sudo Packages

Special handling for system files (e.g., `/etc/`):

```json
{
  "sudo_packages": ["etc"],
  "special_files": {
    "etc": {
      "files": [
        {
          "src": "logid.cfg",
          "dst": "/etc/logid.cfg",
          "sudo": true
        }
      ]
    }
  }
}
```

## Troubleshooting

### "Package not found"

Ensure package directory exists in dotfiles repo.

### Conflicts during install

Use `--dry-run` to preview. Files will be backed up automatically to `.backups/`.

### Symlink integrity issues

```bash
./dotfiles-manager.py check
```

### View logs

```bash
tail -f .logs/stow-manager-$(date +%Y%m%d).log
```

## Best Practices

1. **Always dry-run first** for new packages
2. **Check status regularly** to ensure symlinks are correct
3. **Use adopt** to bring existing configs into dotfiles
4. **Commit often** - especially after adopt operations
5. **Test on VM** before running on production system
6. **Review backups** in `.backups/` before deleting

## Files and Directories

```
dotfiles/
├── dotfiles-manager.py          # Main script
├── .dotfiles-config.json        # Configuration
├── .logs/                       # Operation logs (gitignored)
├── .backups/                    # Conflict backups (gitignored)
├── package1/
│   └── .config/package1/...
└── package2/
    └── .config/package2/...
```

## License

Same as main dotfiles repository.
