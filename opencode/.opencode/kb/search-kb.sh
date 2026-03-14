#!/bin/bash
# Search OpenCode Knowledge Base
# Usage: search-kb.sh [--status STATUS] [--project PROJECT] [--tag TAG] [--keyword KEYWORD] [--medium] [--list-tags] [--list-projects]

set -euo pipefail

KB_DIR="$HOME/.config/opencode/kb"
ENTRIES_DIR="$KB_DIR/entries"
INDEX_FILE="$KB_DIR/index.tsv"

# Parse arguments
STATUS=""
PROJECT=""
TAG=""
KEYWORD=""
MEDIUM=false
LIST_TAGS=false
LIST_PROJECTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --status) STATUS="$2"; shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        --tag) TAG="$2"; shift 2 ;;
        --keyword) KEYWORD="$2"; shift 2 ;;
        --medium) MEDIUM=true; shift ;;
        --list-tags) LIST_TAGS=true; shift ;;
        --list-projects) LIST_PROJECTS=true; shift ;;
        *) KEYWORD="$1"; shift ;;
    esac
done

# Rebuild index if entries newer than index
rebuild_index() {
    if [[ ! -f "$INDEX_FILE" ]] || [[ $(find "$ENTRIES_DIR" -name "*.md" -newer "$INDEX_FILE" 2>/dev/null | wc -l) -gt 0 ]]; then
        echo "date	status	project	tags	title	outcome	summary	file" > "$INDEX_FILE"
        for entry in "$ENTRIES_DIR"/*.md; do
            [[ -f "$entry" ]] || continue
            # Extract YAML frontmatter
            date=$(grep -m1 "^date:" "$entry" | cut -d: -f2- | xargs || echo "")
            status=$(grep -m1 "^status:" "$entry" | cut -d: -f2- | xargs || echo "")
            project=$(grep -m1 "^project:" "$entry" | cut -d: -f2- | xargs || echo "")
            tags=$(grep -m1 "^tags:" "$entry" | cut -d: -f2- | xargs || echo "")
            title=$(grep -m1 "^title:" "$entry" | cut -d: -f2- | xargs || echo "")
            outcome=$(grep -m1 "^outcome:" "$entry" | cut -d: -f2- | xargs || echo "")
            file=$(basename "$entry")
            echo -e "$date\t$status\t$project\t$tags\t$title\t$outcome\t$file" >> "$INDEX_FILE"
        done
    fi
}

# List all unique tags
if [[ "$LIST_TAGS" == "true" ]]; then
    rebuild_index
    cut -f4 "$INDEX_FILE" | tail -n +2 | tr ',' '\n' | tr -d '[]"' | sort -u
    exit 0
fi

# List all unique projects
if [[ "$LIST_PROJECTS" == "true" ]]; then
    rebuild_index
    cut -f3 "$INDEX_FILE" | tail -n +2 | sort -u
    exit 0
fi

# Search by criteria
rebuild_index

# Build filter chain
FILTER_CMD="cat"
[[ -n "$STATUS" ]] && FILTER_CMD="$FILTER_CMD | grep -i \"$STATUS\""
[[ -n "$PROJECT" ]] && FILTER_CMD="$FILTER_CMD | grep -i \"$PROJECT\""
[[ -n "$TAG" ]] && FILTER_CMD="$FILTER_CMD | grep -i \"$TAG\""
[[ -n "$KEYWORD" ]] && FILTER_CMD="$FILTER_CMD | grep -i \"$KEYWORD\""

# Execute search
if [[ "$MEDIUM" == "true" ]]; then
    # Medium output: title + summary from frontmatter
    eval "$FILTER_CMD \"$INDEX_FILE\"" | while IFS=$'\t' read -r date status project tags title outcome summary file; do
        [[ -n "$title" ]] || continue
        summary_fm=$(grep -m1 "^summary:" "$ENTRIES_DIR/$file" 2>/dev/null | cut -d: -f2- | xargs || echo "")
        echo "### $title"
        echo "Project: $project | Tags: $tags"
        echo "Summary: ${summary_fm:-$summary}"
        echo "File: $file"
        echo ""
    done
else
    # Default: just show matching lines from index
    eval "$FILTER_CMD \"$INDEX_FILE\"" | head -20
fi

# If keyword provided, also full-text search
if [[ -n "$KEYWORD" ]]; then
    echo ""
    echo "## Full-text matches:"
    grep -rl "$KEYWORD" "$ENTRIES_DIR" 2>/dev/null | head -5 | while read -r f; do
        echo "- $(basename "$f")"
    done
fi