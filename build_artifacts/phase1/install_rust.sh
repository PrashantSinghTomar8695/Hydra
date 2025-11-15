#!/bin/bash
# Rust toolchain installation script for Project Hydra Phase 1
# Run this in WSL Kali Linux

set -e

echo "=== Installing Rust Toolchain ==="
echo "This will install rustup and cargo (~200MB download)"
echo ""

# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Source cargo
source "$HOME/.cargo/env"

# Verify installation
rustc --version
cargo --version

# Install Android targets
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi

# Install cargo-ndk for cross-compilation
cargo install cargo-ndk

echo ""
echo "=== Rust installation complete ==="
echo "Add to your shell profile: source \$HOME/.cargo/env"

