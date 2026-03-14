#!/usr/bin/env python3
"""
Generic JaCoCo Coverage Comparison Tool

Compare current JaCoCo coverage against baseline.
Works with both Gradle and Maven projects.

Usage:
    python3 jacoco-compare.py                       # Use stored baseline
    python3 jacoco-compare.py --report path/to/index.html
    python3 jacoco-compare.py --baseline baseline.json
    python3 jacoco-compare.py --save-baseline       # Save current as baseline
    python3 jacoco-compare.py --set-baseline 75.0 60.0 65.0 73.0 70.0

Examples:
    # Gradle multi-module project
    python3 jacoco-compare.py --report core/build/jacocoHtml/index.html

    # Maven project
    python3 jacoco-compare.py --report target/site/jacoco/index.html

    # Set custom baseline
    python3 jacoco-compare.py --set-baseline 80.0 70.0 75.0 78.0 72.0
"""

import argparse
import os
import re
import sys

# Import shared utilities
from coverage_common import (
    calculate_percentages,
    load_baseline,
    save_baseline,
    compare_coverage,
    auto_bootstrap_baseline,
    exit_with_result,
    validate_report_exists
)

DEFAULT_GRADLE_REPORT = 'build/jacocoHtml/index.html'
DEFAULT_MAVEN_REPORT = 'target/site/jacoco/index.html'
BASELINE_FILE = '.jacoco-baseline.json'


def find_report():
    """Auto-discover JaCoCo report location."""
    candidates = [
        DEFAULT_GRADLE_REPORT,
        'build/reports/jacoco/test/html/index.html',  # Gradle default report path
        DEFAULT_MAVEN_REPORT,
        'core/build/jacocoHtml/index.html',  # Multi-module Gradle
    ]

    for path in candidates:
        if os.path.exists(path):
            return path

    return None


def parse_coverage_report(html_path):
    """Parse JaCoCo HTML report and extract coverage metrics."""
    validate_report_exists(
        html_path,
        "JaCoCo",
        [
            "Gradle: ./gradlew test jacocoTestReport",
            "Maven:  mvn test jacoco:report"
        ]
    )

    with open(html_path, 'r') as f:
        html = f.read()

    # Extract Total row from tfoot
    total_match = re.search(r'<tfoot><tr><td>Total</td>(.*?)</tr></tfoot>', html, re.DOTALL)
    if not total_match:
        print("❌ Could not parse coverage report")
        sys.exit(1)

    total_row = total_match.group(1)

    # Extract "X of Y" patterns (Instructions, Branches)
    bar_pattern = r'(\d+(?:,\d+)*) of (\d+(?:,\d+)*)'
    bars = re.findall(bar_pattern, total_row)

    # Extract complexity, lines, methods from ctr1/ctr2 pairs
    ctr_pattern = r'<td class="ctr1">(\d+(?:,\d+)*)</td><td class="ctr2">(\d+(?:,\d+)*)</td>'
    ctrs = re.findall(ctr_pattern, total_row)

    def parse_num(s):
        return int(s.replace(',', ''))

    if len(bars) < 2 or len(ctrs) < 3:
        print(f"❌ Unexpected report format")
        sys.exit(1)

    # Return raw metrics for calculate_percentages() from coverage_common
    return {
        'instructions_missed': parse_num(bars[0][0]),
        'instructions_total': parse_num(bars[0][1]),
        'branches_missed': parse_num(bars[1][0]),
        'branches_total': parse_num(bars[1][1]),
        'complexity_missed': parse_num(ctrs[0][0]),
        'complexity_total': parse_num(ctrs[0][1]),
        'lines_missed': parse_num(ctrs[1][0]),
        'lines_total': parse_num(ctrs[1][1]),
        'methods_missed': parse_num(ctrs[2][0]),
        'methods_total': parse_num(ctrs[2][1]),
    }


def main():
    parser = argparse.ArgumentParser(description='Compare JaCoCo coverage against baseline')
    parser.add_argument('--report', help='Path to JaCoCo index.html report')
    parser.add_argument('--baseline', default=BASELINE_FILE, help='Baseline file (default: .jacoco-baseline.json)')
    parser.add_argument('--save-baseline', action='store_true', help='Save current coverage as baseline')
    parser.add_argument('--set-baseline', nargs=5, type=float, metavar=('INST', 'BRANCH', 'CPLX', 'LINE', 'METHOD'),
                        help='Set baseline values manually (instructions branches complexity lines methods)')
    parser.add_argument('--tolerance', type=float, default=0.01, help='Tolerance for rounding (default: 0.01%%)')

    args = parser.parse_args()

    # Find report
    report_path = args.report or find_report()
    if not report_path:
        print("❌ Could not find JaCoCo report")
        print("\nSpecify location with --report, or run:")
        print("  Gradle: ./gradlew test jacocoTestReport")
        print("  Maven:  mvn test jacoco:report")
        sys.exit(1)

    # Parse current coverage
    metrics = parse_coverage_report(report_path)
    current = calculate_percentages(metrics)

    # Handle --save-baseline
    if args.save_baseline:
        save_baseline(current, args.baseline)
        return

    # Handle --set-baseline
    if args.set_baseline:
        baseline = {
            'instructions': args.set_baseline[0],
            'branches': args.set_baseline[1],
            'complexity': args.set_baseline[2],
            'lines': args.set_baseline[3],
            'methods': args.set_baseline[4],
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
