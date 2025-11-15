#!/bin/bash
set -e

# Install all required scanning tools for Project Hydra

echo "=========================================="
echo "Installing Security & Quality Scan Tools"
echo "=========================================="
echo ""

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_CMD=python3
    PIP_CMD=pip3
elif command -v python &> /dev/null; then
    PYTHON_CMD=python
    PIP_CMD=pip
else
    echo "❌ Python not found. Please install Python 3 first."
    exit 1
fi

echo "Using Python: $($PYTHON_CMD --version)"
echo ""

# Install Semgrep (Code Review & Security)
echo "Installing Semgrep..."
if command -v semgrep &> /dev/null; then
    echo "✓ Semgrep already installed"
else
    $PIP_CMD install semgrep || echo "⚠ Failed to install semgrep. Try: pip install semgrep"
fi
echo ""

# Install Safety (Python Vulnerability Scanner)
echo "Installing Safety..."
if command -v safety &> /dev/null; then
    echo "✓ Safety already installed"
else
    $PIP_CMD install safety || echo "⚠ Failed to install safety. Try: pip install safety"
fi
echo ""

# Install Bandit (Python Security Scanner)
echo "Installing Bandit..."
if command -v bandit &> /dev/null; then
    echo "✓ Bandit already installed"
else
    $PIP_CMD install bandit || echo "⚠ Failed to install bandit. Try: pip install bandit"
fi
echo ""

# Install/Check Cargo Audit (Rust Vulnerability Scanner)
echo "Checking Cargo Audit..."
if command -v cargo &> /dev/null; then
    if cargo audit --version &> /dev/null; then
        echo "✓ cargo-audit already installed"
    else
        echo "Installing cargo-audit..."
        cargo install cargo-audit || echo "⚠ Failed to install cargo-audit. Try: cargo install cargo-audit"
    fi
else
    echo "⚠ Rust/cargo not found. Install Rust toolchain to use cargo-audit"
fi
echo ""

echo "=========================================="
echo "Installation Summary"
echo "=========================================="
echo ""

# Verify installations
echo "Installed tools:"
command -v semgrep &> /dev/null && echo "  ✓ semgrep" || echo "  ✗ semgrep (not found)"
command -v safety &> /dev/null && echo "  ✓ safety" || echo "  ✗ safety (not found)"
command -v bandit &> /dev/null && echo "  ✓ bandit" || echo "  ✗ bandit (not found)"
command -v cargo &> /dev/null && cargo audit --version &> /dev/null && echo "  ✓ cargo-audit" || echo "  ✗ cargo-audit (not found)"

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Run: ./tools/run_scans.sh"
echo "  2. Check reports in: scan-reports/"
echo ""

