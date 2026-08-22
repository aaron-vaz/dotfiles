#!/bin/bash
# Smart test runner that adapts to project type

set +e

# Tool input arrives as JSON on stdin — see validate-git-usage.sh for the
# contract note. This hook previously read $CLAUDE_FILE_PATH, which is never
# set, so both `!=` tests below were always true and it exited 0 without ever
# running a test.
FILE_PATH="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"
FILE_PATH="${FILE_PATH:-${CLAUDE_FILE_PATH:-}}"

# Only run if a source file was modified
if [[ "$FILE_PATH" != *"/src/"* ]] && [[ "$FILE_PATH" != *"/lib/"* ]]; then
  exit 0
fi

# Get the project root (where git repo is)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT" || exit 0

# Detect project type and run appropriate test command
if [[ -f "build.gradle.kts" ]] || [[ -f "build.gradle" ]]; then
  # Gradle/Kotlin/Java
  ./gradlew test --quiet 2>&1 | tail -3
elif [[ -f "package.json" ]]; then
  # Node/TypeScript
  npm test --silent 2>&1 | tail -3
elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
  # Python
  pytest --quiet 2>&1 | tail -3
elif [[ -f "Cargo.toml" ]]; then
  # Rust
  cargo test --quiet 2>&1 | tail -3
elif [[ -f "go.mod" ]]; then
  # Go
  go test ./... 2>&1 | tail -3
else
  # Unknown project type, skip silently
  exit 0
fi

exit 0
