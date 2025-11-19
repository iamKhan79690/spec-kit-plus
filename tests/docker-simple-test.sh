#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Install dependencies
apt-get update -qq
apt-get install -y -qq git bash > /dev/null 2>&1

# Configure git
git config --global user.name "Test User"
git config --global user.email "test@example.com"
git config --global init.defaultBranch main

# Create test project
cd /tmp
mkdir calc && cd calc
git init

# Copy scripts from workspace
cp -r /workspace/scripts ./
cp -r /workspace/templates ./
mkdir -p specs history

# Initial commit
echo "# Calculator" > README.md
git add .
git commit -m "init" > /dev/null 2>&1

# TEST 1: Old flow
echo "=== TEST 1: Old Flow (Traditional Branches) ==="
bash scripts/bash/create-new-feature.sh --json --short-name "add" "Add basic addition"

# Verify
git branch | grep "001-add" && echo "✓ Branch created" || exit 1
test -d "specs/001-add" && echo "✓ Spec directory created" || exit 1
echo "✓ OLD FLOW WORKS IN DOCKER"

# Return to main
git checkout main > /dev/null 2>&1

echo ""
echo "=== TEST 2: New Flow (Git Worktrees) ==="
export SPECIFY_WORKTREE_MODE=true
bash scripts/bash/create-new-feature.sh --json --short-name "subtract" "Add subtraction"

# Verify worktree
test -d "../worktrees/002-subtract" && echo "✓ Worktree created" || exit 1
test -d "specs/002-subtract" && echo "✓ Spec in main repo" || exit 1
git worktree list | grep "002-subtract" && echo "✓ Worktree registered" || exit 1
echo "✓ NEW FLOW WORKS IN DOCKER"

echo ""
echo "=========================================="
echo "ALL DOCKER TESTS PASSED ✓"
echo "=========================================="
