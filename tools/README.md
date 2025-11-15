# Project Hydra - Security & Quality Scanning Tools

This directory contains scripts and tools for running security, vulnerability, and code quality scans on Project Hydra.

## Quick Start

### 1. Install Required Tools

**Linux/WSL:**
```bash
chmod +x tools/install_scan_tools.sh
./tools/install_scan_tools.sh
```

**Windows (PowerShell):**
```powershell
# Install Python tools
pip install semgrep safety bandit

# Install Rust tools (if Rust is installed)
cargo install cargo-audit
```

### 2. Run All Scans

**Linux/WSL:**
```bash
chmod +x tools/run_scans.sh
./tools/run_scans.sh
```

**Windows (PowerShell):**
```powershell
.\tools\run_scans.ps1
```

## Available Scans

### 1. Code Review Scan
- **Tool:** Semgrep (auto-config)
- **Purpose:** General code quality and best practices
- **Output:** `code-review-report_*.json` and `code-review-report_*.txt`

### 2. Security Scan
- **Tool:** Semgrep (security-audit rules)
- **Purpose:** Security vulnerabilities and issues
- **Output:** `security-report_*.json` and `security-report_*.txt`

### 3. Vulnerability Scan
- **Rust:** `cargo audit` (for Rust dependencies)
- **Python:** `safety` (for Python dependencies)
- **Purpose:** Known vulnerabilities in dependencies
- **Output:** `vulnerability-report-rust_*.json/txt` and `vulnerability-report-python_*.json/txt`

### 4. AI Code Proofreading
- **Tool:** Semgrep + Custom Python Analysis
- **Purpose:** AI-powered code review with categorized suggestions
- **Output:** `ai-proofreading-report_*.json` and `ai-proofreading-report_*.txt`

### 5. Python Security Scan
- **Tool:** Bandit
- **Purpose:** Python-specific security issues
- **Output:** `security-report-python_*.json` and `security-report-python_*.txt`

## Report Location

All reports are saved to: `scan-reports/`

Reports are automatically added to `.gitignore` and should not be committed to the repository.

## Tools Required

- **Semgrep:** `pip install semgrep`
- **Safety:** `pip install safety`
- **Bandit:** `pip install bandit`
- **Cargo Audit:** `cargo install cargo-audit` (requires Rust)

## Manual Tool Usage

### Semgrep
```bash
# Code review
semgrep --config=auto --json --output=report.json .

# Security scan
semgrep --config=p/security-audit --json --output=security.json .
```

### Cargo Audit
```bash
cd android/rust
cargo audit --json > audit.json
```

### Safety
```bash
safety check --json > safety.json
```

### Bandit
```bash
bandit -r ppt/ -f json -o bandit.json
```

## Troubleshooting

- **Tool not found:** Install using the commands above or run `install_scan_tools.sh`
- **Permission denied:** Make scripts executable with `chmod +x`
- **No reports generated:** Check that the tools are installed and paths are correct

