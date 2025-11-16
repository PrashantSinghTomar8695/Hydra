#!/bin/bash
set -e

# Determine repository path - use current directory if not specified
REPO_PATH="${REPO_PATH:-$(pwd)}"
ARTIFACTS_DIR="$REPO_PATH/build_artifacts/phase1"
ACTIONS_LOG="$ARTIFACTS_DIR/actions.log"

log_action() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$ACTIONS_LOG"
}

log_action "Phase 1 execution started"

# Create artifact directories
mkdir -p "$ARTIFACTS_DIR/{apk,libs,logs}"
log_action "Artifact directories created"

# Check toolchains
log_action "Checking toolchains..."
MISSING_TOOLS=()

if ! command -v rustc &> /dev/null; then
    MISSING_TOOLS+=("rustc")
fi
if ! command -v cargo &> /dev/null; then
    MISSING_TOOLS+=("cargo")
fi
if ! command -v javac &> /dev/null; then
    MISSING_TOOLS+=("javac")
fi
if [ ! -f "$REPO_PATH/android/gradlew" ]; then
    MISSING_TOOLS+=("gradlew")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    log_action "Missing tools: ${MISSING_TOOLS[*]}"
    echo "MISSING_TOOLS=${MISSING_TOOLS[*]}" > "$ARTIFACTS_DIR/missing_tools.txt"
    log_action "Toolchain check incomplete - manual installation required"
else
    log_action "All required toolchains found"
fi

echo "Toolchain check complete. Missing: ${MISSING_TOOLS[*]}"

