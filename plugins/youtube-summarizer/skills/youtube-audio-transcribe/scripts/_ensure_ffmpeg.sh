#!/bin/bash
# _ensure_ffmpeg.sh - Ensure ffmpeg is available
#
# Priority (consistent with other skills):
#   1. System-installed ffmpeg
#   2. Pre-built binary in bin/
#
# Usage:
#   source "$(dirname "$0")/_ensure_ffmpeg.sh"
#   "$FFMPEG" -version

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

get_ffmpeg() {
    # 1. Prefer system-installed ffmpeg
    if command -v ffmpeg &> /dev/null; then
        echo "ffmpeg"
        return 0
    fi

    # 2. Check pre-built binary in bin/
    local binary_path="$BIN_DIR/ffmpeg"
    if [ -x "$binary_path" ]; then
        echo "$binary_path"
        return 0
    fi

    # 3. Not available
    echo "ERROR: ffmpeg not found" >&2
    echo "Install with: brew install ffmpeg" >&2
    echo "Or run: ./scripts/_download_ffmpeg.sh" >&2
    exit 1
}

# Get ffmpeg path
FFMPEG="$(get_ffmpeg)"
