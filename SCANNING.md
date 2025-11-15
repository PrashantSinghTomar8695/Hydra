# Project Hydra - Security & Quality Scanning

This document describes the security and code quality scanning setup for Project Hydra.

## Overview

Project Hydra includes comprehensive scanning tools for:
1. **Code Review** - Automated code quality analysis
2. **AI Code Proofreading** - AI-powered code review with categorized suggestions
3. **Vulnerability Reports** - Dependency vulnerability scanning
4. **Security Reports** - Security-focused code analysis

## Quick Start

### Install Tools

**Linux/WSL:**
```bash
chmod +x tools/install_scan_tools.sh
./tools/install_scan_tools.sh
```

**Windows (PowerShell):**
```powershell
pip install semgrep safety bandit
cargo install cargo-audit  # If Rust is installed
```

### Run All Scans

**Linux/WSL:**
```bash
chmod +x tools/run_scans.sh
./tools/run_scans.sh
```

**Windows (PowerShell):**
```powershell
.\tools\run_scans.ps1
```

## Scan Types

### 1. Code Review Scan
- **Tool:** Semgrep (auto-config)
- **Purpose:** General code quality, best practices, and potential bugs
- **Output:** `scan-reports/code-review-report_*.json` and `.txt`

### 2. Security Scan
- **Tool:** Semgrep (security-audit ruleset)
- **Purpose:** Security vulnerabilities, injection risks, authentication issues
- **Output:** `scan-reports/security-report_*.json` and `.txt`

### 3. Vulnerability Scan

#### Rust Dependencies
- **Tool:** `cargo audit`
- **Purpose:** Known vulnerabilities in Rust crates
- **Output:** `scan-reports/vulnerability-report-rust_*.json` and `.txt`

#### Python Dependencies
- **Tool:** `safety`
- **Purpose:** Known vulnerabilities in Python packages
- **Output:** `scan-reports/vulnerability-report-python_*.json` and `.txt`

### 4. AI Code Proofreading
- **Tool:** Semgrep + Custom Python Analysis Script
- **Purpose:** AI-powered code review with categorized suggestions:
  - Security issues
  - Performance optimizations
  - Best practices
  - Maintainability improvements
  - General code quality
- **Output:** `scan-reports/ai-proofreading-report_*.json` and `.txt`

### 5. Python Security Scan
- **Tool:** Bandit
- **Purpose:** Python-specific security issues (SQL injection, shell injection, etc.)
- **Output:** `scan-reports/security-report-python_*.json` and `.txt`

## Report Location

All reports are saved to: **`scan-reports/`**

Reports are automatically excluded from git (see `.gitignore`).

## Tools Used

| Tool | Purpose | Install Command |
|------|---------|----------------|
| **Semgrep** | Code review & security scanning | `pip install semgrep` |
| **Safety** | Python dependency vulnerabilities | `pip install safety` |
| **Bandit** | Python security scanner | `pip install bandit` |
| **Cargo Audit** | Rust dependency vulnerabilities | `cargo install cargo-audit` |

## Integration

### CI/CD Integration

You can integrate these scans into your CI/CD pipeline:

```yaml
# Example GitHub Actions
- name: Run Security Scans
  run: ./tools/run_scans.sh
  
- name: Upload Reports
  uses: actions/upload-artifact@v3
  with:
    name: scan-reports
    path: scan-reports/
```

### Pre-commit Hooks

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
./tools/run_scans.sh
# Check for critical issues before allowing commit
```

## Report Formats

- **JSON:** Machine-readable format for CI/CD integration
- **TXT:** Human-readable format for manual review

## Best Practices

1. **Run scans regularly** - Before commits, PRs, and releases
2. **Review high-severity issues** - Address security and critical bugs first
3. **Update dependencies** - Keep tools and dependencies up to date
4. **Fix false positives** - Configure tool rules to reduce noise
5. **Document exceptions** - If you must ignore a finding, document why

## Troubleshooting

### Tool Not Found
- Ensure Python/Rust toolchains are installed
- Check PATH environment variable
- Try installing with `--user` flag: `pip install --user semgrep`

### No Reports Generated
- Verify project structure matches expected paths
- Check file permissions
- Review tool output for errors

### False Positives
- Semgrep: Create `.semgrep.yml` to exclude rules
- Bandit: Use `# nosec` comments or `.bandit` config file
- Cargo Audit: Update dependencies or use `--ignore` flag

## Additional Resources

- [Semgrep Documentation](https://semgrep.dev/docs/)
- [Bandit Documentation](https://bandit.readthedocs.io/)
- [Safety Documentation](https://pyup.io/safety/)
- [Cargo Audit Documentation](https://github.com/rustsec/cargo-audit)

## Support

For issues or questions about scanning setup, contact:
- **Project Lead:** Prashant Singh Tomar
- **Email:** prashantt409@gmail.com
- **GitHub:** https://github.com/PrashantSinghTomar8695

