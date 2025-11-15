#!/bin/bash
# Toolchain installation commands for Project Hydra Phase 1
# Run these in WSL Kali Linux after user approval

set -e

echo "Installing Rust toolchain..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

echo "Installing Java JDK..."
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk

echo "Installing Android SDK dependencies..."
sudo apt-get install -y unzip wget

echo "Setting up Android NDK (if needed)..."
# Note: Full Android SDK/NDK setup may require Android Studio or manual download
# This is a minimal setup - user may need to configure SDK path in local.properties

echo "Verifying installations..."
rustc --version
cargo --version
javac -version

echo "Installation complete!"

