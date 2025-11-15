#!/bin/bash
set -e

REPO_PATH="/mnt/c/Users/prash/OneDrive/Documents/test_project"
ARTIFACTS_DIR="$REPO_PATH/build_artifacts/phase1"
LOG_FILE="$ARTIFACTS_DIR/rust_build.log"

cd "$REPO_PATH/android/rust"

echo "Attempting Rust build..." | tee "$LOG_FILE"
echo "Date: $(date)" | tee -a "$LOG_FILE"
echo "Working directory: $(pwd)" | tee -a "$LOG_FILE"

# Attempt build - will fail if cargo not installed, but we'll capture the error
cargo build --release --all-targets 2>&1 | tee -a "$LOG_FILE" || {
    EXIT_CODE=$?
    echo "Build failed with exit code: $EXIT_CODE" | tee -a "$LOG_FILE"
    exit $EXIT_CODE
}

