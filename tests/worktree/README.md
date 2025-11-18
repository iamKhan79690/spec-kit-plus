# Git Worktree Test Suite

Comprehensive test suite for SpecKit Plus git worktree functionality. Tests all worktree detection, management, and integration features across both Bash and PowerShell environments.

## Quick Start

### Bash
```bash
cd tests/worktree
./test-worktree.sh
```

### PowerShell
```powershell
cd tests/worktree
.\test-worktree.ps1
```

## Requirements

### System Requirements
- **Git**: 2.15+ (for worktree support)
- **Bash**: 4.0+ (for bash tests)
- **PowerShell**: 7.0+ (for PowerShell tests)
- **Disk Space**: ~50MB for test repositories
- **Permissions**: Write access to temp directory

### Checking Requirements

**Git Version:**
```bash
git --version
# Should show: git version 2.15.0 or higher
```

**Bash Version:**
```bash
bash --version
# Should show: GNU bash, version 4.0 or higher
```

**PowerShell Version:**
```powershell
$PSVersionTable.PSVersion
# Should show: 7.0.0 or higher
```

## Test Coverage

### Unit Tests - Worktree Detection (6 tests)

Tests core worktree detection functions:

1. **`is_worktree()` in normal repo** - Should return false
2. **`is_worktree()` in worktree** - Should return true
3. **`get_repo_root()` in normal repo** - Should return repo path
4. **`get_repo_root()` in worktree** - Should return main repo path (not worktree)
5. **`get_worktree_dir()` in worktree** - Should return worktree directory
6. **`get_git_common_dir()`** - Should return main repo .git parent

### Unit Tests - Worktree Management (6 tests)

Tests worktree creation, listing, and removal:

1. **`create_worktree()` with new branch** - Creates branch and worktree
2. **`create_worktree()` with existing branch** - Creates worktree from existing branch
3. **`create_worktree()` with custom path** - Creates worktree at specified location
4. **`list_worktrees()`** - Lists all active worktrees
5. **`remove_worktree()`** - Removes worktree and cleans up
6. **`is_worktree_mode_enabled()`** - Checks SPECIFY_WORKTREE_MODE variable

### Integration Tests - File Access (2 tests)

Tests shared directory access:

1. **Access `specs/` from worktree** - Specs in main repo accessible from worktree
2. **Access `history/` from worktree** - History in main repo accessible from worktree

### Integration Tests - Scripts (2 tests)

Tests SpecKit Plus script integration:

1. **`create-new-feature.sh` normal mode** - Creates branch in current repo
2. **`create-new-feature.sh` worktree mode** - Creates worktree when SPECIFY_WORKTREE_MODE=true

### Edge Cases and Error Handling (4 tests)

Tests error conditions and edge cases:

1. **`create_worktree()` without git** - Fails gracefully
2. **`create_worktree()` with empty branch name** - Returns error
3. **Nested directory in worktree** - Detection works in subdirectories
4. **Multiple worktrees simultaneously** - All access same main repo

**Total: 20 tests** (Bash: 20, PowerShell: 11)

## Usage

### Basic Usage

Run all tests with default settings:

```bash
# Bash
./test-worktree.sh

# PowerShell
.\test-worktree.ps1
```

### Verbose Mode

Show detailed output for debugging:

```bash
# Bash
./test-worktree.sh --verbose
./test-worktree.sh -v

# PowerShell
.\test-worktree.ps1 -VerboseOutput
```

**Verbose output includes:**
- Detailed assertion values (expected vs actual)
- Test repository paths
- Function return values
- Additional context for failures

### Keep Test Directories

Preserve test directories after run for manual inspection:

```bash
# Bash
./test-worktree.sh --keep
./test-worktree.sh -k

# PowerShell
.\test-worktree.ps1 -Keep
```

Test directories will be left in:
- **Linux/macOS**: `/tmp/speckit-worktree-tests`
- **Windows**: `%TEMP%\speckit-worktree-tests`

### Combined Options

```bash
# Bash: Verbose output and keep directories
./test-worktree.sh --verbose --keep

# PowerShell
.\test-worktree.ps1 -VerboseOutput -Keep
```

### Environment Variables

Override test directory location:

```bash
# Bash
export TEST_BASE_DIR=/custom/path/tests
./test-worktree.sh

# PowerShell
$env:TEST_BASE_DIR = "C:\custom\path\tests"
.\test-worktree.ps1
```

## Understanding Test Output

### Successful Run

```
============================================================================
SpecKit Plus - Git Worktree Test Suite
============================================================================

[INFO] Git version: 2.39 ✓
[INFO] Setting up test environment...

Running Unit Tests - Worktree Detection
----------------------------------------
[INFO] Running: is_worktree() in normal repo
[PASS] is_worktree() in normal repo
[INFO] Running: is_worktree() in worktree
[PASS] is_worktree() in worktree
...

============================================================================
Test Summary
============================================================================
Tests run:    20
Tests passed: 20
Tests failed: 0

✓ All tests passed!
```

### Failed Test Example

```
[INFO] Running: get_repo_root() in worktree
[FAIL] get_repo_root() should return main repo path in worktree
       Expected: '/tmp/speckit-worktree-tests/test-repo'
       Actual:   '/tmp/speckit-worktree-tests/worktrees/test-branch'
[FAIL] get_repo_root() in worktree
```

### Test Summary

At the end of each run:

```
============================================================================
Test Summary
============================================================================
Tests run:    20
Tests passed: 18
Tests failed: 2

✗ Some tests failed
```

## Troubleshooting

### Git Version Error

**Error:**
```
[FAIL] Git 2.15+ required for worktree support (found: 2.14)
```

**Solution:**
Update git to version 2.15 or higher:

```bash
# Ubuntu/Debian
sudo add-apt-repository ppa:git-core/ppa
sudo apt update
sudo apt install git

# macOS
brew upgrade git

# Check version
git --version
```

### Permission Errors

**Error:**
```
mkdir: cannot create directory '/tmp/speckit-worktree-tests': Permission denied
```

**Solution:**
Use custom test directory with write permissions:

```bash
export TEST_BASE_DIR="$HOME/tmp/speckit-tests"
./test-worktree.sh
```

### Stale Test Directories

**Error:**
```
fatal: '/tmp/speckit-worktree-tests/worktrees/001-test' already exists
```

**Solution:**
Clean up manually:

```bash
# Remove old test directories
rm -rf /tmp/speckit-worktree-tests

# Or run with forced cleanup
rm -rf /tmp/speckit-worktree-tests && ./test-worktree.sh
```

### PowerShell Execution Policy

**Error:**
```
.\test-worktree.ps1 : File cannot be loaded because running scripts is disabled
```

**Solution:**
Allow script execution:

```powershell
# For current session only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Then run tests
.\test-worktree.ps1
```

### Tests Hang or Take Too Long

**Cause:**
Network issues with git operations or slow disk I/O

**Solution:**
- Ensure no network operations (all tests are local)
- Check disk space: `df -h /tmp`
- Use SSD if available
- Close other applications

## Writing New Tests

### Test Structure

Each test function should:

1. Create a clean test environment
2. Perform specific test operations
3. Make assertions about results
4. Return true (pass) or false (fail)

### Example Test (Bash)

```bash
test_my_new_feature() {
    local repo_path=$(create_test_repo "test-my-feature")
    cd "$repo_path"

    source "$repo_path/scripts/bash/common.sh"

    # Test logic here
    local result=$(my_function)

    # Assertions
    assert_equals "expected" "$result" "Function should return 'expected'"
}
```

### Example Test (PowerShell)

```powershell
function Test-MyNewFeature {
    $repoPath = New-TestRepository "test-my-feature"
    Set-Location $repoPath

    . "$repoPath/scripts/powershell/common.ps1"

    # Test logic here
    $result = My-Function

    # Assertions
    return Assert-Equals "expected" $result "Function should return 'expected'"
}
```

### Adding Tests to Runner

**Bash** (`test-worktree.sh`):
```bash
run_test "My new feature" test_my_new_feature
```

**PowerShell** (`test-worktree.ps1`):
```powershell
Invoke-Test "My new feature" { Test-MyNewFeature }
```

### Assertion Functions Available

**Bash:**
- `assert_equals <expected> <actual> [message]`
- `assert_true <condition> [message]`
- `assert_false <condition> [message]`
- `assert_file_exists <path> [message]`
- `assert_dir_exists <path> [message]`
- `assert_command_succeeds <message> <command...>`
- `assert_command_fails <message> <command...>`

**PowerShell:**
- `Assert-Equals -Expected <val> -Actual <val> [-Message <msg>]`
- `Assert-True -Condition <bool> [-Message <msg>]`
- `Assert-FileExists -Path <path> [-Message <msg>]`
- `Assert-DirectoryExists -Path <path> [-Message <msg>]`
- `Assert-CommandSucceeds -Message <msg> -Command <scriptblock>`

## CI/CD Integration

### GitHub Actions

```yaml
name: Test Worktree Support

on: [push, pull_request]

jobs:
  test-bash:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Bash Tests
        run: |
          cd tests/worktree
          ./test-worktree.sh

  test-powershell:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install PowerShell
        run: |
          sudo apt-get update
          sudo apt-get install -y powershell
      - name: Run PowerShell Tests
        run: |
          cd tests/worktree
          pwsh ./test-worktree.ps1
```

### GitLab CI

```yaml
test:worktree:bash:
  script:
    - cd tests/worktree
    - ./test-worktree.sh

test:worktree:powershell:
  image: mcr.microsoft.com/powershell:latest
  script:
    - cd tests/worktree
    - pwsh ./test-worktree.ps1
```

### Local Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
cd tests/worktree
./test-worktree.sh
exit $?
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Test Architecture

### Test Isolation

Each test runs in complete isolation:

1. **Fresh test repository** created for each test
2. **Clean working directory** - no shared state
3. **Separate git repository** - no conflicts
4. **Independent worktrees** - tests don't interfere

### Cleanup

- **Automatic cleanup**: Test directories removed after run (unless `--keep` flag used)
- **Worktree cleanup**: All worktrees pruned after each test
- **Git cleanup**: Repositories deleted, not just cleaned

### Performance

- **Parallel-safe**: Tests can be run concurrently (future enhancement)
- **Fast execution**: ~30-60 seconds for full suite
- **Minimal I/O**: Uses tmpfs when available

## Continuous Testing

### Watch Mode (Development)

Monitor tests during development:

```bash
# Install entr (file watcher)
# Ubuntu/Debian: apt install entr
# macOS: brew install entr

# Watch for changes and re-run tests
find ../../scripts/bash -name "*.sh" | entr -c ./test-worktree.sh
```

### Test-Driven Development

1. Write failing test for new feature
2. Run tests: `./test-worktree.sh`
3. Implement feature
4. Run tests again until passing
5. Refactor if needed

## Test Metrics

Track test execution:

```bash
# Run with timing
time ./test-worktree.sh

# Example output:
# real    0m42.156s
# user    0m15.234s
# sys     0m8.901s
```

## Contributing

When contributing worktree features:

1. **Add tests first** - Write tests that fail without your feature
2. **Run full suite** - Ensure all existing tests pass
3. **Test both platforms** - Run Bash and PowerShell tests
4. **Document changes** - Update this README if adding new test types
5. **Keep tests focused** - One test should test one thing

## See Also

- [Git Worktree Documentation](../../docs-plus/04_git_worktrees/README.md)
- [SpecKit Plus Commands](../../templates/commands/)
- [Common Functions](../../scripts/bash/common.sh)

## Support

For issues with tests:

1. Run with `--verbose` flag for detailed output
2. Check `--keep` flag to inspect test repositories
3. Verify git version: `git --version` (need 2.15+)
4. Check permissions on temp directory
5. Review recent changes to `common.sh` or `create-new-feature.sh`

## License

Same as SpecKit Plus - see repository LICENSE file.
