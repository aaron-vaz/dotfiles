#!/bin/bash
# Smart test runner that adapts to project type

set +e

# Get the project root (where git repo is)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT" || exit 0

# Only run if a source file was modified
if [[ "$CLAUDE_FILE_PATH" != *"/src/"* ]] && [[ "$CLAUDE_FILE_PATH" != *"/lib/"* ]]; then
  exit 0
fi

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