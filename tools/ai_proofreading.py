#!/usr/bin/env python3
"""
AI Code Proofreading Tool
Analyzes code quality issues and provides suggestions for improvement.
"""

import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Any

def analyze_semgrep_results(semgrep_json_path: str) -> Dict[str, Any]:
    """Analyze Semgrep results and generate proofreading report."""
    try:
        with open(semgrep_json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        return {"error": f"File not found: {semgrep_json_path}"}
    except json.JSONDecodeError:
        return {"error": f"Invalid JSON in: {semgrep_json_path}"}
    
    results = data.get('results', [])
    
    # Categorize issues
    categories = {
        'security': [],
        'performance': [],
        'best_practices': [],
        'code_quality': [],
        'maintainability': [],
        'other': []
    }
    
    # Keywords for categorization
    security_keywords = ['security', 'vulnerability', 'injection', 'xss', 'csrf', 'auth', 'crypto', 'password', 'secret', 'key']
    performance_keywords = ['performance', 'slow', 'inefficient', 'optimization', 'memory', 'leak']
    best_practices_keywords = ['best-practice', 'convention', 'style', 'naming', 'documentation']
    maintainability_keywords = ['complexity', 'maintainability', 'readability', 'refactor']
    
    for result in results:
        check_id = result.get('check_id', '')
        message = result.get('message', '')
        severity = result.get('extra', {}).get('severity', 'INFO')
        
        issue = {
            'check_id': check_id,
            'message': message,
            'severity': severity,
            'path': result.get('path', ''),
            'start_line': result.get('start', {}).get('line', 0),
            'end_line': result.get('end', {}).get('line', 0),
        }
        
        # Categorize
        categorized = False
        text_lower = (check_id + ' ' + message).lower()
        
        if any(keyword in text_lower for keyword in security_keywords):
            categories['security'].append(issue)
            categorized = True
        elif any(keyword in text_lower for keyword in performance_keywords):
            categories['performance'].append(issue)
            categorized = True
        elif any(keyword in text_lower for keyword in best_practices_keywords):
            categories['best_practices'].append(issue)
            categorized = True
        elif any(keyword in text_lower for keyword in maintainability_keywords):
            categories['maintainability'].append(issue)
            categorized = True
        
        if not categorized:
            categories['code_quality'].append(issue)
    
    return {
        'total_issues': len(results),
        'categories': categories,
        'summary': {
            'security': len(categories['security']),
            'performance': len(categories['performance']),
            'best_practices': len(categories['best_practices']),
            'maintainability': len(categories['maintainability']),
            'code_quality': len(categories['code_quality']),
        }
    }

def generate_text_report(analysis: Dict[str, Any], output_path: str):
    """Generate human-readable text report."""
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("AI Code Proofreading Report\n")
        f.write("=" * 80 + "\n\n")
        
        if 'error' in analysis:
            f.write(f"Error: {analysis['error']}\n")
            return
        
        f.write(f"Total Issues Found: {analysis['total_issues']}\n\n")
        
        f.write("Summary by Category:\n")
        f.write("-" * 80 + "\n")
        summary = analysis['summary']
        f.write(f"  Security Issues:        {summary['security']}\n")
        f.write(f"  Performance Issues:      {summary['performance']}\n")
        f.write(f"  Best Practices:          {summary['best_practices']}\n")
        f.write(f"  Maintainability:         {summary['maintainability']}\n")
        f.write(f"  Code Quality:            {summary['code_quality']}\n")
        f.write("\n")
        
        categories = analysis['categories']
        
        # Security Issues
        if categories['security']:
            f.write("\n" + "=" * 80 + "\n")
            f.write("SECURITY ISSUES\n")
            f.write("=" * 80 + "\n\n")
            for issue in categories['security']:
                f.write(f"Severity: {issue['severity']}\n")
                f.write(f"File: {issue['path']}:{issue['start_line']}\n")
                f.write(f"Check: {issue['check_id']}\n")
                f.write(f"Message: {issue['message']}\n")
                f.write("-" * 80 + "\n")
        
        # Performance Issues
        if categories['performance']:
            f.write("\n" + "=" * 80 + "\n")
            f.write("PERFORMANCE ISSUES\n")
            f.write("=" * 80 + "\n\n")
            for issue in categories['performance']:
                f.write(f"Severity: {issue['severity']}\n")
                f.write(f"File: {issue['path']}:{issue['start_line']}\n")
                f.write(f"Check: {issue['check_id']}\n")
                f.write(f"Message: {issue['message']}\n")
                f.write("-" * 80 + "\n")
        
        # Best Practices
        if categories['best_practices']:
            f.write("\n" + "=" * 80 + "\n")
            f.write("BEST PRACTICES\n")
            f.write("=" * 80 + "\n\n")
            for issue in categories['best_practices']:
                f.write(f"Severity: {issue['severity']}\n")
                f.write(f"File: {issue['path']}:{issue['start_line']}\n")
                f.write(f"Check: {issue['check_id']}\n")
                f.write(f"Message: {issue['message']}\n")
                f.write("-" * 80 + "\n")
        
        # Maintainability
        if categories['maintainability']:
            f.write("\n" + "=" * 80 + "\n")
            f.write("MAINTAINABILITY ISSUES\n")
            f.write("=" * 80 + "\n\n")
            for issue in categories['maintainability']:
                f.write(f"Severity: {issue['severity']}\n")
                f.write(f"File: {issue['path']}:{issue['start_line']}\n")
                f.write(f"Check: {issue['check_id']}\n")
                f.write(f"Message: {issue['message']}\n")
                f.write("-" * 80 + "\n")
        
        # Code Quality
        if categories['code_quality']:
            f.write("\n" + "=" * 80 + "\n")
            f.write("CODE QUALITY ISSUES\n")
            f.write("=" * 80 + "\n\n")
            for issue in categories['code_quality'][:20]:  # Limit to first 20
                f.write(f"Severity: {issue['severity']}\n")
                f.write(f"File: {issue['path']}:{issue['start_line']}\n")
                f.write(f"Check: {issue['check_id']}\n")
                f.write(f"Message: {issue['message']}\n")
                f.write("-" * 80 + "\n")
            if len(categories['code_quality']) > 20:
                f.write(f"\n... and {len(categories['code_quality']) - 20} more code quality issues\n")
        
        f.write("\n" + "=" * 80 + "\n")
        f.write("End of Report\n")
        f.write("=" * 80 + "\n")

def main():
    if len(sys.argv) < 3:
        print("Usage: ai_proofreading.py <semgrep_json_file> <output_txt_file>")
        sys.exit(1)
    
    semgrep_json = sys.argv[1]
    output_txt = sys.argv[2]
    
    print(f"Analyzing Semgrep results from: {semgrep_json}")
    analysis = analyze_semgrep_results(semgrep_json)
    
    print(f"Generating report: {output_txt}")
    generate_text_report(analysis, output_txt)
    
    print("AI proofreading analysis complete!")

if __name__ == '__main__':
    main()

