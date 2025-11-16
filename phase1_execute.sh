#!/bin/bash
set -e

# Determine repository path - use current directory if not specified
REPO_PATH="${REPO_PATH:-$(pwd)}"

log_action() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log_action "Phase 1 execution started"
log_action "Repository path: $REPO_PATH"

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
    log_action "Toolchain check incomplete - manual installation required"
    exit 1
else
    log_action "All required toolchains found"
fi

log_action "Toolchain check complete. Ready to build!"

# Build Rust library
log_action "Building Rust library..."
cd "$REPO_PATH/android/rust"
cargo build --release
log_action "Rust library built successfully"

log_action "Phase 1 execution completed successfully"

