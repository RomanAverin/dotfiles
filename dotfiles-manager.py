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


@dataclass
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
    package_targets: Dict[str, str]
    special_files: Dict[str, Dict[str, List[Dict]]]
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

    def check_dependencies(self) -> bool:
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
        # Check if package is a sudo package
        if package in self.config.sudo_packages:
            package_dir = self.config.dotfiles_dir / "sudo_packages" / package
        else:
            package_dir = self.config.dotfiles_dir / package

        if not package_dir.exists() or not package_dir.is_dir():
            self._print_error(
                f"Package '{package}' not found in {self.config.dotfiles_dir}"
            )
            return False
        return True

    def _validate_package_name(self, package_name: str) -> Tuple[bool, str]:
        """
        Validate package name for new package creation.

        Returns:
            (is_valid, error_message)
        """
        # Check for empty name
        if not package_name or not package_name.strip():
            return False, "Package name cannot be empty"

        # Check for invalid characters
        invalid_chars = ["/", "\\", " ", "\t", "\n", ":", "*", "?", '"', "<", ">", "|"]
        for char in invalid_chars:
            if char in package_name:
                return False, f"Package name contains invalid character: '{char}'"

        # Check for reserved names
        reserved_names = [".", "..", ".git", ".logs", ".backups", "sudo_packages"]
        if package_name in reserved_names:
            return False, f"Package name '{package_name}' is reserved"

        # Check for hidden files (starting with .)
        if package_name.startswith("."):
            return False, "Package name cannot start with '.'"

        return True, ""

    def _check_package_exists(self, package_name: str, is_sudo: bool) -> Tuple[bool, str]:
        """
        Check if package already exists (directory or in config).

        Returns:
            (exists, location_info)
        """
        # Check directory existence
        if is_sudo:
            package_dir = self.config.dotfiles_dir / "sudo_packages" / package_name
        else:
            package_dir = self.config.dotfiles_dir / package_name

        if package_dir.exists():
            return True, f"Directory already exists: {package_dir}"

        # Check in all_packages config
        if package_name in self.config.all_packages:
            return True, f"Package '{package_name}' already listed in configuration"

        return False, ""

    def _determine_structure_from_path(self, from_path: Optional[str]) -> Tuple[str, Path]:
        """
        Determine package structure from --from path.

        Returns:
            (structure_type, relative_path_in_package)

        structure_type: "xdg" | "simple" | "sudo"
        """
        if not from_path:
            # Default to XDG if path not specified
            return ("xdg", Path(".config"))

        path = Path(from_path).expanduser()

        # Determine relative path from HOME
        try:
            home = Path.home()
            rel_path = path.relative_to(home)
        except ValueError:
            # Path not relative to HOME (e.g., /etc/)
            return ("sudo", path)

        # Analyze path
        parts = rel_path.parts

        if len(parts) > 0 and parts[0] == ".config":
            # ~/.config/something → XDG structure
            return ("xdg", rel_path)
        else:
            # ~/something → Simple structure
            return ("simple", rel_path)

    def _create_package_structure(
        self, package_name: str, structure_type: str, relative_path: Path, dry_run: bool
    ) -> Tuple[bool, List[Path]]:
        """
        Create directory structure for new package.

        Returns:
            (success, list_of_created_directories)
        """
        created_dirs = []

        try:
            # Determine base directory
            if structure_type == "sudo":
                base_dir = self.config.dotfiles_dir / "sudo_packages" / package_name
            else:
                base_dir = self.config.dotfiles_dir / package_name

            # Determine final directory based on structure type
            if structure_type == "xdg":
                # XDG: package-name/.config/package-name/
                final_dir = base_dir / ".config" / package_name
            elif structure_type == "simple":
                # Simple: package-name/ or package-name/relative_path/
                if relative_path.is_absolute() or len(relative_path.parts) == 0:
                    final_dir = base_dir
                else:
                    # Create parent directory for the relative path
                    # E.g., for ~/.aider -> create package-name/.aider/
                    final_dir = base_dir / relative_path
            elif structure_type == "sudo":
                # Sudo: sudo_packages/package-name/
                final_dir = base_dir
            else:
                self._log("ERROR", f"Unknown structure type: {structure_type}")
                return False, []

            # Create directories
            if not dry_run:
                final_dir.mkdir(parents=True, exist_ok=False)

                # Create .gitkeep for empty directories
                gitkeep = final_dir / ".gitkeep"
                gitkeep.touch()

                self._log("INFO", f"Created package structure: {final_dir}")

            # Collect list of created directories for output
            if structure_type == "xdg":
                created_dirs = [base_dir, base_dir / ".config", final_dir]
            elif structure_type == "simple":
                # Collect all parent directories
                current = final_dir
                while current != base_dir.parent:
                    created_dirs.insert(0, current)
                    current = current.parent
                    if current == self.config.dotfiles_dir:
                        break
            else:  # sudo
                created_dirs = [base_dir]

            return True, created_dirs

        except OSError as e:
            self._log("ERROR", f"Failed to create package structure: {e}")
            return False, []

    def _update_config_file(
        self, package_name: str, is_sudo: bool, custom_target: Optional[str], dry_run: bool
    ) -> bool:
        """
        Update .dotfiles-config.json with new package.

        Returns:
            success
        """
        config_file = self.config.dotfiles_dir / ".dotfiles-config.json"

        try:
            # Create backup
            if not dry_run:
                backup_file = config_file.with_suffix(".json.backup")
                shutil.copy2(config_file, backup_file)
                self._log("INFO", f"Config backup created: {backup_file}")

            # Load current config
            with open(config_file, "r", encoding="utf-8") as f:
                config_data = json.load(f)

            # Add package to all_packages (at the end)
            if package_name not in config_data.get("all_packages", []):
                config_data.setdefault("all_packages", []).append(package_name)

            # Add to sudo_packages if needed
            if is_sudo:
                if package_name not in config_data.get("sudo_packages", []):
                    config_data.setdefault("sudo_packages", []).append(package_name)

            # Add custom target if specified
            if custom_target:
                config_data.setdefault("package_targets", {})[package_name] = custom_target

            # Save with proper formatting
            if not dry_run:
                with open(config_file, "w", encoding="utf-8") as f:
                    json.dump(config_data, f, indent=2, ensure_ascii=False)
                    f.write("\n")  # Add final newline

                self._log("INFO", f"Updated config: {config_file}")

            return True

        except (json.JSONDecodeError, IOError) as e:
            self._log("ERROR", f"Failed to update config: {e}")
            self._print_error(f"Failed to update configuration: {e}")
            return False

    def _get_package_metadata(self, package_name: str) -> Dict[str, Any]:
        """
        Get comprehensive metadata about a package.

        Args:
            package_name: Name of the package

        Returns:
            Dictionary with package metadata:
            - exists_in_config: bool
            - exists_as_directory: bool
            - is_sudo: bool
            - has_custom_target: bool
            - has_special_files: bool
            - directory_path: Optional[Path]
            - sudo_directory_path: Optional[Path]
            - target: str
        """
        metadata = {
            "exists_in_config": False,
            "exists_as_directory": False,
            "is_sudo": False,
            "has_custom_target": False,
            "has_special_files": False,
            "directory_path": None,
            "sudo_directory_path": None,
            "target": str(self.config.target_dir),
        }

        # Check if package exists in configuration
        if package_name in self.config.all_packages:
            metadata["exists_in_config"] = True

        # Check if it's a sudo package
        if package_name in self.config.sudo_packages:
            metadata["is_sudo"] = True

        # Check if it has custom target
        if package_name in self.config.package_targets:
            metadata["has_custom_target"] = True
            metadata["target"] = self.config.package_targets[package_name]

        # Check if it has special files
        if package_name in self.config.special_files:
            metadata["has_special_files"] = True

        # Check if package directory exists
        package_dir = self.config.dotfiles_dir / package_name
        if package_dir.exists() and package_dir.is_dir():
            metadata["exists_as_directory"] = True
            metadata["directory_path"] = package_dir

        # Check if sudo package directory exists
        sudo_dir = self.config.dotfiles_dir / "sudo_packages" / package_name
        if sudo_dir.exists() and sudo_dir.is_dir():
            metadata["exists_as_directory"] = True
            metadata["sudo_directory_path"] = sudo_dir
            metadata["is_sudo"] = True

        return metadata

    def _verify_symlinks_removed(self, package_name: str) -> Tuple[bool, List[Path]]:
        """
        Verify that all symlinks for a package have been removed.

        Args:
            package_name: Name of the package

        Returns:
            Tuple of (all_removed, list_of_remaining_symlinks)
        """
        remaining_symlinks = []
        target = Path(self.config.package_targets.get(package_name, str(self.config.target_dir))).expanduser()

        # Get package directory
        package_dir = self.config.dotfiles_dir / package_name
        sudo_dir = self.config.dotfiles_dir / "sudo_packages" / package_name

        # Determine which directory to check
        if sudo_dir.exists():
            check_dir = sudo_dir
        elif package_dir.exists():
            check_dir = package_dir
        else:
            # No package directory exists, consider all removed
            return (True, [])

        # Walk through package directory and check for corresponding symlinks in target
        for root, dirs, files in os.walk(check_dir):
            rel_root = Path(root).relative_to(check_dir)

            for file in files:
                # Skip .gitkeep and other meta files
                if file == ".gitkeep":
                    continue

                # Calculate target file path
                file_rel_path = rel_root / file
                target_file = target / file_rel_path

                # Check if symlink still exists
                if target_file.exists() or target_file.is_symlink():
                    if target_file.is_symlink():
                        # Check if it points to our package
                        try:
                            link_target = target_file.resolve(strict=False)
                            package_file = check_dir / file_rel_path
                            if link_target == package_file.resolve(strict=False):
                                remaining_symlinks.append(target_file)
                        except (OSError, RuntimeError):
                            # If we can't resolve, assume it's not our symlink
                            pass

        all_removed = len(remaining_symlinks) == 0
        return (all_removed, remaining_symlinks)

    def _create_package_backup(
        self, package_name: str, is_sudo: bool, dry_run: bool
    ) -> Tuple[bool, Optional[Path]]:
        """
        Create a backup of the entire package directory.

        Args:
            package_name: Name of the package
            is_sudo: Whether this is a sudo package
            dry_run: If True, simulate only

        Returns:
            Tuple of (success, backup_path)
        """
        # Determine source directory
        if is_sudo:
            source_dir = self.config.dotfiles_dir / "sudo_packages" / package_name
        else:
            source_dir = self.config.dotfiles_dir / package_name

        if not source_dir.exists():
            self._log("WARNING", f"Package directory does not exist: {source_dir}")
            return (True, None)  # Nothing to backup

        # Create backup directory with timestamp
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_base = self.config.dotfiles_dir / ".backups" / f"delete-{timestamp}"
        backup_path = backup_base / package_name

        try:
            if dry_run:
                self._print_info(f"Would create backup at: {backup_path}")
                return (True, backup_path)

            # Create backup directory
            backup_base.mkdir(parents=True, exist_ok=True)

            # Copy entire package directory
            shutil.copytree(source_dir, backup_path)

            self._log("INFO", f"Created backup: {backup_path}")
            return (True, backup_path)

        except (OSError, shutil.Error) as e:
            self._log("ERROR", f"Failed to create backup: {e}")
            return (False, None)

    def _remove_from_config(
        self, package_name: str, metadata: Dict[str, Any], dry_run: bool
    ) -> bool:
        """
        Remove package from .dotfiles-config.json.
        Reverse operation of _update_config_file().

        Args:
            package_name: Name of the package
            metadata: Package metadata from _get_package_metadata()
            dry_run: If True, simulate only

        Returns:
            success
        """
        config_file = self.config.dotfiles_dir / ".dotfiles-config.json"

        try:
            # Create backup
            if not dry_run:
                backup_file = config_file.with_suffix(".json.backup")
                shutil.copy2(config_file, backup_file)
                self._log("INFO", f"Config backup created: {backup_file}")

            # Load current config
            with open(config_file, "r", encoding="utf-8") as f:
                config_data = json.load(f)

            # Remove from all_packages
            if package_name in config_data.get("all_packages", []):
                config_data["all_packages"].remove(package_name)

            # Remove from sudo_packages
            if package_name in config_data.get("sudo_packages", []):
                config_data["sudo_packages"].remove(package_name)

            # Remove from package_targets
            if package_name in config_data.get("package_targets", {}):
                del config_data["package_targets"][package_name]

            # Remove from special_files
            if package_name in config_data.get("special_files", {}):
                del config_data["special_files"][package_name]

            # Save with proper formatting
            if not dry_run:
                with open(config_file, "w", encoding="utf-8") as f:
                    json.dump(config_data, f, indent=2, ensure_ascii=False)
                    f.write("\n")  # Add final newline

                self._log("INFO", f"Updated config: {config_file}")

            return True

        except (json.JSONDecodeError, IOError) as e:
            self._log("ERROR", f"Failed to update config: {e}")
            self._print_error(f"Failed to update configuration: {e}")
            return False

    def _check_wsl(self) -> bool:
        """Detect WSL environment"""
        try:
            with open("/proc/version", "r", encoding="utf-8") as f:
                return "microsoft" in f.read().lower()
        except FileNotFoundError:
            return False

    def _parse_package_spec(self, package_spec: str) -> Tuple[str, Optional[str]]:
        """
        Parse package specification in format 'package:file' or just 'package'.

        Returns:
            (package_name, specific_file or None)

        Examples:
            'etc:logid.cfg' -> ('etc', 'logid.cfg')
            'etc' -> ('etc', None)
        """
        if ":" in package_spec:
            parts = package_spec.split(":", 1)
            return (parts[0], parts[1])
        return (package_spec, None)

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
        # Check if package is a sudo package
        if package in self.config.sudo_packages:
            package_dir = self.config.dotfiles_dir / "sudo_packages" / package
        else:
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
                    for target in conflicts[:3]:  # Show first 3
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

        # Parse package specifications (format: package or package:file)
        package_specs = {}  # {package_name: specific_file or None}
        for pkg_spec in packages:
            pkg_name, specific_file = self._parse_package_spec(pkg_spec)
            package_specs[pkg_name] = specific_file

        # Validate packages
        valid_packages = [p for p in package_specs if self._is_valid_package(p)]
        if not valid_packages:
            return

        # Dry-run for all packages (except sudo packages)
        self._print_info("Analyzing changes...")
        dry_run_results = {}
        for package in valid_packages:
            # Sudo packages don't use stow, skip dry-run
            if package in self.config.sudo_packages:
                dry_run_results[package] = (True, "sudo package - no stow dry-run")
            else:
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
                specific_file = package_specs.get(package)
                self._handle_sudo_package(package, "install", specific_file)
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

        # Parse package specifications (format: package or package:file)
        package_specs = {}  # {package_name: specific_file or None}
        for pkg_spec in packages:
            pkg_name, specific_file = self._parse_package_spec(pkg_spec)
            package_specs[pkg_name] = specific_file

        # Validate packages
        valid_packages = [p for p in package_specs if self._is_valid_package(p)]
        if not valid_packages:
            return

        # Dry-run for all packages (except sudo packages)
        self._print_info("Analyzing changes...")
        dry_run_results = {}
        for package in valid_packages:
            # Sudo packages don't use stow, skip dry-run
            if package in self.config.sudo_packages:
                dry_run_results[package] = (True, "sudo package - no stow dry-run")
            else:
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
                specific_file = package_specs.get(package)
                self._handle_sudo_package(package, "uninstall", specific_file)
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
                for target in conflicts:
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

    def _handle_sudo_package(
        self, package: str, operation: str, specific_file: Optional[str] = None
    ):
        """
        Handle packages with special files requiring sudo or custom installation.

        Reads configuration from special_files section in .dotfiles-config.json.

        Args:
            package: Package name from sudo_packages list
            operation: "install" or "uninstall"
            specific_file: If provided, process only this file (e.g., 'logid.cfg')
        """
        # Check if package has special_files configuration
        if package not in self.config.special_files:
            self._print_warning(
                f"Package '{package}' not found in special_files configuration"
            )
            return

        # Get list of files to process
        package_config = self.config.special_files[package]
        files_to_process = package_config.get("files", [])

        # Filter by specific file if provided
        if specific_file:
            files_to_process = [
                f for f in files_to_process if f.get("src") == specific_file
            ]

            if not files_to_process:
                self._print_error(
                    f"File '{specific_file}' not found in package '{package}' configuration"
                )
                return

        if not files_to_process:
            self._print_warning(f"No files configured for package '{package}'")
            return

        # Process each file in the package
        for file_config in files_to_process:
            src_relative = file_config.get("src")
            dst_absolute = file_config.get("dst")
            requires_sudo = file_config.get("sudo", False)

            # Validate configuration
            if not src_relative or not dst_absolute:
                self._print_error(
                    f"Invalid file configuration in package '{package}': {file_config}"
                )
                continue

            # Build absolute paths
            # Sudo packages are stored in sudo_packages/{package}/
            src_path = self.config.dotfiles_dir / "sudo_packages" / package / src_relative
            dst_path = Path(dst_absolute)

            # Check if source file exists
            if not src_path.exists():
                self._print_error(f"Source file not found: {src_path}")
                continue

            # Execute operation
            if operation == "install":
                self._install_special_file(src_path, dst_path, requires_sudo, package)
            elif operation == "uninstall":
                self._uninstall_special_file(dst_path, requires_sudo, package)

    def _install_special_file(
        self, src: Path, dst: Path, use_sudo: bool, package: str
    ):
        """Install a single special file with optional sudo"""

        self._print_info(f"Installing {src.name} → {dst} (sudo={use_sudo})")

        # Backup existing file
        if dst.exists():
            backup_path = Path(str(dst) + ".backup")
            try:
                if use_sudo:
                    subprocess.run(
                        ["sudo", "cp", str(dst), str(backup_path)],
                        check=True,
                        capture_output=True,
                    )
                else:
                    shutil.copy2(dst, backup_path)
                self._print_info(f"Backup created: {backup_path}")
            except (subprocess.CalledProcessError, IOError) as e:
                self._print_warning(f"Could not create backup: {e}")

        # Copy file
        try:
            if use_sudo:
                subprocess.run(
                    ["sudo", "cp", str(src), str(dst)],
                    check=True,
                    capture_output=True,
                )
                # Set root:root ownership for system files
                subprocess.run(
                    ["sudo", "chown", "root:root", str(dst)],
                    check=True,
                    capture_output=True,
                )
                self._print_success(f"System file installed: {dst}")
                self._log("SUCCESS", f"Sudo package '{package}' installed: {src} → {dst}")
            else:
                shutil.copy2(src, dst)
                self._print_success(f"File installed: {dst}")
                self._log("SUCCESS", f"Package '{package}' installed: {src} → {dst}")

        except (subprocess.CalledProcessError, IOError) as e:
            self._print_error(f"Error installing {dst}: {e}")
            self._log("ERROR", f"Failed to install '{package}': {e}")

    def _uninstall_special_file(
        self, dst: Path, use_sudo: bool, package: str
    ):
        """Uninstall a single special file with optional sudo"""

        if not dst.exists():
            self._print_info(f"File not found (already removed): {dst}")
            return

        # Confirmation prompt
        prompt = f"Remove {dst}?"
        if use_sudo:
            prompt += " (requires sudo)"

        if not self._confirm_action(prompt):
            self._print_warning(f"Skipped: {dst}")
            return

        # Remove file
        try:
            if use_sudo:
                subprocess.run(
                    ["sudo", "rm", str(dst)], check=True, capture_output=True
                )
                self._print_success(f"System file removed: {dst}")
                self._log("SUCCESS", f"Sudo package '{package}' uninstalled: {dst}")
            else:
                dst.unlink()
                self._print_success(f"File removed: {dst}")
                self._log("SUCCESS", f"Package '{package}' uninstalled: {dst}")

        except (subprocess.CalledProcessError, OSError) as e:
            self._print_error(f"Error removing {dst}: {e}")
            self._log("ERROR", f"Failed to uninstall '{package}': {e}")

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

    def _git_prompt_commit(self, _packages: str) -> bool:
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

            # For sudo packages use special_files
            if package in self.config.sudo_packages:
                if package not in self.config.special_files:
                    self._print_warning("  No configuration in special_files")
                    continue

                package_config = self.config.special_files[package]
                files_list = package_config.get("files", [])

                if not files_list:
                    self._print_warning("  Empty")
                    continue

                for file_entry in files_list:
                    src_file = file_entry.get("src", "")
                    dst_file = file_entry.get("dst", "")

                    if not src_file or not dst_file:
                        continue

                    target_file = Path(dst_file)

                    if target_file.exists():
                        print(f"  {Colors.GREEN}✓{Colors.RESET} {src_file} → {dst_file}")
                    else:
                        print(f"  {Colors.BLUE}○{Colors.RESET} {src_file} (not installed)")
            else:
                # Regular packages
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

        # Use all_packages from configuration instead of scanning
        packages = self.config.all_packages

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

    def new(
        self,
        package_name: str,
        from_path: Optional[str] = None,
        is_sudo: bool = False,
        custom_target: Optional[str] = None,
        dry_run: bool = False,
    ):
        """
        Create new package with directory structure and update configuration.

        Args:
            package_name: Name of the new package
            from_path: Path to existing config (determines structure automatically)
            is_sudo: Mark package as requiring sudo
            custom_target: Custom target directory for this package
            dry_run: Simulate without making changes
        """
        self._log("INFO", f"Starting new package creation: {package_name}")

        # ========== 1. Validate package name ==========
        self._print_info("Validating package name...")
        is_valid, error_msg = self._validate_package_name(package_name)
        if not is_valid:
            self._print_error(f"Invalid package name: {error_msg}")
            return

        # ========== 2. Check if package already exists ==========
        self._print_info("Checking if package already exists...")
        exists, location = self._check_package_exists(package_name, is_sudo)
        if exists:
            self._print_error(f"Package already exists: {location}")
            return

        # ========== 3. Determine structure from path ==========
        structure_type, relative_path = self._determine_structure_from_path(from_path)

        # Override for sudo if explicitly specified
        if is_sudo:
            structure_type = "sudo"

        # ========== 4. Show preview ==========
        self._print_header("New Package Preview")

        print(f"Package name: {Colors.CYAN}{package_name}{Colors.RESET}")

        if from_path:
            print(f"Source:       {from_path}")

        # Determine structure description for display
        if structure_type == "sudo":
            print(f"Package type: {Colors.YELLOW}sudo package{Colors.RESET}")
            structure_display = f"sudo_packages/{package_name}/"
        elif structure_type == "simple":
            print(f"Package type: {Colors.BLUE}simple{Colors.RESET}")
            if relative_path.parts:
                structure_display = f"{package_name}/{relative_path}/"
            else:
                structure_display = f"{package_name}/"
        else:  # xdg
            print(f"Package type: {Colors.BLUE}XDG{Colors.RESET}")
            structure_display = f"{package_name}/.config/{package_name}/"

        print(f"Structure:    {structure_display}")

        if custom_target:
            print(f"Target:       {custom_target}")

        print(f"\n{Colors.BOLD}Configuration changes:{Colors.RESET}")
        print(f"  • Add '{package_name}' to all_packages")
        if is_sudo or structure_type == "sudo":
            print(f"  • Add '{package_name}' to sudo_packages")
        if custom_target:
            print(f"  • Set custom target: {custom_target}")

        # ========== 5. Dry-run mode ==========
        if dry_run:
            self._print_info("Dry-run mode - no changes will be made")
            self._print_success("Validation passed! Run without --dry-run to create.")
            return

        # ========== 6. Confirmation ==========
        if not self._confirm_action("Create this package?"):
            self._print_warning("Operation cancelled")
            return

        # ========== 7. Create structure ==========
        print()
        self._print_info("Creating directory structure...")
        success, created_dirs = self._create_package_structure(
            package_name, structure_type, relative_path, dry_run=False
        )

        if not success:
            self._print_error("Failed to create package structure")
            return

        for dir_path in created_dirs:
            self._print_success(f"Created: {dir_path}")

        # ========== 8. Update config ==========
        self._print_info("Updating configuration...")
        if not self._update_config_file(package_name, is_sudo or structure_type == "sudo", custom_target, dry_run=False):
            # Rollback: remove created directories
            self._print_warning("Rolling back changes...")
            try:
                if structure_type == "sudo":
                    base_dir = self.config.dotfiles_dir / "sudo_packages" / package_name
                else:
                    base_dir = self.config.dotfiles_dir / package_name

                if base_dir.exists():
                    shutil.rmtree(base_dir)
                    self._print_info(f"Removed: {base_dir}")
            except OSError as e:
                self._print_error(f"Failed to rollback: {e}")
            return

        self._print_success("Configuration updated")

        # ========== 9. Automatic adopt if from_path specified and exists ==========
        adopted = False
        if from_path:
            from_full_path = Path(from_path).expanduser()
            if from_full_path.exists():
                print()
                self._print_info(f"Adopting files from {from_path}...")
                try:
                    self.adopt([package_name], git_commit=False)
                    adopted = True
                except Exception as e:
                    self._print_warning(f"Adopt failed: {e}")
                    self._print_info("You can run adopt manually later")
            else:
                self._print_warning(f"Path does not exist: {from_path}")
                self._print_info("Package structure created, but no files adopted")

        # ========== 10. Success message and next steps ==========
        print()
        if adopted:
            self._print_header("Package Created and Adopted Successfully!")
            print(f"\n{Colors.GREEN}✓{Colors.RESET} Files moved from {from_path} to dotfiles/{package_name}/")
            print(f"{Colors.GREEN}✓{Colors.RESET} Symlinks created")
            print(f"\n{Colors.BOLD}Next steps:{Colors.RESET}")
            print(f"1. Review changes: git diff")
            print(f'2. Commit: git add . && git commit -m "feat(dotfiles): add {package_name} config"')
        else:
            self._print_header("Package Created Successfully!")

            if structure_type == "sudo":
                base_dir = self.config.dotfiles_dir / "sudo_packages" / package_name
            else:
                base_dir = self.config.dotfiles_dir / package_name

            print(f"\n{Colors.BOLD}Next steps:{Colors.RESET}")
            print()
            print(f"If you have existing configs:")
            print(f"   ./dotfiles-manager.py adopt {package_name}")
            print()
            print(f"Or add files manually:")
            print(f"   1. Copy your configuration to: {base_dir}/")
            if structure_type == "xdg":
                print(f"      (XDG structure: {base_dir}/.config/{package_name}/)")
            print(f"   2. Install: ./dotfiles-manager.py install {package_name}")

            if structure_type == "sudo":
                print(f"\n{Colors.YELLOW}Note:{Colors.RESET} This is a sudo package.")
                print(f"   Configure file mappings in .dotfiles-config.json")
                print(f"   under 'special_files' -> '{package_name}'")

        print()
        self._log("SUCCESS", f"Package '{package_name}' created successfully")

    def delete(
        self,
        packages: List[str],
        force: bool = False,
        dry_run: bool = False,
        keep_files: bool = False,
        no_backup: bool = False,
    ):
        """
        Delete packages completely from dotfiles.

        Args:
            packages: List of package names to delete
            force: Skip confirmation prompt
            dry_run: Simulate without making changes
            keep_files: Keep package files, only remove from configuration
            no_backup: Do not create backup before deleting
        """
        self._print_header("DELETE PACKAGES")

        for package_name in packages:
            # Step 1: Get package metadata
            metadata = self._get_package_metadata(package_name)

            # Check if package exists at all
            if not metadata["exists_in_config"] and not metadata["exists_as_directory"]:
                self._print_error(f"Package '{package_name}' does not exist")
                self._print_info("  Not found in configuration or as directory")
                continue

            # Step 2: Show preview
            self._print_header(f"Delete Package Preview: {package_name}")
            print()

            # Show location
            if metadata["exists_as_directory"]:
                if metadata["sudo_directory_path"]:
                    location = f"sudo_packages/{package_name}/"
                else:
                    location = f"{package_name}/"
                print(f"Location:  {location}")
            else:
                print(f"Location:  {Colors.YELLOW}(directory not found){Colors.RESET}")

            # Show config status
            if metadata["exists_in_config"]:
                config_sections = ["all_packages"]
                if metadata["is_sudo"]:
                    config_sections.append("sudo_packages")
                if metadata["has_custom_target"]:
                    config_sections.append("package_targets")
                if metadata["has_special_files"]:
                    config_sections.append("special_files")
                print(f"In config: {Colors.GREEN}Yes{Colors.RESET} ({', '.join(config_sections)})")
            else:
                print(f"In config: {Colors.YELLOW}No{Colors.RESET}")

            print()

            # Show warnings for edge cases
            if metadata["exists_in_config"] and not metadata["exists_as_directory"]:
                self._print_warning(
                    "Package directory does not exist, will only remove from configuration"
                )
                print()
            elif metadata["exists_as_directory"] and not metadata["exists_in_config"]:
                self._print_warning(
                    "Package not in configuration, will only remove directory"
                )
                print()

            # Show actions
            print(f"{Colors.CYAN}Actions:{Colors.RESET}")

            if metadata["exists_as_directory"]:
                print(f"  • Uninstall symlinks from {metadata['target']}")

            if metadata["exists_as_directory"] and not no_backup and not keep_files:
                timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
                backup_path = f".backups/delete-{timestamp}/{package_name}/"
                print(f"  • Backup to: {backup_path}")

            if metadata["exists_as_directory"] and not keep_files:
                if metadata["sudo_directory_path"]:
                    print(f"  • Remove directory: sudo_packages/{package_name}/")
                else:
                    print(f"  • Remove directory: {package_name}/")

            if metadata["exists_in_config"]:
                print(f"  • Remove from configuration:")
                if package_name in self.config.all_packages:
                    print(f"    - all_packages")
                if metadata["is_sudo"]:
                    print(f"    - sudo_packages")
                if metadata["has_custom_target"]:
                    print(f"    - package_targets")
                if metadata["has_special_files"]:
                    print(f"    - special_files")

            print()
            self._print_warning(
                "This action cannot be undone (except via backup restore)"
            )
            print()

            # Step 3: Dry-run check
            if dry_run:
                self._print_success(f"Dry-run: Would delete package '{package_name}'")
                continue

            # Step 4: Confirmation
            if not force:
                print(
                    f"{Colors.YELLOW}To confirm deletion, type the package name:{Colors.RESET} {package_name}"
                )
                try:
                    confirmation = input("> ").strip()
                    if confirmation != package_name:
                        self._print_warning("Confirmation failed. Package not deleted.")
                        continue
                    print(f"{Colors.GREEN}✓ Confirmed{Colors.RESET}")
                    print()
                except (KeyboardInterrupt, EOFError):
                    print()
                    self._print_warning("Operation cancelled by user")
                    continue

            # Step 5: Uninstall symlinks (if directory exists)
            if metadata["exists_as_directory"]:
                self._print_info(f"Uninstalling symlinks for '{package_name}'...")
                try:
                    # Call uninstall, but don't fail if there are no symlinks
                    self.uninstall([package_name], dry_run=False)
                except Exception as e:
                    self._log("WARNING", f"Uninstall had errors: {e}")
                    # Continue anyway

                # Step 6: Verify symlinks removed
                all_removed, remaining = self._verify_symlinks_removed(package_name)
                if not all_removed:
                    self._print_warning("Some symlinks could not be removed:")
                    for symlink in remaining:
                        print(f"  {symlink}")
                    print()
                    print("This may happen if:")
                    print("  - Files were modified manually")
                    print("  - Permission issues")
                    print("  - Stow encountered an error")
                    print()
                    print(
                        "Continue with deletion? This will remove the package from dotfiles,"
                    )
                    print("but symlinks will remain pointing to non-existent files.")

                    try:
                        continue_anyway = input("[y/N]: ").strip().lower()
                        if continue_anyway != "y":
                            self._print_warning(
                                f"Deletion of '{package_name}' cancelled"
                            )
                            continue
                    except (KeyboardInterrupt, EOFError):
                        print()
                        self._print_warning("Operation cancelled by user")
                        continue

            # Step 7: Create backup
            backup_path = None
            if metadata["exists_as_directory"] and not no_backup and not keep_files:
                self._print_info("Creating backup...")
                success, backup_path = self._create_package_backup(
                    package_name, metadata["is_sudo"], dry_run=False
                )

                if not success:
                    self._print_error("Failed to create backup")
                    print()
                    print("Continue deletion WITHOUT backup?")

                    try:
                        continue_anyway = input("[y/N]: ").strip().lower()
                        if continue_anyway != "y":
                            self._print_warning(
                                f"Deletion of '{package_name}' cancelled"
                            )
                            continue
                    except (KeyboardInterrupt, EOFError):
                        print()
                        self._print_warning("Operation cancelled by user")
                        continue

            # Step 8: Remove directory
            if metadata["exists_as_directory"] and not keep_files:
                self._print_info("Removing package directory...")

                if metadata["sudo_directory_path"]:
                    dir_to_remove = metadata["sudo_directory_path"]
                else:
                    dir_to_remove = metadata["directory_path"]

                try:
                    shutil.rmtree(dir_to_remove)
                    self._log("INFO", f"Removed directory: {dir_to_remove}")
                except (OSError, shutil.Error) as e:
                    self._log("ERROR", f"Failed to remove directory: {e}")
                    self._print_error(f"Failed to remove directory: {e}")
                    # Don't continue if we can't remove the directory
                    continue

            # Step 9: Remove from config
            if metadata["exists_in_config"]:
                self._print_info("Updating configuration...")
                success = self._remove_from_config(package_name, metadata, dry_run=False)

                if not success:
                    self._print_error("Failed to update configuration file")
                    print()

                    if backup_path:
                        print(f"Package directory has been removed and backed up to:")
                        print(f"  {backup_path}")
                        print()

                    print(f"{Colors.YELLOW}MANUAL ACTION REQUIRED:{Colors.RESET}")
                    print("1. Check .dotfiles-config.json permissions")
                    print(f"2. Manually remove '{package_name}' from .dotfiles-config.json")
                    print("3. Or restore from backup: .dotfiles-config.json.backup")
                    continue

            # Step 10: Success message
            print()
            self._print_header("Package Deleted Successfully!")
            print()

            if metadata["exists_as_directory"]:
                self._print_success(f"Symlinks removed from {metadata['target']}")

            if backup_path:
                self._print_success(f"Backup created: {backup_path}")

            if metadata["exists_as_directory"] and not keep_files:
                if metadata["sudo_directory_path"]:
                    self._print_success(f"Directory removed: sudo_packages/{package_name}/")
                else:
                    self._print_success(f"Directory removed: {package_name}/")

            if metadata["exists_in_config"]:
                self._print_success("Configuration updated")

            # Show restore instructions if backup was created
            if backup_path:
                print()
                print(f"{Colors.CYAN}To restore this package:{Colors.RESET}")
                if metadata["sudo_directory_path"]:
                    print(
                        f"1. Copy from backup: cp -r {backup_path} sudo_packages/"
                    )
                else:
                    print(f"1. Copy from backup: cp -r {backup_path} .")
                print(f"2. Manually add '{package_name}' back to .dotfiles-config.json")
                print(f"3. Install: ./dotfiles-manager.py install {package_name}")

            print()
            self._log("SUCCESS", f"Package '{package_name}' deleted successfully")


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
            "etc",
        ],
        "sudo_packages": ["etc"],
        "package_targets": {},
        "special_files": {},
    }

    if not config_file.exists():
        return default_config

    try:
        with open(config_file, "r", encoding="utf-8") as f:
            config = json.load(f)

        # Validate special_files
        if "special_files" in config:
            for pkg_name, pkg_config in config["special_files"].items():
                if "files" not in pkg_config:
                    print(
                        f"Warning: Package '{pkg_name}' in special_files has no 'files' key",
                        file=sys.stderr,
                    )
                else:
                    for file_entry in pkg_config["files"]:
                        if "src" not in file_entry or "dst" not in file_entry:
                            print(
                                f"Warning: Invalid file entry in '{pkg_name}': {file_entry}",
                                file=sys.stderr,
                            )

        return config
    except (json.JSONDecodeError, IOError) as e:
        print(f"Warning: Could not load config file: {e}", file=sys.stderr)
        print("Using default configuration", file=sys.stderr)
        return default_config


def create_config(args) -> Config:
    """Create configuration from arguments and configuration file"""
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
    package_targets = config_data.get("package_targets", {})
    special_files = config_data.get("special_files", {})

    return Config(
        dotfiles_dir=dotfiles_dir,
        target_dir=target_dir,
        log_dir=dotfiles_dir / ".logs",
        backup_dir=dotfiles_dir / ".backups",
        all_packages=all_packages,
        sudo_packages=sudo_packages,
        package_targets=package_targets,
        special_files=special_files,
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

    # new
    new_parser = subparsers.add_parser(
        "new",
        help="Create new package",
        description="Create a new package with automatic structure detection and optional adopt"
    )
    new_parser.add_argument(
        "package_name",
        help="Name of the new package"
    )
    new_parser.add_argument(
        "--from",
        dest="from_path",
        metavar="PATH",
        help="Path to existing config (e.g., ~/.aider or ~/.config/alacritty). Automatically determines structure and adopts files."
    )
    new_parser.add_argument(
        "--sudo",
        action="store_true",
        help="Mark package as requiring sudo (for system files in /etc/)"
    )
    new_parser.add_argument(
        "--target",
        metavar="PATH",
        help="Custom target directory where symlinks will be installed (default: ~)"
    )
    new_parser.add_argument(
        "-n", "--dry-run",
        action="store_true",
        help="Simulate without making changes"
    )
    new_parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Verbose output"
    )

    # delete
    delete_parser = subparsers.add_parser(
        "delete",
        help="Delete package completely",
        description="Remove package from dotfiles (symlinks + directory + configuration)"
    )
    delete_parser.add_argument(
        "packages",
        nargs="+",
        help="Names of packages to delete"
    )
    delete_parser.add_argument(
        "-f", "--force",
        action="store_true",
        help="Skip confirmation prompt"
    )
    delete_parser.add_argument(
        "-n", "--dry-run",
        action="store_true",
        help="Simulate without making changes"
    )
    delete_parser.add_argument(
        "--keep-files",
        action="store_true",
        help="Keep package files, only remove from configuration"
    )
    delete_parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Do not create backup before deleting"
    )
    delete_parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Verbose output"
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    # Create configuration
    config = create_config(args)
    manager = DotfilesManager(config)

    # Check dependencies
    if not manager.check_dependencies():
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

    elif args.command == "new":
        manager.new(
            package_name=args.package_name,
            from_path=args.from_path,
            is_sudo=args.sudo,
            custom_target=args.target,
            dry_run=args.dry_run
        )

    elif args.command == "delete":
        manager.delete(
            packages=args.packages,
            force=args.force,
            dry_run=args.dry_run,
            keep_files=args.keep_files,
            no_backup=args.no_backup
        )


if __name__ == "__main__":
    main()
