#!/usr/bin/env bash
# Search tagged memory files across all projects

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

MEMORY_ROOT="$HOME/.claude/projects"

usage() {
    cat << EOF
${CYAN}search-memories.sh${NC} - Search tagged memory files across projects

${YELLOW}USAGE:${NC}
    search-memories.sh [OPTIONS] QUERY

${YELLOW}OPTIONS:${NC}
    --tag TAG           Search for specific tag (e.g., #debugging, #jvm)
    --relevance LEVEL   Filter by relevance (project-specific, cross-project, tool-specific)
    --project NAME      Search only in specific project
    --domain            Show only domain tags (#jvm, #kotlin, #sql, etc.)
    --activity          Show only activity tags (#debugging, #refactoring, etc.)
    --tool              Show only tool tags (#git, #gradle, #github, etc.)
    --list-tags         List all tags used across projects
    --list-projects     List all projects with memories
    --help              Show this help message

${YELLOW}EXAMPLES:${NC}
    # Find all debugging memories
    search-memories.sh --tag debugging

    # Find cross-project patterns
    search-memories.sh --relevance cross-project

    # Find JVM debugging patterns
    search-memories.sh --tag jvm --tag debugging

    # Search for keyword in memories
    search-memories.sh "gradle build"

    # Find memories in specific project
    search-memories.sh --project REDACTED "metric ID"

    # List all available tags
    search-memories.sh --list-tags

    # List all projects with memories
    search-memories.sh --list-projects

${YELLOW}TAG CATEGORIES:${NC}
    ${GREEN}Domain:${NC}   #jvm, #kotlin, #java, #sql, #trino, #testing, #experimentation
    ${GREEN}Activity:${NC} #debugging, #refactoring, #architecture, #ci-cd, #build, #deployment
    ${GREEN}Tool:${NC}     #git, #gradle, #maven, #github, #jira, #confluence
    ${GREEN}Scope:${NC}    project-specific, cross-project, tool-specific (use --relevance)

EOF
    exit 0
}

list_tags() {
    echo -e "${CYAN}=== All Tags Across Projects ===${NC}\n"

    # Extract all tags from memory files
    find "$MEMORY_ROOT" -path "*/memory/*.md" -type f -exec grep -h "^**Tags:**" {} \; 2>/dev/null | \
        sed 's/\*\*Tags:\*\* //' | \
        tr ',' '\n' | \
        tr ' ' '\n' | \
        grep '^#' | \
        sort -u | \
        column -c 80

    echo ""
    exit 0
}

list_projects() {
    echo -e "${CYAN}=== Projects with Memory Files ===${NC}\n"

    find "$MEMORY_ROOT" -type d -name "memory" 2>/dev/null | while read -r dir; do
        project_path=$(dirname "$dir")
        project_name=$(basename "$project_path")
        file_count=$(find "$dir" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${GREEN}$project_name${NC} (${file_count} files)"
    done

    echo ""
    exit 0
}

# Parse arguments
TAGS=()
RELEVANCE=""
PROJECT=""
QUERY=""
FILTER_TYPE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            usage
            ;;
        --tag)
            # Remove leading # if provided
            TAG="${2#\#}"
            TAGS+=("#$TAG")
            shift 2
            ;;
        --relevance)
            RELEVANCE="$2"
            shift 2
            ;;
        --project)
            PROJECT="$2"
            shift 2
            ;;
        --domain)
            FILTER_TYPE="domain"
            shift
            ;;
        --activity)
            FILTER_TYPE="activity"
            shift
            ;;
        --tool)
            FILTER_TYPE="tool"
            shift
            ;;
        --list-tags)
            list_tags
            ;;
        --list-projects)
            list_projects
            ;;
        *)
            QUERY="$1"
            shift
            ;;
    esac
done

# Build search path
if [[ -n "$PROJECT" ]]; then
    SEARCH_PATH=$(find "$MEMORY_ROOT" -type d -name "memory" | grep -i "$PROJECT" | head -1)
    if [[ -z "$SEARCH_PATH" ]]; then
        echo -e "${RED}Error: Project '$PROJECT' not found${NC}" >&2
        exit 1
    fi
else
    SEARCH_PATH="$MEMORY_ROOT"
fi

# Execute search based on options
if [[ ${#TAGS[@]} -gt 0 ]]; then
    # Tag-based search
    echo -e "${CYAN}=== Searching for tags: ${TAGS[*]} ===${NC}\n"

    # Build grep pattern for multiple tags
    TAG_PATTERN=$(printf "%s.*" "${TAGS[@]}")
    TAG_PATTERN=${TAG_PATTERN%.*}  # Remove trailing .*

    FILES=$(find "$SEARCH_PATH" -path "*/memory/*.md" -type f -exec grep -l "Tags:.*$TAG_PATTERN" {} \; 2>/dev/null)

elif [[ -n "$RELEVANCE" ]]; then
    # Relevance-based search
    echo -e "${CYAN}=== Searching for relevance: $RELEVANCE ===${NC}\n"

    FILES=$(find "$SEARCH_PATH" -path "*/memory/*.md" -type f -exec grep -l "Relevance: $RELEVANCE" {} \; 2>/dev/null)

elif [[ -n "$QUERY" ]]; then
    # Keyword search
    echo -e "${CYAN}=== Searching for: $QUERY ===${NC}\n"

    FILES=$(find "$SEARCH_PATH" -path "*/memory/*.md" -type f -exec grep -li "$QUERY" {} \; 2>/dev/null)

elif [[ -n "$FILTER_TYPE" ]]; then
    # Filter by tag type
    case $FILTER_TYPE in
        domain)
            echo -e "${CYAN}=== Domain Tags ===${NC}\n"
            PATTERN="#(jvm|kotlin|java|sql|trino|testing|experimentation)"
            ;;
        activity)
            echo -e "${CYAN}=== Activity Tags ===${NC}\n"
            PATTERN="#(debugging|refactoring|architecture|ci-cd|build|deployment)"
            ;;
        tool)
            echo -e "${CYAN}=== Tool Tags ===${NC}\n"
            PATTERN="#(git|gradle|maven|github|jira|confluence)"
            ;;
    esac

    FILES=$(find "$SEARCH_PATH" -path "*/memory/*.md" -type f -exec grep -lE "Tags:.*$PATTERN" {} \; 2>/dev/null)
else
    echo -e "${RED}Error: No search criteria provided${NC}" >&2
    echo "Use --help for usage information" >&2
    exit 1
fi

# Display results
if [[ -z "$FILES" ]]; then
    echo -e "${YELLOW}No matches found${NC}"
    exit 0
fi

echo "$FILES" | while read -r file; do
    # Extract project name from path
    PROJECT_PATH=$(echo "$file" | sed "s|$MEMORY_ROOT/||" | cut -d'/' -f1)
    FILE_NAME=$(basename "$file")

    echo -e "${GREEN}Project: ${NC}$PROJECT_PATH"
    echo -e "${BLUE}File:    ${NC}$FILE_NAME"

    # Extract and display tags
    TAGS_LINE=$(grep "^**Tags:**" "$file" 2>/dev/null || echo "")
    if [[ -n "$TAGS_LINE" ]]; then
        echo -e "${MAGENTA}Tags:    ${NC}${TAGS_LINE#**Tags:** }"
    fi

    # Extract and display relevance
    REL_LINE=$(grep "^**Relevance:**" "$file" 2>/dev/null || echo "")
    if [[ -n "$REL_LINE" ]]; then
        echo -e "${CYAN}Scope:   ${NC}${REL_LINE#**Relevance:** }"
    fi

    # Show snippet with matches if keyword search
    if [[ -n "$QUERY" ]]; then
        echo -e "${YELLOW}Snippet:${NC}"
        grep -i --color=always -C 2 "$QUERY" "$file" 2>/dev/null | head -10 | sed 's/^/  /'
    fi

    echo -e "${YELLOW}Path:    ${NC}$file"
    echo ""
done

# Summary
COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
echo -e "${CYAN}=== Found $COUNT matching file(s) ===${NC}"
