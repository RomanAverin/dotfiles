"""Tests for test infrastructure validation"""
import pytest


@pytest.mark.unit
def test_fixtures_loaded(dotfiles_dir, target_dir, manager):
    """Verify that fixtures load correctly"""
    assert dotfiles_dir.exists()
    assert target_dir.exists()
    assert manager is not None
    assert manager.config.dotfiles_dir == dotfiles_dir


@pytest.mark.unit
def test_sample_package_simple(sample_package_simple):
    """Verify simple test package creation"""
    assert sample_package_simple.exists()
    assert (sample_package_simple / ".vimrc").exists()
    content = (sample_package_simple / ".vimrc").read_text()
    assert "set number" in content


@pytest.mark.unit
def test_config_file_fixture(config_file, json_file_helper):
    """Verify configuration file creation"""
    assert config_file.exists()
    config = json_file_helper.read_json(config_file)
    assert "all_packages" in config
    assert "zsh" in config["all_packages"]
