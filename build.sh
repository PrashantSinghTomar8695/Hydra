#!/bin/bash
# Project Hydra - Build Script
# This script builds all components of the Hydra project

set -e

echo "=========================================="
echo "  Project Hydra - Build Script"
echo "=========================================="
echo ""

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "Repository: $REPO_ROOT"
echo ""

# Check prerequisites
echo "Checking prerequisites..."
MISSING=()

if ! command -v rustc &> /dev/null; then
    MISSING+=("Rust (rustc)")
fi

if ! command -v cargo &> /dev/null; then
    MISSING+=("Cargo")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "ERROR: Missing required tools:"
    for tool in "${MISSING[@]}"; do
        echo "  - $tool"
    done
    echo ""
    echo "Please install the missing tools and try again."
    echo "See BUILD_INSTRUCTIONS.md for installation instructions."
    exit 1
fi

echo "✓ All prerequisites found"
echo ""

# Build Rust library
echo "Building Rust RAM store library..."
cd "$REPO_ROOT/android/rust"
cargo build --release

if [ $? -eq 0 ]; then
    echo "✓ Rust library built successfully"
    
    # Show built library
    LIB_PATH="$REPO_ROOT/android/rust/target/release/libramstore.so"
    if [ -f "$LIB_PATH" ]; then
        echo "  Library: $LIB_PATH"
        echo "  Size: $(du -h "$LIB_PATH" | cut -f1)"
    fi
else
    echo "✗ Rust library build failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "  Build completed successfully!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. For Android: See BUILD_INSTRUCTIONS.md for Gradle build steps"
echo "  2. For iOS: See BUILD_INSTRUCTIONS.md for Xcode build steps"
echo ""
