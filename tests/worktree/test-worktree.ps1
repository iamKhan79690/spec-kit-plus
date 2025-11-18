#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Git Worktree Test Suite for SpecKit Plus (PowerShell)

.DESCRIPTION
    Tests all worktree functionality including detection, creation, and
    integration with /sp.specify command for PowerShell environments.

.PARAMETER Verbose
    Enable verbose output

.PARAMETER Keep
    Keep test directories after run

.EXAMPLE
    .\test-worktree.ps1

.EXAMPLE
    .\test-worktree.ps1 -Verbose -Keep

.NOTES
    Requirements:
    - Git 2.15+ (for worktree support)
    - PowerShell 7.0+
    - Write permissions in temp directory
#>

[CmdletBinding()]
param(
    [switch]$Keep,
    [switch]$VerboseOutput
)

# Configuration
$Script:ScriptDir = $PSScriptRoot
$Script:RepoRoot = (Resolve-Path "$ScriptDir/../..").Path
$Script:TestBaseDir = if ($env:TEMP) { "$env:TEMP\speckit-worktree-tests" } else { "/tmp/speckit-worktree-tests" }
$Script:TestsRun = 0
$Script:TestsPassed = 0
$Script:TestsFailed = 0

# ============================================================================
# Helper Functions
# ============================================================================

function Write-TestInfo {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-TestSuccess {
    param([string]$Message)
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Write-TestError {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-TestWarning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-TestVerbose {
    param([string]$Message)
    if ($VerboseOutput) {
        Write-Host "       $Message" -ForegroundColor Gray
    }
}

# Assertion functions
function Assert-Equals {
    param(
        [string]$Expected,
        [string]$Actual,
        [string]$Message = "Assertion failed"
    )

    if ($Expected -eq $Actual) {
        return $true
    }

    Write-TestError $Message
    Write-TestVerbose "Expected: '$Expected'"
    Write-TestVerbose "Actual:   '$Actual'"
    return $false
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message = "Assertion failed"
    )

    if ($Condition) {
        return $true
    }

    Write-TestError $Message
    Write-TestVerbose "Condition was false"
    return $false
}

function Assert-FileExists {
    param(
        [string]$Path,
        [string]$Message = "File does not exist: $Path"
    )

    if (Test-Path -Path $Path -PathType Leaf) {
        return $true
    }

    Write-TestError $Message
    return $false
}

function Assert-DirectoryExists {
    param(
        [string]$Path,
        [string]$Message = "Directory does not exist: $Path"
    )

    if (Test-Path -Path $Path -PathType Container) {
        return $true
    }

    Write-TestError $Message
    return $false
}

function Assert-CommandSucceeds {
    param(
        [string]$Message,
        [scriptblock]$Command
    )

    try {
        $null = & $Command 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
    } catch {
        # Command failed
    }

    Write-TestError $Message
    return $false
}

function Invoke-Test {
    param(
        [string]$Name,
        [scriptblock]$Test
    )

    $Script:TestsRun++
    Write-TestInfo "Running: $Name"

    try {
        $result = & $Test
        if ($result) {
            $Script:TestsPassed++
            Write-TestSuccess $Name
            return $true
        } else {
            $Script:TestsFailed++
            Write-TestError $Name
            return $false
        }
    } catch {
        $Script:TestsFailed++
        Write-TestError "$Name (Exception: $_)"
        return $false
    }
}

# ============================================================================
# Test Setup and Teardown
# ============================================================================

function Initialize-TestEnvironment {
    Write-TestInfo "Setting up test environment..."

    if (Test-Path $Script:TestBaseDir) {
        Remove-Item -Path $Script:TestBaseDir -Recurse -Force
    }

    New-Item -Path $Script:TestBaseDir -ItemType Directory -Force | Out-Null
    Set-Location $Script:TestBaseDir

    Write-TestVerbose "Test directory: $Script:TestBaseDir"
}

function Remove-TestEnvironment {
    if (-not $Keep) {
        Write-TestInfo "Cleaning up test environment..."
        Set-Location $env:TEMP
        Remove-Item -Path $Script:TestBaseDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-TestVerbose "Removed: $Script:TestBaseDir"
    } else {
        Write-TestWarning "Keeping test directories: $Script:TestBaseDir"
    }
}

function New-TestRepository {
    param([string]$Name)

    $repoPath = Join-Path $Script:TestBaseDir $Name
    New-Item -Path $repoPath -ItemType Directory -Force | Out-Null
    Set-Location $repoPath

    git init -b main 2>$null | Out-Null
    git config user.email "test@speckit.test"
    git config user.name "SpecKit Test"

    # Copy SpecKit Plus structure
    New-Item -Path "specs" -ItemType Directory -Force | Out-Null
    New-Item -Path "history/prompts" -ItemType Directory -Force | Out-Null
    New-Item -Path "templates" -ItemType Directory -Force | Out-Null
    New-Item -Path "scripts/bash" -ItemType Directory -Force | Out-Null
    New-Item -Path "scripts/powershell" -ItemType Directory -Force | Out-Null

    # Copy scripts
    Copy-Item "$Script:RepoRoot/scripts/bash/common.sh" "$repoPath/scripts/bash/" -ErrorAction SilentlyContinue
    Copy-Item "$Script:RepoRoot/scripts/bash/create-new-feature.sh" "$repoPath/scripts/bash/" -ErrorAction SilentlyContinue
    Copy-Item "$Script:RepoRoot/scripts/powershell/common.ps1" "$repoPath/scripts/powershell/" -ErrorAction SilentlyContinue

    # Initial commit
    "# Test Repository" | Out-File -FilePath "README.md" -Encoding UTF8
    git add -A 2>$null | Out-Null
    git commit -m "Initial commit" 2>$null | Out-Null

    Write-TestVerbose "Created test repo: $repoPath"
    return $repoPath
}

# ============================================================================
# Unit Tests - Worktree Detection Functions
# ============================================================================

function Test-IsWorktreeInNormalRepo {
    $repoPath = New-TestRepository "test-normal-repo"
    Set-Location $repoPath

    . "$repoPath/scripts/powershell/common.ps1"

    # In normal repo, Test-IsWorktree should return false
    $result = Test-IsWorktree
    if ($result) {
        Write-TestError "Test-IsWorktree returned true in normal repo"
        return $false
    }

    Write-TestVerbose "Test-IsWorktree correctly returned false in normal repo"
    return $true
}

function Test-IsWorktreeInWorktree {
    $repoPath = New-TestRepository "test-worktree-repo"
    Set-Location $repoPath

    # Create a worktree
    $worktreesDir = Join-Path $Script:TestBaseDir "worktrees"
    New-Item -Path $worktreesDir -ItemType Directory -Force | Out-Null
    git worktree add "$worktreesDir/test-branch" -b test-branch 2>$null | Out-Null

    # Switch to worktree
    Set-Location "$worktreesDir/test-branch"

    . "$repoPath/scripts/powershell/common.ps1"

    # In worktree, Test-IsWorktree should return true
    $result = Test-IsWorktree
    if (-not $result) {
        Write-TestError "Test-IsWorktree returned false in worktree"
        return $false
    }

    Write-TestVerbose "Test-IsWorktree correctly returned true in worktree"
    return $true
}

function Test-GetRepoRootInNormalRepo {
    $repoPath = New-TestRepository "test-repo-root-normal"
    Set-Location $repoPath

    . "$repoPath/scripts/powershell/common.ps1"

    $detectedRoot = Get-RepoRoot

    return Assert-Equals $repoPath $detectedRoot "Get-RepoRoot should return repo path in normal repo"
}

function Test-GetRepoRootInWorktree {
    $repoPath = New-TestRepository "test-repo-root-worktree"
    Set-Location $repoPath

    # Create a worktree
    $worktreesDir = Join-Path $Script:TestBaseDir "worktrees"
    New-Item -Path $worktreesDir -ItemType Directory -Force | Out-Null
    git worktree add "$worktreesDir/test-branch" -b test-branch 2>$null | Out-Null

    # Switch to worktree
    Set-Location "$worktreesDir/test-branch"

    . "$repoPath/scripts/powershell/common.ps1"

    $detectedRoot = Get-RepoRoot

    # Should return main repo root, not worktree directory
    return Assert-Equals $repoPath $detectedRoot "Get-RepoRoot should return main repo path in worktree"
}

function Test-GetWorktreeDirInWorktree {
    $repoPath = New-TestRepository "test-worktree-dir"
    Set-Location $repoPath

    # Create a worktree
    $worktreePath = Join-Path $Script:TestBaseDir "worktrees/test-branch"
    $worktreesDir = Join-Path $Script:TestBaseDir "worktrees"
    New-Item -Path $worktreesDir -ItemType Directory -Force | Out-Null
    git worktree add $worktreePath -b test-branch 2>$null | Out-Null

    # Switch to worktree
    Set-Location $worktreePath

    . "$repoPath/scripts/powershell/common.ps1"

    $detectedDir = Get-WorktreeDir

    return Assert-Equals $worktreePath $detectedDir "Get-WorktreeDir should return worktree directory"
}

# ============================================================================
# Unit Tests - Worktree Management Functions
# ============================================================================

function Test-CreateWorktreeNewBranch {
    $repoPath = New-TestRepository "test-create-worktree"
    Set-Location $repoPath

    . "$repoPath/scripts/powershell/common.ps1"

    $worktreePath = New-Worktree -BranchName "001-test-feature"

    if (-not $worktreePath) {
        Write-TestError "New-Worktree returned null"
        return $false
    }

    if (-not (Test-Path $worktreePath)) {
        Write-TestError "Worktree directory does not exist"
        return $false
    }

    # Check branch exists
    git rev-parse --verify 001-test-feature 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-TestError "Branch was not created"
        return $false
    }

    Write-TestVerbose "Created worktree at: $worktreePath"
    return $true
}

function Test-CreateWorktreeExistingBranch {
    $repoPath = New-TestRepository "test-create-worktree-existing"
    Set-Location $repoPath

    . "$repoPath/scripts/powershell/common.ps1"

    # Create branch first
    git branch 002-existing-branch 2>$null | Out-Null

    $worktreePath = New-Worktree -BranchName "002-existing-branch"

    if (-not $worktreePath) {
        Write-TestError "New-Worktree failed with existing branch"
        return $false
    }

    return Assert-DirectoryExists $worktreePath "Worktree directory should exist"
}

function Test-ListWorktrees {
    $repoPath = New-TestRepository "test-list-worktrees"
    Set-Location $repoPath

    . "$repoPath/scripts/powershell/common.ps1"

    # Create some worktrees
    New-Worktree -BranchName "001-feature-a" | Out-Null
    New-Worktree -BranchName "002-feature-b" | Out-Null

    $worktreeList = Get-Worktrees | Out-String

    if ($worktreeList -notmatch "001-feature-a") {
        Write-TestError "feature-a not found in worktree list"
        return $false
    }

    if ($worktreeList -notmatch "002-feature-b") {
        Write-TestError "feature-b not found in worktree list"
        return $false
    }

    Write-TestVerbose "Both worktrees found in list"
    return $true
}

function Test-RemoveWorktree {
    $repoPath = New-TestRepository "test-remove-worktree"
    Set-Location $repoPath

    . "$repoPath/scripts/powershell/common.ps1"

    $worktreePath = New-Worktree -BranchName "004-to-remove"

    if (-not (Test-Path $worktreePath)) {
        Write-TestError "Worktree was not created"
        return $false
    }

    Remove-Worktree -WorktreePath $worktreePath 2>$null

    if (Test-Path $worktreePath) {
        Write-TestError "Worktree directory still exists after removal"
        return $false
    }

    Write-TestVerbose "Worktree removed successfully"
    return $true
}

# ============================================================================
# Integration Tests
# ============================================================================

function Test-SpecsAccessFromWorktree {
    $repoPath = New-TestRepository "test-specs-access"
    Set-Location $repoPath

    . "$repoPath/scripts/powershell/common.ps1"

    # Create a spec in main repo
    New-Item -Path "$repoPath/specs/001-main-spec" -ItemType Directory -Force | Out-Null
    "# Main Spec" | Out-File -FilePath "$repoPath/specs/001-main-spec/spec.md" -Encoding UTF8

    # Create worktree
    $worktreePath = New-Worktree -BranchName "002-worktree-branch"
    Set-Location $worktreePath

    # Get repo root from worktree
    $detectedRoot = Get-RepoRoot
    $specsDir = Join-Path $detectedRoot "specs"

    # Should access main spec from worktree
    if (-not (Test-Path "$specsDir/001-main-spec/spec.md")) {
        Write-TestError "Cannot access specs from main repo"
        return $false
    }

    # Create spec from worktree
    New-Item -Path "$specsDir/002-worktree-spec" -ItemType Directory -Force | Out-Null
    "# Worktree Spec" | Out-File -FilePath "$specsDir/002-worktree-spec/spec.md" -Encoding UTF8

    # Verify from main repo
    Set-Location $repoPath
    return Assert-FileExists "$repoPath/specs/002-worktree-spec/spec.md" "Spec created from worktree should exist in main repo"
}

function Test-MultipleWorktreesSimultaneously {
    $repoPath = New-TestRepository "test-multiple"
    Set-Location $repoPath

    . "$repoPath/scripts/powershell/common.ps1"

    # Create multiple worktrees
    $wt1 = New-Worktree -BranchName "001-feature-a"
    $wt2 = New-Worktree -BranchName "002-feature-b"
    $wt3 = New-Worktree -BranchName "003-feature-c"

    # All should exist
    if (-not (Test-Path $wt1)) { return $false }
    if (-not (Test-Path $wt2)) { return $false }
    if (-not (Test-Path $wt3)) { return $false }

    # All should access same repo root
    Set-Location $wt1
    $root1 = Get-RepoRoot

    Set-Location $wt2
    $root2 = Get-RepoRoot

    Set-Location $wt3
    $root3 = Get-RepoRoot

    if ($root1 -ne $repoPath) { return $false }
    if ($root2 -ne $repoPath) { return $false }
    if ($root3 -ne $repoPath) { return $false }

    Write-TestVerbose "All worktrees access same repo root"
    return $true
}

# ============================================================================
# Main Test Runner
# ============================================================================

function Main {
    Write-Host "============================================================================"
    Write-Host "SpecKit Plus - Git Worktree Test Suite (PowerShell)"
    Write-Host "============================================================================"
    Write-Host ""

    # Check git version
    $gitVersion = (git --version) -replace '.*?(\d+\.\d+).*','$1'
    $gitParts = $gitVersion.Split('.')
    $gitMajor = [int]$gitParts[0]
    $gitMinor = [int]$gitParts[1]

    if ($gitMajor -lt 2 -or ($gitMajor -eq 2 -and $gitMinor -lt 15)) {
        Write-TestError "Git 2.15+ required for worktree support (found: $gitVersion)"
        exit 1
    }

    Write-TestInfo "Git version: $gitVersion ✓"
    Write-Host ""

    Initialize-TestEnvironment

    # Run all tests
    Write-Host "Running Unit Tests - Worktree Detection"
    Write-Host "----------------------------------------"
    Invoke-Test "Test-IsWorktree in normal repo" { Test-IsWorktreeInNormalRepo }
    Invoke-Test "Test-IsWorktree in worktree" { Test-IsWorktreeInWorktree }
    Invoke-Test "Get-RepoRoot in normal repo" { Test-GetRepoRootInNormalRepo }
    Invoke-Test "Get-RepoRoot in worktree" { Test-GetRepoRootInWorktree }
    Invoke-Test "Get-WorktreeDir in worktree" { Test-GetWorktreeDirInWorktree }
    Write-Host ""

    Write-Host "Running Unit Tests - Worktree Management"
    Write-Host "----------------------------------------"
    Invoke-Test "New-Worktree with new branch" { Test-CreateWorktreeNewBranch }
    Invoke-Test "New-Worktree with existing branch" { Test-CreateWorktreeExistingBranch }
    Invoke-Test "Get-Worktrees" { Test-ListWorktrees }
    Invoke-Test "Remove-Worktree" { Test-RemoveWorktree }
    Write-Host ""

    Write-Host "Running Integration Tests"
    Write-Host "----------------------------------------"
    Invoke-Test "Access specs/ from worktree" { Test-SpecsAccessFromWorktree }
    Invoke-Test "Multiple worktrees simultaneously" { Test-MultipleWorktreesSimultaneously }
    Write-Host ""

    Remove-TestEnvironment

    # Print summary
    Write-Host "============================================================================"
    Write-Host "Test Summary"
    Write-Host "============================================================================"
    Write-Host "Tests run:    $Script:TestsRun" -ForegroundColor Cyan
    Write-Host "Tests passed: $Script:TestsPassed" -ForegroundColor Green
    Write-Host "Tests failed: $Script:TestsFailed" -ForegroundColor Red
    Write-Host ""

    if ($Script:TestsFailed -eq 0) {
        Write-Host "✓ All tests passed!" -ForegroundColor Green
        return 0
    } else {
        Write-Host "✗ Some tests failed" -ForegroundColor Red
        return 1
    }
}

# Run main
exit (Main)
