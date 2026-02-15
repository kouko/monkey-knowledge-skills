#!/bin/bash
# download-model.sh - Download whisper model
#
# Downloads model from Hugging Face with progress bar.
# Run this in terminal to see download progress.
#
# Usage:
#   ./scripts/download-model.sh <model_name>
#   ./scripts/download-model.sh --list
#
# Examples:
#   ./scripts/download-model.sh medium      # Download medium model (1.5GB)
#   ./scripts/download-model.sh belle-zh    # Download Chinese model
#   ./scripts/download-model.sh kotoba-ja   # Download Japanese model
#   ./scripts/download-model.sh --list      # List available models

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$SCRIPT_DIR/../models"

# Hugging Face base URL
HF_BASE_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

# Get model size
get_model_size() {
    local name="$1"
    case "$name" in
        tiny|tiny.en)         echo "75MB" ;;
        base|base.en)         echo "142MB" ;;
        small|small.en)       echo "466MB" ;;
        medium|medium.en)     echo "1.5GB" ;;
        large-v1|large-v2|large-v3) echo "2.9GB" ;;
        large-v3-turbo)       echo "1.5GB" ;;
        belle-zh)             echo "1.5GB" ;;
        kotoba-ja)            echo "1.5GB" ;;
        kotoba-ja-q5)         echo "600MB" ;;
        *)                    echo "unknown" ;;
    esac
}

# Get model description
get_model_description() {
    local name="$1"
    case "$name" in
        tiny)           echo "Fastest, lowest accuracy" ;;
        base)           echo "Fast, moderate accuracy" ;;
        small)          echo "Balanced speed/accuracy" ;;
        medium)         echo "High accuracy (recommended for general use)" ;;
        large-v3)       echo "Best accuracy, slowest" ;;
        large-v3-turbo) echo "Large model optimized for speed" ;;
        belle-zh)       echo "Chinese-specialized (recommended for zh)" ;;
        kotoba-ja)      echo "Japanese-specialized (recommended for ja)" ;;
        kotoba-ja-q5)   echo "Japanese-specialized, quantized (faster)" ;;
        *)              echo "" ;;
    esac
}

# Show available models
show_models() {
    echo "Available models:"
    echo ""
    echo "Standard Models:"
    printf "  %-16s %-10s %s\n" "MODEL" "SIZE" "DESCRIPTION"
    printf "  %-16s %-10s %s\n" "-----" "----" "-----------"
    for model in tiny base small medium large-v3 large-v3-turbo; do
        printf "  %-16s %-10s %s\n" "$model" "$(get_model_size "$model")" "$(get_model_description "$model")"
    done
    echo ""
    echo "Language-Specialized Models:"
    printf "  %-16s %-10s %s\n" "MODEL" "SIZE" "DESCRIPTION"
    printf "  %-16s %-10s %s\n" "-----" "----" "-----------"
    for model in belle-zh kotoba-ja kotoba-ja-q5; do
        printf "  %-16s %-10s %s\n" "$model" "$(get_model_size "$model")" "$(get_model_description "$model")"
    done
    echo ""
    echo "Usage: $0 <model_name>"
}

# Map model name to local filename
get_model_filename() {
    local name="$1"
    case "$name" in
        tiny|tiny.en)     echo "ggml-${name}.bin" ;;
        base|base.en)     echo "ggml-${name}.bin" ;;
        small|small.en)   echo "ggml-${name}.bin" ;;
        medium|medium.en) echo "ggml-${name}.bin" ;;
        large|large-v1)   echo "ggml-large-v1.bin" ;;
        large-v2)         echo "ggml-large-v2.bin" ;;
        large-v3)         echo "ggml-large-v3.bin" ;;
        large-v3-turbo)   echo "ggml-large-v3-turbo.bin" ;;
        belle-zh)         echo "ggml-belle-zh.bin" ;;
        kotoba-ja)        echo "ggml-kotoba-ja.bin" ;;
        kotoba-ja-q5)     echo "ggml-kotoba-ja-q5.bin" ;;
        *)
            echo ""
            ;;
    esac
}

# Get download URL for model
get_model_url() {
    local name="$1"
    case "$name" in
        belle-zh)
            echo "https://huggingface.co/BELLE-2/Belle-whisper-large-v3-turbo-zh-ggml/resolve/main/ggml-model.bin"
            ;;
        kotoba-ja)
            echo "https://huggingface.co/kotoba-tech/kotoba-whisper-v2.0-ggml/resolve/main/ggml-kotoba-whisper-v2.0.bin"
            ;;
        kotoba-ja-q5)
            echo "https://huggingface.co/kotoba-tech/kotoba-whisper-v2.0-ggml/resolve/main/ggml-kotoba-whisper-v2.0-q5_0.bin"
            ;;
        *)
            local filename
            filename=$(get_model_filename "$name")
            echo "$HF_BASE_URL/$filename"
            ;;
    esac
}

# Download model
download_model() {
    local model_name="$1"
    local filename
    filename=$(get_model_filename "$model_name")

    if [ -z "$filename" ]; then
        echo "ERROR: Unknown model: $model_name" >&2
        echo "" >&2
        show_models >&2
        exit 1
    fi

    local model_path="$MODELS_DIR/$filename"
    local download_url
    download_url=$(get_model_url "$model_name")
    local model_size
    model_size=$(get_model_size "$model_name")

    # Check if already downloaded
    if [ -f "$model_path" ]; then
        echo "[INFO] Model already exists: $model_path"
        echo "[INFO] Size: $(du -h "$model_path" | cut -f1)"
        exit 0
    fi

    echo "┌────────────────────────────────────────────────────┐"
    echo "│  Downloading Whisper Model                        │"
    echo "├────────────────────────────────────────────────────┤"
    echo "│  Model: $model_name"
    echo "│  Size:  $model_size"
    echo "│  URL:   $download_url"
    echo "└────────────────────────────────────────────────────┘"
    echo ""

    mkdir -p "$MODELS_DIR"

    # Download with progress bar
    if command -v curl &> /dev/null; then
        echo "[INFO] Downloading with curl..."
        curl -L --progress-bar -o "$model_path" "$download_url"
    elif command -v wget &> /dev/null; then
        echo "[INFO] Downloading with wget..."
        wget --show-progress -O "$model_path" "$download_url"
    else
        echo "ERROR: curl or wget required to download model" >&2
        exit 1
    fi

    echo ""
    echo "[SUCCESS] Model downloaded: $model_path"
    echo "[INFO] Size: $(du -h "$model_path" | cut -f1)"
}

# Main
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_models
    exit 0
fi

if [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
    show_models
    exit 0
fi

download_model "$1"
