#!/usr/bin/env bash
# ============================================================================
# Run All Tests - Bash and PowerShell
# ============================================================================
# Convenience script to run both bash and PowerShell test suites
#
# Usage:
#   ./run-all-tests.sh              # Run all tests
#   ./run-all-tests.sh --verbose    # Verbose output
#   ./run-all-tests.sh --keep       # Keep test directories
#   ./run-all-tests.sh --bash-only  # Run only bash tests
#   ./run-all-tests.sh --ps-only    # Run only PowerShell tests
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_BASH=true
RUN_POWERSHELL=true
VERBOSE_FLAG=""
KEEP_FLAG=""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE_FLAG="--verbose"
            shift
            ;;
        --keep|-k)
            KEEP_FLAG="--keep"
            shift
            ;;
        --bash-only)
            RUN_POWERSHELL=false
            shift
            ;;
        --ps-only|--powershell-only)
            RUN_BASH=false
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v          Verbose output"
            echo "  --keep, -k             Keep test directories"
            echo "  --bash-only            Run only bash tests"
            echo "  --ps-only              Run only PowerShell tests"
            echo "  --help, -h             Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}SpecKit Plus - Complete Worktree Test Suite${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

OVERALL_EXIT_CODE=0

# Run Bash tests
if [[ "$RUN_BASH" == "true" ]]; then
    echo -e "${BLUE}▶ Running Bash Test Suite...${NC}"
    echo ""

    if [[ -x "$SCRIPT_DIR/test-worktree.sh" ]]; then
        if "$SCRIPT_DIR/test-worktree.sh" $VERBOSE_FLAG $KEEP_FLAG; then
            echo ""
            echo -e "${GREEN}✓ Bash tests passed${NC}"
        else
            echo ""
            echo -e "${RED}✗ Bash tests failed${NC}"
            OVERALL_EXIT_CODE=1
        fi
    else
        echo -e "${RED}✗ test-worktree.sh not found or not executable${NC}"
        OVERALL_EXIT_CODE=1
    fi

    echo ""
fi

# Run PowerShell tests
if [[ "$RUN_POWERSHELL" == "true" ]]; then
    echo -e "${BLUE}▶ Running PowerShell Test Suite...${NC}"
    echo ""

    # Check if pwsh is available
    if command -v pwsh >/dev/null 2>&1; then
        PS_FLAGS=""
        if [[ -n "$VERBOSE_FLAG" ]]; then
            PS_FLAGS="$PS_FLAGS -VerboseOutput"
        fi
        if [[ -n "$KEEP_FLAG" ]]; then
            PS_FLAGS="$PS_FLAGS -Keep"
        fi

        if pwsh "$SCRIPT_DIR/test-worktree.ps1" $PS_FLAGS; then
            echo ""
            echo -e "${GREEN}✓ PowerShell tests passed${NC}"
        else
            echo ""
            echo -e "${RED}✗ PowerShell tests failed${NC}"
            OVERALL_EXIT_CODE=1
        fi
    else
        echo -e "${YELLOW}⚠ PowerShell (pwsh) not found - skipping PowerShell tests${NC}"
        echo -e "${YELLOW}  Install PowerShell from: https://github.com/PowerShell/PowerShell${NC}"
        echo ""
    fi

    echo ""
fi

# Final summary
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}Final Summary${NC}"
echo -e "${BLUE}============================================================================${NC}"

if [[ "$RUN_BASH" == "true" ]]; then
    echo -e "Bash tests:       ${GREEN}Run${NC}"
fi

if [[ "$RUN_POWERSHELL" == "true" ]]; then
    if command -v pwsh >/dev/null 2>&1; then
        echo -e "PowerShell tests: ${GREEN}Run${NC}"
    else
        echo -e "PowerShell tests: ${YELLOW}Skipped${NC}"
    fi
fi

echo ""

if [[ $OVERALL_EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✓ All test suites passed!${NC}"
else
    echo -e "${RED}✗ Some test suites failed${NC}"
fi

exit $OVERALL_EXIT_CODE
