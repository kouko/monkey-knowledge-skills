#!/bin/bash
# _ensure_model.sh - Ensure whisper model is available
#
# Checks if model exists locally. Does NOT auto-download.
# For downloading, use: ./scripts/download-model.sh <model_name>
#
# Usage:
#   source "$(dirname "$0")/_ensure_model.sh" [model_name]
#   echo "Model path: $MODEL_PATH"
#
# Exit codes:
#   0 - Model found (MODEL_PATH is set)
#   1 - Unknown model (MODEL_ERROR_JSON is set)
#   2 - Model not found (MODEL_ERROR_JSON is set)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$SCRIPT_DIR/../models"

# Model name (default: medium)
MODEL_NAME="${1:-medium}"

# Hugging Face base URL
HF_BASE_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

# Get model size in bytes
get_model_size_bytes() {
    local name="$1"
    case "$name" in
        tiny|tiny.en)         echo "77691713" ;;
        base|base.en)         echo "147951465" ;;
        small|small.en)       echo "488210841" ;;
        medium|medium.en)     echo "1572864000" ;;
        large-v1|large-v2|large-v3) echo "3094623232" ;;
        large-v3-turbo)       echo "1620000000" ;;
        belle-zh)             echo "1620000000" ;;
        kotoba-ja)            echo "1620000000" ;;
        kotoba-ja-q5)         echo "600000000" ;;
        *)                    echo "0" ;;
    esac
}

# Get model size human readable
get_model_size_human() {
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

# Map model name to local filename
get_model_filename() {
    local name="$1"
    case "$name" in
        # Standard whisper.cpp models
        tiny|tiny.en)     echo "ggml-${name}.bin" ;;
        base|base.en)     echo "ggml-${name}.bin" ;;
        small|small.en)   echo "ggml-${name}.bin" ;;
        medium|medium.en) echo "ggml-${name}.bin" ;;
        large|large-v1)   echo "ggml-large-v1.bin" ;;
        large-v2)         echo "ggml-large-v2.bin" ;;
        large-v3)         echo "ggml-large-v3.bin" ;;
        large-v3-turbo)   echo "ggml-large-v3-turbo.bin" ;;
        # Language-specialized models
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
        # Chinese-specialized model (BELLE-2)
        belle-zh)
            echo "https://huggingface.co/BELLE-2/Belle-whisper-large-v3-turbo-zh-ggml/resolve/main/ggml-model.bin"
            ;;
        # Japanese-specialized model (kotoba-tech)
        kotoba-ja)
            echo "https://huggingface.co/kotoba-tech/kotoba-whisper-v2.0-ggml/resolve/main/ggml-kotoba-whisper-v2.0.bin"
            ;;
        kotoba-ja-q5)
            echo "https://huggingface.co/kotoba-tech/kotoba-whisper-v2.0-ggml/resolve/main/ggml-kotoba-whisper-v2.0-q5_0.bin"
            ;;
        # Standard whisper.cpp models
        *)
            local filename
            filename=$(get_model_filename "$name")
            echo "$HF_BASE_URL/$filename"
            ;;
    esac
}

# Initialize result variables
MODEL_PATH=""
MODEL_ERROR_JSON=""
_MODEL_EXIT_CODE=0

# Get filename
_MODEL_FILENAME=$(get_model_filename "$MODEL_NAME")

# Check for unknown model
if [ -z "$_MODEL_FILENAME" ]; then
    MODEL_ERROR_JSON=$(cat <<EOF
{
    "error_code": "UNKNOWN_MODEL",
    "message": "Unknown model: $MODEL_NAME",
    "available_models": ["tiny", "base", "small", "medium", "large-v3", "belle-zh", "kotoba-ja", "kotoba-ja-q5"]
}
EOF
)
    _MODEL_EXIT_CODE=1
else
    _MODEL_PATH_CHECK="$MODELS_DIR/$_MODEL_FILENAME"

    # Check if model file exists
    if [ -f "$_MODEL_PATH_CHECK" ]; then
        MODEL_PATH="$_MODEL_PATH_CHECK"
        _MODEL_EXIT_CODE=0
    else
        # Model not found - prepare error info
        _DOWNLOAD_URL=$(get_model_url "$MODEL_NAME")
        _MODEL_SIZE=$(get_model_size_bytes "$MODEL_NAME")
        _MODEL_SIZE_HUMAN=$(get_model_size_human "$MODEL_NAME")

        MODEL_ERROR_JSON=$(cat <<EOF
{
    "error_code": "MODEL_NOT_FOUND",
    "message": "Model '$MODEL_NAME' not found. Please download it first.",
    "model": "$MODEL_NAME",
    "model_size": "$_MODEL_SIZE_HUMAN",
    "model_size_bytes": $_MODEL_SIZE,
    "download_command": "$SCRIPT_DIR/download-model.sh $MODEL_NAME",
    "download_url": "$_DOWNLOAD_URL"
}
EOF
)
        _MODEL_EXIT_CODE=2
    fi
fi

# Export results
export MODEL_PATH
export MODEL_NAME
export MODEL_ERROR_JSON

# Return/exit with appropriate code
if [ $_MODEL_EXIT_CODE -ne 0 ]; then
    return $_MODEL_EXIT_CODE 2>/dev/null || exit $_MODEL_EXIT_CODE
fi
