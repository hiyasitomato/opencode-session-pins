#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-opencode-v2.4.1-repo>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="${SCRIPT_DIR}/../patches/opencode-v2.4.1-home-session-pins.patch"
REPO_PATH="$(cd "$1" && pwd)"

echo "Checking patch against ${REPO_PATH} ..."
git -C "${REPO_PATH}" apply --check "${PATCH_FILE}"

echo "Applying patch..."
git -C "${REPO_PATH}" apply "${PATCH_FILE}"

cat <<EOF

Patch applied cleanly.
Next steps:
  cd "${REPO_PATH}"
  bun install
  OPENCODE_CHANNEL=latest OPENCODE_VERSION=2.4.1-pins.1 bun run --cwd packages/cli build --single --baseline
  OPENCODE_CHANNEL=latest OPENCODE_VERSION=2.4.1-pins.1 bun run --cwd packages/desktop build
EOF
