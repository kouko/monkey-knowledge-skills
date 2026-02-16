#!/bin/bash
# _ensure_whisper.sh - Ensure whisper-cli is available
#
# Priority (consistent with other skills):
#   1. System-installed whisper-cli
#   2. Pre-built binary in bin/
#
# Usage:
#   source "$(dirname "$0")/_ensure_whisper.sh"
#   "$WHISPER" --help

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

get_whisper() {
    # 1. Prefer system-installed whisper-cli
    if command -v whisper-cli &> /dev/null; then
        echo "whisper-cli"
        return 0
    fi

    # 2. Check pre-built binary in bin/
    local binary_path="$BIN_DIR/whisper-cli"
    if [ -x "$binary_path" ]; then
        echo "$binary_path"
        return 0
    fi

    # 3. Not available
    echo "ERROR: whisper-cli not found" >&2
    echo "Run: ./scripts/_build_whisper.sh" >&2
    exit 1
}

# Get whisper-cli path
WHISPER="$(get_whisper)"
