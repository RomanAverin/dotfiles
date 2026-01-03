"""Shared fixtures for all tests"""
import pytest
import json
from pathlib import Path
from unittest.mock import Mock, patch

import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

# Import classes from dotfiles-manager.py
# Since the file is named dotfiles-manager.py (with hyphen), use importlib
import importlib.util
spec = importlib.util.spec_from_file_location(
    "dotfiles_manager",
    Path(__file__).parent.parent / "dotfiles-manager.py"
)
dotfiles_manager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dotfiles_manager)

Config = dotfiles_manager.Config
DotfilesManager = dotfiles_manager.DotfilesManager


# ========== Temporary Directories ==========

@pytest.fixture
def dotfiles_dir(tmp_path):
    """Temporary dotfiles directory"""
    dotfiles = tmp_path / "dotfiles"
    dotfiles.mkdir()
    (dotfiles / ".logs").mkdir()
    (dotfiles / ".backups").mkdir()
    (dotfiles / "sudo_packages").mkdir()
    return dotfiles


@pytest.fixture
def target_dir(tmp_path):
    """Temporary target directory (emulates ~)"""
    target = tmp_path / "home"
    target.mkdir()
    return target


@pytest.fixture
def config_file(dotfiles_dir):
    """Creates .dotfiles-config.json"""
    config_path = dotfiles_dir / ".dotfiles-config.json"
    default_config = {
        "default_target": "~",
        "all_packages": ["zsh", "vim", "test-package"],
        "sudo_packages": ["etc"],
        "package_targets": {},
        "special_files": {
            "etc": {
                "files": [{"src": "test.cfg", "dst": "/etc/test.cfg", "sudo": True}]
            }
        }
    }
    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(default_config, f, indent=2)
    return config_path


# ========== Configurations ==========

@pytest.fixture
def basic_config(dotfiles_dir, target_dir):
    """Basic configuration"""
    return Config(
        dotfiles_dir=dotfiles_dir,
        target_dir=target_dir,
        log_dir=dotfiles_dir / ".logs",
        backup_dir=dotfiles_dir / ".backups",
        all_packages=["zsh", "vim", "test-package"],
        sudo_packages=["etc"],
        package_targets={},
        special_files={},
        verbose=False
    )


@pytest.fixture
def manager(basic_config):
    """DotfilesManager instance"""
    return DotfilesManager(basic_config)


# ========== Mocks ==========

@pytest.fixture
def mock_subprocess_success():
    """Mock for successful subprocess"""
    mock_result = Mock()
    mock_result.returncode = 0
    mock_result.stdout = "Success"
    mock_result.stderr = ""
    with patch('subprocess.run', return_value=mock_result) as mock:
        yield mock


@pytest.fixture
def mock_subprocess_failure():
    """Mock for failed subprocess"""
    from subprocess import CalledProcessError
    with patch('subprocess.run', side_effect=CalledProcessError(
        returncode=1, cmd=['stow'], stderr="Error"
    )) as mock:
        yield mock


@pytest.fixture
def mock_user_input():
    """Mock for input()"""
    with patch('builtins.input') as mock:
        yield mock


# ========== Test Packages ==========

@pytest.fixture
def sample_package_simple(dotfiles_dir):
    """Simple package (test-package/.vimrc)"""
    package_dir = dotfiles_dir / "test-package"
    package_dir.mkdir()
    (package_dir / ".vimrc").write_text("set number\n")
    return package_dir


@pytest.fixture
def sample_package_xdg(dotfiles_dir):
    """XDG package (zsh/.config/zsh/.zshrc)"""
    package_dir = dotfiles_dir / "zsh"
    config_dir = package_dir / ".config" / "zsh"
    config_dir.mkdir(parents=True)
    (config_dir / ".zshrc").write_text("# ZSH config\n")
    return package_dir


@pytest.fixture
def sample_package_sudo(dotfiles_dir):
    """Sudo package (sudo_packages/etc/logid.cfg)"""
    package_dir = dotfiles_dir / "sudo_packages" / "etc"
    package_dir.mkdir(parents=True)
    (package_dir / "logid.cfg").write_text("# Config\n")
    return package_dir


# ========== Utilities ==========

@pytest.fixture
def json_file_helper():
    """Utility for working with JSON"""
    class JsonHelper:
        @staticmethod
        def read_json(file_path: Path) -> dict:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)

        @staticmethod
        def write_json(file_path: Path, data: dict):
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)

    return JsonHelper()
