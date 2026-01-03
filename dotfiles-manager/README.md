# Dotfiles Manager

Python-based dotfiles manager using GNU Stow for symlink management.

## Quick Links

- **Main Documentation**: [../DOTFILES-MANAGER.md](../DOTFILES-MANAGER.md)
- **Parent Repository**: [../README.md](../README.md)

## Development

### Project Structure

```
dotfiles-manager/
├── dotfiles-manager.py     # Main script (~1990 lines)
├── requirements-dev.txt    # Development dependencies
├── pytest.ini             # Pytest configuration
├── tests/                 # Test suite
│   ├── conftest.py       # Test fixtures
│   └── test_*.py         # Test files
└── README.md             # This file
```

### Running Tests

```bash
# Install dependencies
pip install -r requirements-dev.txt

# Run all tests
pytest

# Run with coverage (requires 80%+)
pytest --cov=. --cov-report=html --cov-report=term-missing

# Run specific test types
pytest -m unit              # Only unit tests
pytest -m integration       # Only integration tests

# Run specific test file
pytest tests/test_validation.py -v

# Run tests in parallel
pytest -n auto
```

### Test Coverage

The test suite includes:

- **~151 tests** covering 18 critical functions
- **80%+ code coverage** requirement (enforced by CI)
- **Unit tests**: Fast, no I/O operations
- **Integration tests**: File system operations

### CI/CD

Automated checks run on every push to `dotfiles-manager/**`:

1. **Pylint** (`.github/workflows/pylint.yml`)
   - Code quality analysis
   - Runs on Python 3.8, 3.10, 3.12

2. **Pytest** (`.github/workflows/test-dotfiles-manager.yml`)
   - Full test suite with coverage
   - Requires 80%+ coverage to pass
   - Includes GNU Stow installation

### Making Changes

1. Make your changes to `dotfiles-manager.py` or tests
2. Run tests locally: `pytest`
3. Ensure coverage is 80%+: `pytest --cov=. --cov-report=term-missing`
4. Commit changes (workflows will run automatically)

### Test Organization

- `conftest.py` - Shared fixtures for all tests
- `test_infrastructure.py` - Test infrastructure validation
- `test_validation.py` - Package name validation tests
- `test_config.py` - Configuration file handling tests
- *(More test files will be added)*

### Key Features Tested

- ✅ Package validation and naming
- ✅ Configuration file management (JSON)
- ✅ Conflict detection
- ✅ Dependency checking (GNU Stow)
- ✅ Package structure creation (XDG, simple, sudo)
- ✅ Metadata management
- ✅ Backup creation
- ✅ Command operations (install, uninstall, adopt, delete)

## Bug Fixes

### Fixed Issues

1. **Missing `import os`** (Line 21)
   - Function `_verify_symlinks_removed()` uses `os.walk()` but module wasn't imported
   - Fixed by adding `import os` after other imports

## Contributing

When adding new features:

1. Write tests first (TDD approach recommended)
2. Ensure 80%+ coverage for new code
3. Update documentation if needed
4. Run full test suite before committing

## Support

For issues or questions, see the main repository discussions.
