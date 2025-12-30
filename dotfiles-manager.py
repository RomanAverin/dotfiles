#!/usr/bin/env python3
"""
Dotfiles Manager - manage dotfiles with GNU Stow

Script for automating configuration file management using GNU Stow.
Supports installation, removal, updates of symlinks, and Git integration.

Uses only Python 3.6+ standard library
No external dependencies!
"""

from pathlib import Path
from dataclasses import dataclass
from typing import List, Optional, Dict, Tuple
import subprocess
import argparse
import shutil
import sys
import json
from datetime import datetime


class Colors:
    """ANSI escape codes for colored terminal output"""

    GREEN = "\033[0;32m"
    RED = "\033[0;31m"
    YELLOW = "\033[1;33m"
    BLUE = "\033[0;34m"
    CYAN = "\033[0;36m"
    BOLD = "\033[1m"
    RESET = "\033[0m"


@dataclass
class Config:
    """Dotfiles manager configuration"""

    dotfiles_dir: Path
    target_dir: Path
    log_dir: Path
    backup_dir: Path
    all_packages: List[str]
    sudo_packages: List[str]
    verbose: bool = False


class DotfilesManager:
    """Main class for managing dotfiles via stow"""

    def __init__(self, config: Config):
        self.config = config
        self.is_wsl = self._check_wsl()

        # Create necessary directories
        self.config.log_dir.mkdir(exist_ok=True)
        self.config.backup_dir.mkdir(exist_ok=True)

    # ========== Utilities and checks ==========

    def _check_dependencies(self) -> bool:
        """Check if stow and git are installed"""
        try:
            subprocess.run(["stow", "--version"], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            self._print_error("GNU Stow is not installed!")
            self._print_info("Install with: sudo dnf install stow")
            return False

    def _check_git(self) -> bool:
        """Check if git is installed"""
        try:
            subprocess.run(["git", "--version"], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False

    def _is_valid_package(self, package: str) -> bool:
        """Validate package existence"""
        package_dir = self.config.dotfiles_dir / package
        if not package_dir.exists() or not package_dir.is_dir():
            self._print_error(
                f"Package '{package}' not found in {self.config.dotfiles_dir}"
            )
            return False
        return True

    def _check_wsl(self) -> bool:
        """Detect WSL environment"""
        try:
            with open("/proc/version", "r") as f:
                return "microsoft" in f.read().lower()
        except FileNotFoundError:
            return False

    # ========== Colored output ==========

    def _print_success(self, msg: str):
        """Green success output"""
        print(f"{Colors.GREEN}✓{Colors.RESET} {msg}")

    def _print_error(self, msg: str):
        """Red error output"""
        print(f"{Colors.RED}✗{Colors.RESET} {msg}", file=sys.stderr)

    def _print_warning(self, msg: str):
        """Yellow warning output"""
        print(f"{Colors.YELLOW}⚠{Colors.RESET} {msg}")

    def _print_info(self, msg: str):
        """Blue info message"""
        print(f"{Colors.BLUE}ℹ{Colors.RESET} {msg}")

    def _print_header(self, msg: str):
        """Cyan header"""
        print(f"\n{Colors.CYAN}{Colors.BOLD}{msg}{Colors.RESET}")

    # ========== Logging ==========

    def _log(self, level: str, msg: str):
        """Write to log file with timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_file = self.config.log_dir / f"stow-manager-{datetime.now():%Y%m%d}.log"

        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {level}: {msg}\n")

        if self.config.verbose:
            self._print_info(f"[{level}] {msg}")

    # ========== Analysis and preview ==========

    def _get_package_files(self, package: str) -> List[Path]:
        """Get list of files in package"""
        package_dir = self.config.dotfiles_dir / package
        files = []

        for item in package_dir.rglob("*"):
            if item.is_file():
                # Relative path from package
                rel_path = item.relative_to(package_dir)
                files.append(rel_path)

        return files

    def _dry_run_stow(self, operation: str, package: str) -> Tuple[bool, str]:
        """Simulate stow operation via -n"""
        cmd = ["stow", "-n", "-v"]

        if operation == "install":
            cmd.extend(["-R", "-t", str(self.config.target_dir), package])
        elif operation == "uninstall":
            cmd.extend(["-D", "-t", str(self.config.target_dir), package])
        else:
            return False, f"Unknown operation: {operation}"

        try:
            result = subprocess.run(
                cmd,
                cwd=str(self.config.dotfiles_dir),
                capture_output=True,
                text=True,
                check=True,
            )
            return True, result.stderr
        except subprocess.CalledProcessError as e:
            return False, e.stderr

    def _check_conflicts(self, package: str) -> List[Tuple[Path, Path]]:
        """Detect existing files (conflicts)"""
        conflicts = []
        package_files = self._get_package_files(package)

        for rel_path in package_files:
            target_file = self.config.target_dir / rel_path
            if target_file.exists() and not target_file.is_symlink():
                dotfile = self.config.dotfiles_dir / package / rel_path
                conflicts.append((target_file, dotfile))

        return conflicts

    def _show_preview(
        self,
        operation: str,
        packages: List[str],
        dry_run_results: Dict[str, Tuple[bool, str]],
    ):
        """Show detailed preview before execution"""
        self._print_header(f"Preview: {operation.upper()}")

        print(f"Operation: {operation}")
        print(f"Packages: {', '.join(packages)}")
        print(f"Target: {self.config.target_dir}")

        total_success = 0
        total_conflicts = 0

        for package in packages:
            success, output = dry_run_results[package]

            if success:
                self._print_success(f"Package '{package}' ready")
                total_success += 1

                # Check conflicts
                conflicts = self._check_conflicts(package)
                if conflicts:
                    total_conflicts += len(conflicts)
                    self._print_warning(f"  Found conflicts: {len(conflicts)}")
                    for target, dotfile in conflicts[:3]:  # Show first 3
                        print(f"    {target}")
            else:
                self._print_error(f"Package '{package}' - error")
                total_success += 0
                if self.config.verbose:
                    print(f"    {output}")

        print(f"\nTotal: {total_success}/{len(packages)} packages ready")
        if total_conflicts > 0:
            self._print_warning(
                f"Conflicts: {total_conflicts} (backups will be created)"
            )

    # ========== Confirmation ==========

    def _confirm_action(self, prompt: str = "Continue?") -> bool:
        """Interactive confirmation"""
        response = input(f"\n{prompt} [y/N]: ").strip().lower()
        return response in ["y", "yes"]

    # ========== Backup system ==========

    def _create_backup(self, files: List[Path]) -> Path | None:
        """Create backup of files"""
        if not files:
            return None

        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_root = self.config.backup_dir / timestamp
        backup_root.mkdir(parents=True, exist_ok=True)

        for file_path in files:
            if file_path.exists():
                # Preserve directory structure
                rel_path = file_path.relative_to(self.config.target_dir)
                backup_path = backup_root / rel_path
                backup_path.parent.mkdir(parents=True, exist_ok=True)

                shutil.copy2(file_path, backup_path)
                self._log("INFO", f"Backup created: {file_path} -> {backup_path}")

        self._print_success(f"Backup created: {backup_root}")
        return backup_root

    # ========== Core stow operations ==========

    def install(self, packages: List[str], dry_run: bool = False):
        """Install symlinks via stow -R"""
        self._log("INFO", f"Starting install operation for: {', '.join(packages)}")

        # Validate packages
        valid_packages = [p for p in packages if self._is_valid_package(p)]
        if not valid_packages:
            return

        # Dry-run for all packages
        self._print_info("Analyzing changes...")
        dry_run_results = {}
        for package in valid_packages:
            success, output = self._dry_run_stow("install", package)
            dry_run_results[package] = (success, output)

        # Preview
        self._show_preview("install", valid_packages, dry_run_results)

        if dry_run:
            self._print_info("Dry-run mode - no changes applied")
            return

        # Confirmation
        if not self._confirm_action("Install symlinks for these packages?"):
            self._print_warning("Operation cancelled")
            return

        # Handle conflicts and create backups
        all_conflicts = []
        for package in valid_packages:
            conflicts = self._check_conflicts(package)
            all_conflicts.extend([c[0] for c in conflicts])

        if all_conflicts:
            self._create_backup(all_conflicts)

        # Execute stow
        print()
        for package in valid_packages:
            # Special handling for sudo packages
            if package in self.config.sudo_packages:
                self._handle_sudo_package(package, "install")
                continue

            cmd = ["stow", "-v", "-R", "-t", str(self.config.target_dir), package]

            try:
                result = subprocess.run(
                    cmd,
                    cwd=str(self.config.dotfiles_dir),
                    capture_output=True,
                    text=True,
                    check=True,
                )
                self._print_success(f"Package '{package}' installed")
                self._log("SUCCESS", f"Package '{package}' installed successfully")

                if self.config.verbose and result.stderr:
                    print(result.stderr)

            except subprocess.CalledProcessError as e:
                self._print_error(f"Error installing '{package}'")
                self._log("ERROR", f"Failed to install '{package}': {e.stderr}")
                if e.stderr:
                    print(e.stderr, file=sys.stderr)

    def uninstall(self, packages: List[str], dry_run: bool = False):
        """Remove symlinks via stow -D"""
        self._log("INFO", f"Starting uninstall operation for: {', '.join(packages)}")

        # Validate packages
        valid_packages = [p for p in packages if self._is_valid_package(p)]
        if not valid_packages:
            return

        # Dry-run for all packages
        self._print_info("Analyzing changes...")
        dry_run_results = {}
        for package in valid_packages:
            success, output = self._dry_run_stow("uninstall", package)
            dry_run_results[package] = (success, output)

        # Preview
        self._show_preview("uninstall", valid_packages, dry_run_results)

        if dry_run:
            self._print_info("Dry-run mode - no changes applied")
            return

        # Confirmation
        if not self._confirm_action("Remove symlinks for these packages?"):
            self._print_warning("Operation cancelled")
            return

        # Execute stow
        print()
        for package in valid_packages:
            # Special handling for sudo packages
            if package in self.config.sudo_packages:
                self._handle_sudo_package(package, "uninstall")
                continue

            cmd = ["stow", "-v", "-D", "-t", str(self.config.target_dir), package]

            try:
                result = subprocess.run(
                    cmd,
                    cwd=str(self.config.dotfiles_dir),
                    capture_output=True,
                    text=True,
                    check=True,
                )
                self._print_success(f"Package '{package}' removed")
                self._log("SUCCESS", f"Package '{package}' uninstalled successfully")

                if self.config.verbose and result.stderr:
                    print(result.stderr)

            except subprocess.CalledProcessError as e:
                self._print_error(f"Error removing '{package}'")
                self._log("ERROR", f"Failed to uninstall '{package}': {e.stderr}")
                if e.stderr:
                    print(e.stderr, file=sys.stderr)

    def restow(self, packages: List[str], dry_run: bool = False):
        """Reinstall symlinks (alias for install)"""
        self._print_info("Restow = reinstall symlinks")
        self.install(packages, dry_run)

    def adopt(self, packages: List[str], git_commit: bool = True):
        """Move existing configs to dotfiles via stow --adopt"""
        self._log("INFO", f"Starting adopt operation for: {', '.join(packages)}")

        # Validate packages
        valid_packages = [p for p in packages if self._is_valid_package(p)]
        if not valid_packages:
            return

        # Check conflicts
        self._print_header("Analyzing existing files")
        total_conflicts = 0

        for package in valid_packages:
            conflicts = self._check_conflicts(package)
            if conflicts:
                total_conflicts += len(conflicts)
                print(f"\n{Colors.CYAN}{package}{Colors.RESET}:")
                for target, dotfile in conflicts:
                    print(f"  {target} -> dotfiles/{package}/...")

        if total_conflicts == 0:
            self._print_warning(
                "No conflicts to adopt. Use 'install' to create symlinks."
            )
            return

        self._print_warning(f"\nTotal files to adopt: {total_conflicts}")
        self._print_warning(
            "WARNING: Files in dotfiles repository will be OVERWRITTEN!"
        )

        # Confirmation
        if not self._confirm_action("Continue with adopt?"):
            self._print_warning("Operation cancelled")
            return

        # Execute stow --adopt
        print()
        for package in valid_packages:
            cmd = ["stow", "-v", "--adopt", "-t", str(self.config.target_dir), package]

            try:
                result = subprocess.run(
                    cmd,
                    cwd=str(self.config.dotfiles_dir),
                    capture_output=True,
                    text=True,
                    check=True,
                )
                self._print_success(f"Package '{package}' adopted")
                self._log("SUCCESS", f"Package '{package}' adopted successfully")

                if self.config.verbose and result.stderr:
                    print(result.stderr)

            except subprocess.CalledProcessError as e:
                self._print_error(f"Error adopting '{package}'")
                self._log("ERROR", f"Failed to adopt '{package}': {e.stderr}")
                if e.stderr:
                    print(e.stderr, file=sys.stderr)

        # Git integration
        if git_commit and self._check_git():
            self._git_show_diff()
            if self._git_prompt_commit(", ".join(valid_packages)):
                self._git_create_commit(", ".join(valid_packages))

    # ========== Special handlers ==========

    def _handle_sudo_package(self, package: str, operation: str):
        """Handle config/ package (logid.cfg -> /etc/)"""
        if package != "config":
            return

        logid_src = self.config.dotfiles_dir / "config" / "logid.cfg"
        logid_dst = Path("/etc/logid.cfg")

        if not logid_src.exists():
            self._print_warning("config/logid.cfg not found")
            return

        if operation == "install":
            self._print_info("Installing config/logid.cfg requires sudo...")

            # Backup existing
            if logid_dst.exists():
                try:
                    subprocess.run(
                        ["sudo", "cp", str(logid_dst), str(logid_dst) + ".backup"],
                        check=True,
                    )
                    self._print_info(f"Backup created: {logid_dst}.backup")
                except subprocess.CalledProcessError:
                    pass

            # Copy with sudo
            try:
                subprocess.run(
                    ["sudo", "cp", str(logid_src), str(logid_dst)], check=True
                )
                subprocess.run(
                    ["sudo", "chown", "root:root", str(logid_dst)], check=True
                )
                self._print_success(f"System config installed: {logid_dst}")
                self._log("SUCCESS", "Sudo package 'config' installed to /etc/")
            except subprocess.CalledProcessError as e:
                self._print_error(f"Error installing system config: {e}")

        elif operation == "uninstall":
            if logid_dst.exists():
                if self._confirm_action(f"Remove {logid_dst}? (requires sudo)"):
                    try:
                        subprocess.run(["sudo", "rm", str(logid_dst)], check=True)
                        self._print_success(f"System config removed: {logid_dst}")
                        self._log(
                            "SUCCESS", "Sudo package 'config' uninstalled from /etc/"
                        )
                    except subprocess.CalledProcessError as e:
                        self._print_error(f"Error removing system config: {e}")

    # ========== Git integration ==========

    def _git_show_diff(self):
        """Show git diff after adopt"""
        self._print_header("Git Diff")
        try:
            subprocess.run(
                ["git", "diff", "--color=always"],
                cwd=str(self.config.dotfiles_dir),
                check=True,
            )
        except subprocess.CalledProcessError:
            pass

    def _git_prompt_commit(self, packages: str) -> bool:
        """Prompt to create commit"""
        print()
        return self._confirm_action("Create git commit with these changes?")

    def _git_create_commit(self, packages: str):
        """Create commit following Conventional Commits"""
        print()
        commit_msg = input("Commit message (or Enter for auto): ").strip()

        if not commit_msg:
            commit_msg = f"chore(dotfiles): adopt {packages} config"

        try:
            # git add -A
            subprocess.run(
                ["git", "add", "-A"], cwd=str(self.config.dotfiles_dir), check=True
            )

            # git commit
            subprocess.run(
                ["git", "commit", "-m", commit_msg],
                cwd=str(self.config.dotfiles_dir),
                check=True,
            )

            self._print_success(f"Commit created: {commit_msg}")
            self._log("SUCCESS", f"Git commit created: {commit_msg}")
        except subprocess.CalledProcessError as e:
            self._print_error(f"Error creating commit: {e}")

    # ========== Status and reports ==========

    def status(self, packages: Optional[List[str]] = None):
        """Check symlink status"""
        if packages is None:
            packages = self.config.all_packages
        else:
            packages = [p for p in packages if self._is_valid_package(p)]

        self._print_header("Package Status")

        for package in packages:
            print(f"\n{Colors.CYAN}{Colors.BOLD}{package}{Colors.RESET}:")
            package_files = self._get_package_files(package)

            if not package_files:
                self._print_warning("  Empty")
                continue

            for rel_path in sorted(package_files):
                target_file = self.config.target_dir / rel_path
                dotfile = self.config.dotfiles_dir / package / rel_path

                if target_file.is_symlink():
                    link_target = target_file.resolve()
                    if link_target == dotfile.resolve():
                        print(f"  {Colors.GREEN}✓{Colors.RESET} {rel_path}")
                    else:
                        print(
                            f"  {Colors.YELLOW}⚠{Colors.RESET} {rel_path} (wrong target)"
                        )
                elif target_file.exists():
                    print(
                        f"  {Colors.RED}✗{Colors.RESET} {rel_path} (file exists, not symlink)"
                    )
                else:
                    print(f"  {Colors.BLUE}○{Colors.RESET} {rel_path} (not installed)")

    def list_packages(self):
        """List available packages"""
        self._print_header("Available Packages")

        packages = [
            d.name
            for d in self.config.dotfiles_dir.iterdir()
            if d.is_dir() and not d.name.startswith(".")
        ]

        for package in sorted(packages):
            if package in self.config.sudo_packages:
                print(f"  {package} {Colors.YELLOW}(requires sudo){Colors.RESET}")
            elif package == "wsl" and not self.is_wsl:
                print(f"  {package} {Colors.BLUE}(WSL only){Colors.RESET}")
            else:
                print(f"  {package}")

        print(f"\nTotal: {len(packages)} packages")

    def check(self, packages: Optional[List[str]] = None):
        """Check symlink integrity"""
        if packages is None:
            packages = self.config.all_packages
        else:
            packages = [p for p in packages if self._is_valid_package(p)]

        self._print_header("Integrity Check")

        broken_links = []

        for package in packages:
            package_files = self._get_package_files(package)

            for rel_path in package_files:
                target_file = self.config.target_dir / rel_path

                if target_file.is_symlink():
                    if not target_file.exists():
                        broken_links.append((package, rel_path, target_file))

        if broken_links:
            self._print_error(f"Found broken symlinks: {len(broken_links)}")
            for package, rel_path, target in broken_links:
                print(f"  {package}/{rel_path} -> {target}")
        else:
            self._print_success("All symlinks are OK!")


def load_config_file(dotfiles_dir: Path) -> Dict:
    """Load configuration from .dotfiles-config.json"""
    config_file = dotfiles_dir / ".dotfiles-config.json"

    # Default configuration if file doesn't exist
    default_config = {
        "default_target": "~",
        "all_packages": [
            "zsh",
            "p10k.zsh",
            "vim",
            "tmux",
            "wezterm",
            "ghostty",
            "kitty",
            "starship",
            "config",
        ],
        "sudo_packages": ["config"],
        "package_targets": {},
    }

    if not config_file.exists():
        return default_config

    try:
        with open(config_file, "r") as f:
            config = json.load(f)
        return config
    except (json.JSONDecodeError, IOError) as e:
        print(f"Warning: Could not load config file: {e}", file=sys.stderr)
        print("Using default configuration", file=sys.stderr)
        return default_config


def create_config(args) -> Config:
    """Create configuration from arguments and config file"""
    dotfiles_dir = Path(__file__).parent.resolve()

    # Load configuration from file
    config_data = load_config_file(dotfiles_dir)

    # Resolve target directory (support ~ expansion)
    default_target = config_data.get("default_target", "~")
    if default_target.startswith("~"):
        target_dir = (
            Path.home() / default_target[2:] if len(default_target) > 1 else Path.home()
        )
    else:
        target_dir = Path(default_target)

    all_packages = config_data.get("all_packages", [])
    sudo_packages = config_data.get("sudo_packages", [])

    return Config(
        dotfiles_dir=dotfiles_dir,
        target_dir=target_dir,
        log_dir=dotfiles_dir / ".logs",
        backup_dir=dotfiles_dir / ".backups",
        all_packages=all_packages,
        sudo_packages=sudo_packages,
        verbose=args.verbose if hasattr(args, "verbose") else False,
    )


def main():
    """Main function - parse arguments and execute commands"""
    parser = argparse.ArgumentParser(
        description="Dotfiles Manager - manage dotfiles with GNU Stow",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s install zsh p10k.zsh kitty
  %(prog)s uninstall --all
  %(prog)s adopt ghostty
  %(prog)s status
  %(prog)s list
        """,
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # install
    install_parser = subparsers.add_parser("install", help="Install symlinks")
    install_parser.add_argument("packages", nargs="*", help="Packages to install")
    install_parser.add_argument("-a", "--all", action="store_true", help="All packages")
    install_parser.add_argument(
        "-n", "--dry-run", action="store_true", help="Simulate only"
    )
    install_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Verbose output"
    )

    # uninstall
    uninstall_parser = subparsers.add_parser("uninstall", help="Remove symlinks")
    uninstall_parser.add_argument("packages", nargs="*", help="Packages to remove")
    uninstall_parser.add_argument(
        "-a", "--all", action="store_true", help="All packages"
    )
    uninstall_parser.add_argument(
        "-n", "--dry-run", action="store_true", help="Simulate only"
    )
    uninstall_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Verbose output"
    )

    # restow
    restow_parser = subparsers.add_parser("restow", help="Reinstall symlinks")
    restow_parser.add_argument("packages", nargs="*", help="Packages to reinstall")
    restow_parser.add_argument("-a", "--all", action="store_true", help="All packages")
    restow_parser.add_argument(
        "-n", "--dry-run", action="store_true", help="Simulate only"
    )
    restow_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Verbose output"
    )

    # adopt
    adopt_parser = subparsers.add_parser("adopt", help="Adopt existing configs")
    adopt_parser.add_argument("packages", nargs="+", help="Packages to adopt")
    adopt_parser.add_argument("--no-git", action="store_true", help="Skip git commit")
    adopt_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Verbose output"
    )

    # status
    status_parser = subparsers.add_parser("status", help="Show status")
    status_parser.add_argument("packages", nargs="*", help="Packages (or all)")
    status_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Verbose output"
    )

    # list
    list_parser = subparsers.add_parser("list", help="List packages")
    list_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Verbose output"
    )

    # check
    check_parser = subparsers.add_parser("check", help="Check integrity")
    check_parser.add_argument("packages", nargs="*", help="Packages (or all)")
    check_parser.add_argument(
        "-v", "--verbose", action="store_true", help="Verbose output"
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    # Create configuration
    config = create_config(args)
    manager = DotfilesManager(config)

    # Check dependencies
    if not manager._check_dependencies():
        sys.exit(1)

    # Execute command
    if args.command == "install":
        packages = config.all_packages if args.all else args.packages
        if not packages:
            print("Specify packages or use --all")
            sys.exit(1)
        manager.install(packages, dry_run=args.dry_run)

    elif args.command == "uninstall":
        packages = config.all_packages if args.all else args.packages
        if not packages:
            print("Specify packages or use --all")
            sys.exit(1)
        manager.uninstall(packages, dry_run=args.dry_run)

    elif args.command == "restow":
        packages = config.all_packages if args.all else args.packages
        if not packages:
            print("Specify packages or use --all")
            sys.exit(1)
        manager.restow(packages, dry_run=args.dry_run)

    elif args.command == "adopt":
        manager.adopt(args.packages, git_commit=not args.no_git)

    elif args.command == "status":
        packages = args.packages if args.packages else None
        manager.status(packages)

    elif args.command == "list":
        manager.list_packages()

    elif args.command == "check":
        packages = args.packages if args.packages else None
        manager.check(packages)


if __name__ == "__main__":
    main()
