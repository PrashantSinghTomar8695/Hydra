#!/bin/bash
set -e
echo "Phase 1 agent starting at $(date)"
REPO_PATH="/mnt/c/Users/prash/OneDrive/Documents/test_project"
if [ ! -d "$REPO_PATH/android" ]; then
    echo "ERROR: Android directory not found at $REPO_PATH"
    exit 2
fi
echo "REPO_PATH=$REPO_PATH"
cd "$REPO_PATH"
pwd
ls -la | head -20

