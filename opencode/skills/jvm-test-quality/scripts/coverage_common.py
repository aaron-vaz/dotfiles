#!/usr/bin/env python3
"""
Common utilities for coverage comparison tools.

Provides shared functionality for JaCoCo, Scoverage, and other coverage tools:
- Baseline management (save/load)
- Coverage comparison logic
- Percentage calculations
- CLI utilities
"""

import json
import os
import sys
from typing import Dict, List, Optional


def calculate_percentages(metrics: Dict[str, int]) -> Dict[str, float]:
    """
    Calculate coverage percentages from raw metrics.

    Args:
        metrics: Dict with *_missed and *_total keys

    Returns:
        Dict with percentage values for each metric
    """
    result = {}

    for key in ['instructions', 'branches', 'complexity', 'lines', 'methods']:
        missed_key = f'{key}_missed'
        total_key = f'{key}_total'

        if missed_key in metrics and total_key in metrics:
            total = metrics[total_key]
            if total > 0:
                missed = metrics[missed_key]
                result[key] = ((total - missed) / total) * 100
            else:
                result[key] = 0.0

    return result


def calculate_percentages_from_rates(rates: Dict[str, float]) -> Dict[str, float]:
    """
    Convert decimal rates (0.0-1.0) to percentages (0.0-100.0).

    Args:
        rates: Dict with decimal rate values (e.g., line_rate: 0.85)

    Returns:
        Dict with percentage values (e.g., instructions: 85.0)
    """
    return {key: value * 100 for key, value in rates.items()}


def load_baseline(baseline_file: str) -> Optional[Dict[str, float]]:
    """
    Load baseline coverage from file.

    Args:
        baseline_file: Path to baseline JSON file

    Returns:
        Dict with coverage percentages, or None if file doesn't exist/is invalid
    """
    if not os.path.exists(baseline_file):
        return None

    try:
        with open(baseline_file, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError:
        print(f"⚠️  Invalid baseline file: {baseline_file}")
        return None
    except Exception as e:
        print(f"⚠️  Error loading baseline: {e}")
        return None


def save_baseline(baseline: Dict[str, float], baseline_file: str) -> None:
    """
    Save baseline coverage to file.

    Args:
        baseline: Dict with coverage percentages
        baseline_file: Path to baseline JSON file
    """
    with open(baseline_file, 'w') as f:
        json.dump(baseline, f, indent=2)
    print(f"💾 Baseline saved to {baseline_file}")


def compare_coverage(
    current: Dict[str, float],
    baseline: Dict[str, float],
    tolerance: float = 0.01
) -> bool:
    """
    Compare current coverage against baseline.

    Args:
        current: Current coverage percentages
        baseline: Baseline coverage percentages
        tolerance: Tolerance for rounding errors (default: 0.01%)

    Returns:
        True if all metrics maintained or improved, False otherwise
    """
    print("📊 Coverage Comparison")
    print("=" * 70)
    print(f"{'Metric':<15} {'Baseline':>10} {'Current':>10} {'Change':>12} {'Status':>8}")
    print("-" * 70)

    all_pass = True
    for key in ['instructions', 'branches', 'complexity', 'lines', 'methods']:
        if key in current and key in baseline:
            diff = current[key] - baseline[key]
            status = '✅' if diff >= -tolerance else '❌'
            if diff < -tolerance:
                all_pass = False
            print(f"{key.capitalize():<15} {baseline[key]:>9.2f}% {current[key]:>9.2f}% {diff:>+11.2f}% {status:>7}")

    print("=" * 70)
    return all_pass


def print_current_coverage(current: Dict[str, float]) -> None:
    """
    Print current coverage metrics.

    Args:
        current: Current coverage percentages
    """
    print("\n📊 Current coverage:")
    for key, value in current.items():
        print(f"  {key.capitalize()}: {value:.2f}%")


def auto_bootstrap_baseline(
    current: Dict[str, float],
    baseline_file: str
) -> None:
    """
    Auto-create baseline on first run if it doesn't exist.

    Args:
        current: Current coverage percentages
        baseline_file: Path to baseline JSON file
    """
    print(f"ℹ️  No baseline found at {baseline_file}. Creating from current report.")
    save_baseline(current, baseline_file)
    print_current_coverage(current)
    print("\nRun again after making changes to compare against this baseline.")


def exit_with_result(all_pass: bool) -> None:
    """
    Exit with appropriate code based on comparison result.

    Args:
        all_pass: Whether all metrics passed
    """
    if all_pass:
        print("✅ All coverage metrics maintained or improved!")
        sys.exit(0)
    else:
        print("❌ Some coverage metrics decreased")
        sys.exit(1)


def validate_report_exists(report_path: str, tool_name: str, commands: List[str]) -> None:
    """
    Validate that coverage report exists, exit with helpful message if not.

    Args:
        report_path: Path to coverage report
        tool_name: Name of the tool (e.g., "JaCoCo", "Scoverage")
        commands: List of commands to suggest for generating report
    """
    if not os.path.exists(report_path):
        print(f"❌ {tool_name} report not found at {report_path}")
        print("\nTry:")
        for cmd in commands:
            print(f"  {cmd}")
        sys.exit(1)
