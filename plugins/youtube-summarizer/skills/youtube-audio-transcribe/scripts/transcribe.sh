#!/bin/bash
# transcribe.sh - Transcribe audio to text using whisper.cpp
#
# Usage:
#   ./scripts/transcribe.sh "<audio_file>" [model] [language]
#
# Parameters:
#   audio_file - Path to audio file (required)
#   model      - Model name: tiny, base, small, medium, large-v3 (default: medium)
#   language   - Language code: en, ja, zh, auto (default: auto)
#
# Output: JSON with transcription result

set -e

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_ensure_ffmpeg.sh"
source "$SCRIPT_DIR/_ensure_whisper.sh"
source "$SCRIPT_DIR/_ensure_jq.sh"

AUDIO_FILE="$1"
MODEL="${2:-medium}"
LANGUAGE="${3:-auto}"

if [ -z "$AUDIO_FILE" ]; then
    "$JQ" -n '{status: "error", message: "Usage: transcribe.sh <audio_file> [model] [language]"}'
    exit 1
fi

if [ ! -f "$AUDIO_FILE" ]; then
    "$JQ" -n --arg file "$AUDIO_FILE" '{status: "error", message: ("File not found: " + $file)}'
    exit 1
fi

# Ensure model is downloaded
source "$SCRIPT_DIR/_ensure_model.sh" "$MODEL"

# Create temp directory for processing
TEMP_DIR="/tmp/whisper-transcribe-$$"
mkdir -p "$TEMP_DIR"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Convert audio to 16kHz mono WAV (required by whisper)
WAV_FILE="$TEMP_DIR/audio.wav"
echo "[INFO] Converting audio to WAV..." >&2
"$FFMPEG" -i "$AUDIO_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$WAV_FILE" -y 2>/dev/null

# Get audio duration
DURATION=$("$FFMPEG" -i "$AUDIO_FILE" 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed 's/,//' | cut -d '.' -f 1)

# Build whisper command
WHISPER_ARGS=("-f" "$WAV_FILE" "-m" "$MODEL_PATH" "-oj")

# Add language option (auto = don't specify, let whisper detect)
if [ "$LANGUAGE" != "auto" ]; then
    WHISPER_ARGS+=("-l" "$LANGUAGE")
fi

# Run whisper
echo "[INFO] Transcribing with model: $MODEL..." >&2
OUTPUT_FILE="$TEMP_DIR/output"
"$WHISPER" "${WHISPER_ARGS[@]}" -of "$OUTPUT_FILE" >/dev/null 2>&1

# Check if output exists
JSON_FILE="$OUTPUT_FILE.json"
if [ ! -f "$JSON_FILE" ]; then
    "$JQ" -n '{status: "error", message: "Transcription failed"}'
    exit 1
fi

# Parse whisper JSON output and format
"$JQ" --arg model "$MODEL" --arg duration "$DURATION" '
{
    status: "success",
    text: .transcription | map(.text) | join(""),
    language: .result.language,
    duration: $duration,
    model: $model,
    segments: [.transcription[] | {
        start: .timestamps.from,
        end: .timestamps.to,
        text: .text
    }]
}
' "$JSON_FILE"
