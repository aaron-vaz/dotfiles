#!/usr/bin/env python3
"""
Render Mermaid diagrams in markdown files to PNG images.

Usage:
    python3 render_mermaid.py <markdown_file>

This script:
1. Extracts mermaid code blocks from the markdown file
2. Renders each to PNG using mmdc (mermaid-cli) locally
3. Replaces rendered code blocks with image references
4. Keeps unrendered code blocks with a note linking to an online renderer
5. Writes the updated markdown

Requirements:
- npm install -g @mermaid-js/mermaid-cli
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


# Mermaid configuration for consistent styling
# - default theme: standard light theme
# - basis curves: smooth B-spline routing that handles complex layouts well
MERMAID_CONFIG = """\
%%{init: {
  'theme': 'default',
  'themeVariables': {
    'primaryColor': '#ffffff',
    'primaryBorderColor': '#000000',
    'lineColor': '#000000',
    'textColor': '#000000',
    'fontFamily': 'arial',
    'fontSize': '14px'
  },
  'flowchart': {
    'curve': 'basis',
    'nodeSpacing': 30,
    'rankSpacing': 50,
    'padding': 15,
    'htmlLabels': true
  },
  'sequence': {'mirrorActors': false}
}}%%
"""

# Note appended after unrendered mermaid blocks
RENDER_HINT = (
    "\n> **Note:** This diagram could not be rendered locally because `mmdc` "
    "(mermaid-cli) is not installed.\n"
    "> Install it with `npm install -g @mermaid-js/mermaid-cli` and re-run the "
    "rendering script, or paste the Mermaid code into "
    "[Mermaid Live Editor](https://mermaid.live) to view it.\n"
)


def apply_mermaid_config(mermaid_code: str) -> str:
    """Prepend Mermaid configuration for default light theme and smooth basis curves.

    Skips if config already present.
    """
    if mermaid_code.strip().startswith('%%{init:'):
        return mermaid_code
    return MERMAID_CONFIG + mermaid_code


def extract_mermaid_blocks(content: str) -> list[tuple[str, int, int]]:
    """Extract mermaid code blocks from markdown content.

    Returns list of (mermaid_code, start_pos, end_pos) tuples.
    """
    pattern = r'```mermaid\r?\n(.*?)```'
    blocks = []

    for match in re.finditer(pattern, content, re.DOTALL):
        code = match.group(1).strip()
        if code:  # Skip empty mermaid blocks
            blocks.append((code, match.start(), match.end()))

    return blocks


def generate_diagram_name(mermaid_code: str, index: int) -> str:
    """Generate a unique name for the diagram based on content hash."""
    # Create a short hash of the content for uniqueness
    content_hash = hashlib.md5(mermaid_code.encode()).hexdigest()[:8]

    # Try to extract diagram type from first line
    first_line = mermaid_code.split('\n')[0].strip().lower()
    if first_line.startswith('graph') or first_line.startswith('flowchart'):
        diagram_type = 'flowchart'
    elif first_line.startswith('sequencediagram'):
        diagram_type = 'sequence'
    elif first_line.startswith('classdiagram'):
        diagram_type = 'class'
    elif first_line.startswith('statediagram'):
        diagram_type = 'state'
    elif first_line.startswith('erdiagram'):
        diagram_type = 'er'
    elif first_line.startswith('gantt'):
        diagram_type = 'gantt'
    elif first_line.startswith('pie'):
        diagram_type = 'pie'
    elif first_line.startswith('journey'):
        diagram_type = 'journey'
    elif first_line.startswith('mindmap'):
        diagram_type = 'mindmap'
    elif first_line.startswith('gitgraph'):
        diagram_type = 'gitgraph'
    elif first_line.startswith('timeline'):
        diagram_type = 'timeline'
    elif first_line.startswith('quadrantchart'):
        diagram_type = 'quadrant'
    elif first_line.startswith('requirementdiagram'):
        diagram_type = 'requirement'
    elif first_line.startswith('c4context') or first_line.startswith('c4container') or first_line.startswith('c4component') or first_line.startswith('c4dynamic'):
        diagram_type = 'c4'
    else:
        diagram_type = 'diagram'

    return f"{diagram_type}_{index + 1}_{content_hash}"


def render_with_mmdc(mermaid_code: str, output_path: Path) -> bool:
    """Render mermaid diagram using mermaid-cli (mmdc)."""
    # Check if mmdc is available
    if not shutil.which('mmdc'):
        return False

    with tempfile.NamedTemporaryFile(mode='w', suffix='.mmd', delete=False, encoding='utf-8') as f:
        f.write(mermaid_code)
        temp_input = f.name

    try:
        result = subprocess.run(
            ['mmdc', '-i', temp_input, '-o', str(output_path), '-b', 'transparent'],
            capture_output=True,
            text=True,
            timeout=30
        )
        return result.returncode == 0 and output_path.exists()
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        return False
    finally:
        try:
            os.unlink(temp_input)
        except OSError:
            pass


def render_diagram(mermaid_code: str, output_path: Path) -> bool:
    """Render a mermaid diagram to PNG using mmdc."""
    # Ensure output directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Apply styling config (default light theme, smooth curves)
    styled_code = apply_mermaid_config(mermaid_code)

    # Render with local mmdc
    if render_with_mmdc(styled_code, output_path):
        return True

    print("  mmdc not available. Install with: npm install -g @mermaid-js/mermaid-cli", file=sys.stderr)
    print("  Keeping mermaid code block with a note about online rendering.", file=sys.stderr)
    return False


def process_markdown_file(markdown_path: Path) -> bool:
    """Process a markdown file, rendering all mermaid diagrams.

    Returns True if all diagrams were rendered successfully.
    """
    if not markdown_path.exists():
        print(f"Error: File not found: {markdown_path}", file=sys.stderr)
        return False

    content = markdown_path.read_text(encoding='utf-8')
    blocks = extract_mermaid_blocks(content)

    if not blocks:
        print(f"No mermaid diagrams found in {markdown_path}")
        return True

    print(f"Found {len(blocks)} mermaid diagram(s) in {markdown_path}")

    # Determine output directory
    docs_dir = markdown_path.parent
    diagrams_dir = docs_dir / 'diagrams'
    diagrams_dir.mkdir(parents=True, exist_ok=True)

    # Process blocks in reverse order to maintain positions during replacement
    new_content = content
    all_success = True
    hint_added = False

    for i, (mermaid_code, start, end) in enumerate(reversed(blocks)):
        actual_index = len(blocks) - 1 - i
        diagram_name = generate_diagram_name(mermaid_code, actual_index)
        output_file = diagrams_dir / f"{diagram_name}.png"

        print(f"  Rendering diagram {actual_index + 1}/{len(blocks)}: {diagram_name}")

        if render_diagram(mermaid_code, output_file):
            # Calculate relative path from markdown file to image
            rel_path = f"diagrams/{diagram_name}.png"
            replacement = f"![{diagram_name}]({rel_path})"
            new_content = new_content[:start] + replacement + new_content[end:]
            print(f"    Success: {output_file}")
        else:
            # Keep the mermaid code block and append a rendering hint once
            if not hint_added:
                original_block = new_content[start:end]
                new_content = new_content[:end] + RENDER_HINT + new_content[end:]
                hint_added = True
            print(f"    Failed to render, keeping mermaid code block", file=sys.stderr)
            all_success = False

    # Write updated content if any changes were made
    if new_content != content:
        markdown_path.write_text(new_content, encoding='utf-8')
        print(f"Updated {markdown_path}")

    return all_success


def main():
    parser = argparse.ArgumentParser(
        description='Render Mermaid diagrams in markdown files to PNG images.'
    )
    parser.add_argument(
        'markdown_file',
        type=Path,
        help='Path to the markdown file containing mermaid diagrams'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Extract and show diagrams without rendering'
    )

    args = parser.parse_args()
    markdown_path = args.markdown_file.resolve()

    if not markdown_path.exists():
        print(f"Error: File not found: {markdown_path}", file=sys.stderr)
        return 1

    if args.dry_run:
        content = markdown_path.read_text(encoding='utf-8')
        blocks = extract_mermaid_blocks(content)
        print(f"Found {len(blocks)} mermaid diagram(s):")
        for i, (code, _, _) in enumerate(blocks):
            print(f"\n--- Diagram {i + 1} ---")
            print(code[:200] + '...' if len(code) > 200 else code)
        return 0

    success = process_markdown_file(markdown_path)
    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())
