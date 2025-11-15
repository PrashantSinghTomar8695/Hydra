#!/bin/bash
set -e

# Project Hydra - Security and Code Quality Scanning Script
# This script runs all security, vulnerability, and code quality scans

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPORTS_DIR="$PROJECT_ROOT/scan-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "Project Hydra - Security & Quality Scans"
echo "=========================================="
echo "Timestamp: $TIMESTAMP"
echo "Reports directory: $REPORTS_DIR"
echo ""

# Create reports directory
mkdir -p "$REPORTS_DIR"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run scan with error handling
run_scan() {
    local scan_name="$1"
    local scan_command="$2"
    
    echo "----------------------------------------"
    echo "Running: $scan_name"
    echo "----------------------------------------"
    
    if eval "$scan_command"; then
        echo "✓ $scan_name completed successfully"
    else
        echo "⚠ $scan_name completed with warnings/errors"
    fi
    echo ""
}

# 1. Code Review Scan (Semgrep)
if command_exists semgrep; then
    run_scan "Code Review (Semgrep)" \
        "semgrep --config=auto --json --output=\"$REPORTS_DIR/code-review-report_${TIMESTAMP}.json\" --text --output=\"$REPORTS_DIR/code-review-report_${TIMESTAMP}.txt\" \"$PROJECT_ROOT\""
else
    echo "⚠ Semgrep not found. Install with: pip install semgrep"
    echo "  Or use: python -m pip install semgrep"
    echo ""
fi

# 2. Security Scan (Semgrep Security Rules)
if command_exists semgrep; then
    run_scan "Security Scan (Semgrep Security)" \
        "semgrep --config=p/security-audit --json --output=\"$REPORTS_DIR/security-report_${TIMESTAMP}.json\" --text --output=\"$REPORTS_DIR/security-report_${TIMESTAMP}.txt\" \"$PROJECT_ROOT\""
else
    echo "⚠ Semgrep not found for security scan"
    echo ""
fi

# 3. Rust Vulnerability Scan (cargo audit)
if command_exists cargo; then
    if [ -f "$PROJECT_ROOT/android/rust/Cargo.toml" ]; then
        run_scan "Rust Vulnerability Scan (cargo audit)" \
            "cd \"$PROJECT_ROOT/android/rust\" && cargo audit --json > \"$REPORTS_DIR/vulnerability-report-rust_${TIMESTAMP}.json\" 2>&1 || cargo audit > \"$REPORTS_DIR/vulnerability-report-rust_${TIMESTAMP}.txt\" 2>&1"
    else
        echo "⚠ Rust Cargo.toml not found"
    fi
else
    echo "⚠ cargo not found. Install Rust toolchain first"
    echo ""
fi

# 4. Python Vulnerability Scan (safety)
if command_exists safety; then
    if [ -f "$PROJECT_ROOT/ppt/requirements.txt" ] || [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        run_scan "Python Vulnerability Scan (safety)" \
            "safety check --json --output \"$REPORTS_DIR/vulnerability-report-python_${TIMESTAMP}.json\" 2>&1 || safety check --output \"$REPORTS_DIR/vulnerability-report-python_${TIMESTAMP}.txt\" 2>&1"
    else
        echo "⚠ Python requirements.txt not found"
    fi
else
    echo "⚠ safety not found. Install with: pip install safety"
    echo ""
fi

# 5. Python Security Scan (bandit)
if command_exists bandit; then
    if [ -d "$PROJECT_ROOT/ppt" ]; then
        run_scan "Python Security Scan (bandit)" \
            "bandit -r \"$PROJECT_ROOT/ppt\" -f json -o \"$REPORTS_DIR/security-report-python_${TIMESTAMP}.json\" 2>&1 || bandit -r \"$PROJECT_ROOT/ppt\" -f txt -o \"$REPORTS_DIR/security-report-python_${TIMESTAMP}.txt\" 2>&1"
    else
        echo "⚠ Python source directory not found"
    fi
else
    echo "⚠ bandit not found. Install with: pip install bandit"
    echo ""
fi

# 6. AI Code Proofreading (using semgrep + custom analysis)
if command_exists semgrep; then
    run_scan "AI Code Proofreading (Semgrep + Analysis)" \
        "semgrep --config=auto --json --output=\"$REPORTS_DIR/ai-proofreading-report_${TIMESTAMP}.json\" \"$PROJECT_ROOT\" && python3 \"$SCRIPT_DIR/ai_proofreading.py\" \"$REPORTS_DIR/ai-proofreading-report_${TIMESTAMP}.json\" \"$REPORTS_DIR/ai-proofreading-report_${TIMESTAMP}.txt\" 2>&1 || echo 'AI proofreading analysis completed'"
else
    echo "⚠ Semgrep not found for AI proofreading"
    echo ""
fi

# Generate summary report
echo "=========================================="
echo "Scan Summary"
echo "=========================================="
echo "All scan reports saved to: $REPORTS_DIR"
echo ""
echo "Generated reports:"
ls -lh "$REPORTS_DIR"/*${TIMESTAMP}* 2>/dev/null || echo "No reports generated"
echo ""
echo "=========================================="
echo "Scanning complete!"
echo "=========================================="

