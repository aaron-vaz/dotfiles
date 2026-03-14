#!/usr/bin/env python3
"""
Scoverage Coverage Comparison Tool

Compare current Scoverage coverage against baseline.
Works with both Maven and SBT Scala projects.

Scoverage generates both scoverage.xml (native format) and cobertura.xml
(Cobertura-compatible format). This tool uses cobertura.xml for consistent
parsing with decimal rates (0.0-1.0).

Usage:
    python3 scoverage-compare.py                       # Use stored baseline
    python3 scoverage-compare.py --report path/to/cobertura.xml
    python3 scoverage-compare.py --baseline baseline.json
    python3 scoverage-compare.py --save-baseline       # Save current as baseline
    python3 scoverage-compare.py --set-baseline 75.0 60.0 73.0 70.0

Examples:
    # Maven multi-module project (aggregated report)
    python3 scoverage-compare.py --report target/cobertura.xml

    # Maven single module
    python3 scoverage-compare.py --report target/scoverage-report/cobertura.xml

    # SBT project
    python3 scoverage-compare.py --report target/scala-2.13/scoverage-report/cobertura.xml

    # Set custom baseline (instructions branches lines methods)
    python3 scoverage-compare.py --set-baseline 80.0 70.0 78.0 72.0
"""

import argparse
import os
import sys
import xml.etree.ElementTree as ET

# Import shared utilities
from coverage_common import (
    load_baseline,
    save_baseline,
    compare_coverage,
    auto_bootstrap_baseline,
    exit_with_result,
    validate_report_exists
)

DEFAULT_MAVEN_REPORT = 'target/cobertura.xml'
DEFAULT_SBT_REPORT = 'target/scala-2.13/scoverage-report/cobertura.xml'
BASELINE_FILE = '.scoverage-baseline.json'


def find_report():
    """
    Auto-discover Scoverage report location.

    Scoverage generates both scoverage.xml (native format) and cobertura.xml
    (Cobertura-compatible format). We use cobertura.xml for consistent parsing.
    """
    candidates = [
        DEFAULT_MAVEN_REPORT,  # Maven multi-module aggregated report
        'target/scoverage-report/cobertura.xml',  # Maven single module
        DEFAULT_SBT_REPORT,  # SBT with Scala 2.13
        'target/scala-2.12/scoverage-report/cobertura.xml',  # SBT with Scala 2.12
        'target/scala-2.11/scoverage-report/cobertura.xml',  # SBT with Scala 2.11
    ]

    for path in candidates:
        if os.path.exists(path):
            return path

    return None


def parse_coverage_report(xml_path):
    """
    Parse Scoverage/Cobertura XML report and extract coverage metrics.

    Scoverage generates Cobertura-compatible XML with structure:
    <coverage line-rate="0.85" branch-rate="0.70" ...>

    Returns:
        Dict with coverage percentages (0-100 scale)
    """
    validate_report_exists(
        xml_path,
        "Scoverage",
        [
            "Maven:  mvn test scoverage:report",
            "SBT:    sbt clean coverage test coverageReport"
        ]
    )

    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
    except ET.ParseError as e:
        print(f"❌ Failed to parse XML report: {e}")
        sys.exit(1)

    # Extract coverage metrics from root element
    # Cobertura XML uses decimal rates (0.0-1.0), convert to percentages
    line_rate = float(root.get('line-rate', 0)) * 100
    branch_rate = float(root.get('branch-rate', 0)) * 100
    # Note: Cobertura XML 'complexity' is a raw count (total cyclomatic complexity),
    # NOT a rate. It cannot be meaningfully compared as a percentage.

    # Calculate method coverage from XML if available
    # Parse all classes to count methods
    total_methods = 0
    covered_methods = 0

    for cls in root.findall('.//class'):
        for method in cls.findall('.//method'):
            total_methods += 1
            # A method is covered if it has at least one line with hits > 0
            method_lines = method.findall('.//line')
            if any(int(line.get('hits', 0)) > 0 for line in method_lines):
                covered_methods += 1

    method_coverage = (covered_methods / total_methods * 100) if total_methods > 0 else 0

    return {
        'instructions': line_rate,       # Map line-rate to instructions for consistency
        'branches': branch_rate,
        'lines': line_rate,              # Scoverage: lines and statements are the same
        'methods': method_coverage,
    }


def main():
    parser = argparse.ArgumentParser(
        description='Compare Scoverage coverage against baseline',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('--report', help='Path to Scoverage cobertura.xml report')
    parser.add_argument('--baseline', default=BASELINE_FILE, help=f'Baseline file (default: {BASELINE_FILE})')
    parser.add_argument('--save-baseline', action='store_true', help='Save current coverage as baseline')
    parser.add_argument('--set-baseline', nargs=4, type=float, metavar=('INST', 'BRANCH', 'LINE', 'METHOD'),
                        help='Set baseline values manually (instructions branches lines methods)')
    parser.add_argument('--tolerance', type=float, default=0.01, help='Tolerance for rounding (default: 0.01%%)')

    args = parser.parse_args()

    # Find report
    report_path = args.report or find_report()
    if not report_path:
        print("❌ Could not find Scoverage report")
        print("\nSpecify location with --report, or run:")
        print("  Maven:  mvn test scoverage:report")
        print("  SBT:    sbt clean coverage test coverageReport")
        sys.exit(1)

    # Parse current coverage
    current = parse_coverage_report(report_path)

    # Handle --save-baseline
    if args.save_baseline:
        save_baseline(current, args.baseline)
        return

    # Handle --set-baseline
    if args.set_baseline:
        baseline = {
            'instructions': args.set_baseline[0],
            'branches': args.set_baseline[1],
            'lines': args.set_baseline[2],
            'methods': args.set_baseline[3],
        }
        save_baseline(baseline, args.baseline)
        print("\n📊 New baseline:")
        for key, value in baseline.items():
            print(f"  {key.capitalize()}: {value:.2f}%")
        return

    # Load baseline
    baseline = load_baseline(args.baseline)
    if not baseline:
        # Auto-bootstrap: save current as baseline on first run
        auto_bootstrap_baseline(current, args.baseline)
        return

    # Compare
    all_pass = compare_coverage(current, baseline, args.tolerance)
    exit_with_result(all_pass)


if __name__ == '__main__':
    main()
