# Project Hydra - Security and Code Quality Scanning Script (PowerShell)
# This script runs all security, vulnerability, and code quality scans

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ReportsDir = Join-Path $ProjectRoot "scan-reports"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "=========================================="
Write-Host "Project Hydra - Security & Quality Scans"
Write-Host "=========================================="
Write-Host "Timestamp: $Timestamp"
Write-Host "Reports directory: $ReportsDir"
Write-Host ""

# Create reports directory
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir | Out-Null
}

# Function to check if command exists
function Test-Command {
    param($Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Function to run scan with error handling
function Run-Scan {
    param(
        [string]$ScanName,
        [scriptblock]$ScanCommand
    )
    
    Write-Host "----------------------------------------"
    Write-Host "Running: $ScanName"
    Write-Host "----------------------------------------"
    
    try {
        & $ScanCommand
        Write-Host "✓ $ScanName completed successfully" -ForegroundColor Green
    } catch {
        Write-Host "⚠ $ScanName completed with warnings/errors" -ForegroundColor Yellow
    }
    Write-Host ""
}

# 1. Code Review Scan (Semgrep)
if (Test-Command "semgrep") {
    Run-Scan "Code Review (Semgrep)" {
        semgrep --config=auto --json --output="$ReportsDir\code-review-report_$Timestamp.json" --text --output="$ReportsDir\code-review-report_$Timestamp.txt" "$ProjectRoot"
    }
} else {
    Write-Host "⚠ Semgrep not found. Install with: pip install semgrep" -ForegroundColor Yellow
    Write-Host ""
}

# 2. Security Scan (Semgrep Security Rules)
if (Test-Command "semgrep") {
    Run-Scan "Security Scan (Semgrep Security)" {
        semgrep --config=p/security-audit --json --output="$ReportsDir\security-report_$Timestamp.json" --text --output="$ReportsDir\security-report_$Timestamp.txt" "$ProjectRoot"
    }
} else {
    Write-Host "⚠ Semgrep not found for security scan" -ForegroundColor Yellow
    Write-Host ""
}

# 3. Rust Vulnerability Scan (cargo audit)
if (Test-Command "cargo") {
    $CargoToml = Join-Path $ProjectRoot "android\rust\Cargo.toml"
    if (Test-Path $CargoToml) {
        Run-Scan "Rust Vulnerability Scan (cargo audit)" {
            Push-Location (Join-Path $ProjectRoot "android\rust")
            try {
                cargo audit --json | Out-File -FilePath "$ReportsDir\vulnerability-report-rust_$Timestamp.json" -Encoding utf8
            } catch {
                cargo audit | Out-File -FilePath "$ReportsDir\vulnerability-report-rust_$Timestamp.txt" -Encoding utf8
            }
            Pop-Location
        }
    } else {
        Write-Host "⚠ Rust Cargo.toml not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ cargo not found. Install Rust toolchain first" -ForegroundColor Yellow
    Write-Host ""
}

# 4. Python Vulnerability Scan (safety)
if (Test-Command "safety") {
    $RequirementsTxt = Join-Path $ProjectRoot "requirements.txt"
    if (-not (Test-Path $RequirementsTxt)) {
        $RequirementsTxt = Join-Path $ProjectRoot "ppt\requirements.txt"
    }
    if (Test-Path $RequirementsTxt) {
        Run-Scan "Python Vulnerability Scan (safety)" {
            try {
                safety check --json | Out-File -FilePath "$ReportsDir\vulnerability-report-python_$Timestamp.json" -Encoding utf8
            } catch {
                safety check | Out-File -FilePath "$ReportsDir\vulnerability-report-python_$Timestamp.txt" -Encoding utf8
            }
        }
    } else {
        Write-Host "⚠ Python requirements.txt not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ safety not found. Install with: pip install safety" -ForegroundColor Yellow
    Write-Host ""
}

# 5. Python Security Scan (bandit)
if (Test-Command "bandit") {
    $PythonDir = Join-Path $ProjectRoot "ppt"
    if (Test-Path $PythonDir) {
        Run-Scan "Python Security Scan (bandit)" {
            try {
                bandit -r "$PythonDir" -f json -o "$ReportsDir\security-report-python_$Timestamp.json"
            } catch {
                bandit -r "$PythonDir" -f txt -o "$ReportsDir\security-report-python_$Timestamp.txt"
            }
        }
    } else {
        Write-Host "⚠ Python source directory not found" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ bandit not found. Install with: pip install bandit" -ForegroundColor Yellow
    Write-Host ""
}

# 6. AI Code Proofreading
if (Test-Command "semgrep") {
    $ProofreadingJson = "$ReportsDir\ai-proofreading-report_$Timestamp.json"
    Run-Scan "AI Code Proofreading (Semgrep + Analysis)" {
        semgrep --config=auto --json --output="$ProofreadingJson" "$ProjectRoot"
        if (Test-Path $ProofreadingJson) {
            $PythonScript = Join-Path $ScriptDir "ai_proofreading.py"
            if (Test-Path $PythonScript) {
                python "$PythonScript" "$ProofreadingJson" "$ReportsDir\ai-proofreading-report_$Timestamp.txt"
            }
        }
    }
} else {
    Write-Host "⚠ Semgrep not found for AI proofreading" -ForegroundColor Yellow
    Write-Host ""
}

# Generate summary report
Write-Host "=========================================="
Write-Host "Scan Summary"
Write-Host "=========================================="
Write-Host "All scan reports saved to: $ReportsDir"
Write-Host ""
Write-Host "Generated reports:"
Get-ChildItem "$ReportsDir\*$Timestamp*" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  $($_.Name) ($([math]::Round($_.Length / 1KB, 2)) KB)"
}
Write-Host ""
Write-Host "=========================================="
Write-Host "Scanning complete!"
Write-Host "=========================================="

