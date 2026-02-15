#!/bin/bash
# _build_whisper.sh - Build whisper.cpp with CoreML + Metal (macOS)
#
# This script:
#   1. Clones whisper.cpp repository
#   2. Builds with CoreML and Metal acceleration
#   3. Copies binary to bin/
#   4. Cleans up source code
#
# Usage:
#   ./scripts/_build_whisper.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"
BUILD_DIR="/tmp/whisper-cpp-build-$$"

# Only support macOS
if [ "$(uname -s)" != "Darwin" ]; then
    echo "ERROR: This script is for macOS only" >&2
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    if ! xcode-select -p &>/dev/null; then
        echo "ERROR: Xcode CLI tools required" >&2
        echo "Run: xcode-select --install" >&2
        exit 1
    fi

    if ! command -v cmake &>/dev/null; then
        echo "ERROR: cmake required" >&2
        echo "Run: brew install cmake" >&2
        exit 1
    fi

    if ! command -v git &>/dev/null; then
        echo "ERROR: git required" >&2
        exit 1
    fi
}

build_whisper() {
    echo "[INFO] Cloning whisper.cpp..." >&2
    git clone --depth 1 https://github.com/ggml-org/whisper.cpp.git "$BUILD_DIR"
    cd "$BUILD_DIR"

    echo "[INFO] Building with Metal (static linking)..." >&2
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DGGML_METAL=ON \
        -DBUILD_SHARED_LIBS=OFF

    cmake --build build -j"$(sysctl -n hw.ncpu)"

    echo "[INFO] Installing binary..." >&2
    mkdir -p "$BIN_DIR"
    cp build/bin/whisper-cli "$BIN_DIR/whisper-cli"
    chmod +x "$BIN_DIR/whisper-cli"

    echo "[INFO] Cleaning up..." >&2
    cd /
    rm -rf "$BUILD_DIR"

    echo "[INFO] whisper-cli installed: $BIN_DIR/whisper-cli" >&2
    echo "[INFO] Build options: Metal=ON, Static=ON" >&2
}

check_prerequisites
build_whisper

echo "[SUCCESS] Build complete!" >&2
"$BIN_DIR/whisper-cli" --version 2>&1 || true
