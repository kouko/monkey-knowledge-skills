#!/bin/bash
# _download_ffmpeg.sh - Download ffmpeg binary for macOS
#
# Downloads ffmpeg from evermeet.cx (x86_64) or builds universal binary
#
# Usage:
#   ./scripts/_download_ffmpeg.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Only support macOS
if [ "$(uname -s)" != "Darwin" ]; then
    echo "ERROR: This script is for macOS only" >&2
    exit 1
fi

download_ffmpeg() {
    echo "[INFO] Downloading ffmpeg..." >&2
    mkdir -p "$BIN_DIR"

    local temp_dir="/tmp/ffmpeg-download-$$"
    mkdir -p "$temp_dir"

    # Download from evermeet.cx (provides macOS binaries)
    local download_url="https://evermeet.cx/ffmpeg/getrelease/ffmpeg/zip"

    echo "[INFO] Downloading from evermeet.cx..." >&2
    curl -L -o "$temp_dir/ffmpeg.zip" "$download_url"

    echo "[INFO] Extracting..." >&2
    unzip -q "$temp_dir/ffmpeg.zip" -d "$temp_dir"

    # Find and copy the binary
    local ffmpeg_bin
    ffmpeg_bin=$(find "$temp_dir" -name "ffmpeg" -type f -perm +111 | head -1)

    if [ -z "$ffmpeg_bin" ]; then
        echo "ERROR: ffmpeg binary not found in archive" >&2
        rm -rf "$temp_dir"
        exit 1
    fi

    cp "$ffmpeg_bin" "$BIN_DIR/ffmpeg"
    chmod +x "$BIN_DIR/ffmpeg"

    echo "[INFO] Cleaning up..." >&2
    rm -rf "$temp_dir"

    echo "[INFO] ffmpeg installed: $BIN_DIR/ffmpeg" >&2
}

download_ffmpeg

echo "[SUCCESS] Download complete!" >&2
"$BIN_DIR/ffmpeg" -version 2>&1 | head -1
