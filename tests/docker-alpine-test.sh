#!/usr/bin/env bash
set -e

# Install dependencies
apk add --no-cache git bash > /dev/null 2>&1

# Configure git
git config --global user.name "Test User"
git config --global user.email "test@example.com"
git config --global init.defaultBranch main

# Create test project
cd /tmp
mkdir shop && cd shop
git init

# Copy scripts
cp -r /workspace/scripts ./
cp -r /workspace/templates ./
mkdir -p specs history

# Initial commit
echo "# Shop" > README.md
git add .
git commit -m "init" > /dev/null 2>&1

# TEST: Old flow on Alpine
echo "=== Alpine Linux - Old Flow ==="
bash scripts/bash/create-new-feature.sh --json --short-name "cart" "Shopping cart"

git branch | grep "001-cart" && echo "✓ Branch created on Alpine" || exit 1
test -d "specs/001-cart" && echo "✓ Spec created on Alpine" || exit 1
echo "✓ WORKS ON ALPINE LINUX"

git checkout main > /dev/null 2>&1

# TEST: New flow on Alpine
echo ""
echo "=== Alpine Linux - New Flow (Worktrees) ==="
export SPECIFY_WORKTREE_MODE=true
bash scripts/bash/create-new-feature.sh --json --short-name "checkout" "Checkout process"

test -d "../worktrees/002-checkout" && echo "✓ Worktree on Alpine" || exit 1
test -d "specs/002-checkout" && echo "✓ Shared specs on Alpine" || exit 1
echo "✓ WORKTREES WORK ON ALPINE"

echo ""
echo "=========================================="
echo "ALPINE LINUX: ALL TESTS PASSED ✓"
echo "=========================================="
