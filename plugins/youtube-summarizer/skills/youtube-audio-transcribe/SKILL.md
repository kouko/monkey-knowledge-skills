---
name: youtube-audio-transcribe
description: Transcribe audio to text using local whisper.cpp. Use when user wants to convert audio/video to text, get transcription, or speech-to-text.
license: MIT
metadata:
  version: 1.0.0
  author: kouko
  tags:
    - youtube
    - audio
    - transcribe
    - whisper
    - speech-to-text
compatibility:
  claude-code: ">=1.0.0"
---

# YouTube Audio Transcribe

Transcribe audio files to text using local whisper.cpp (no cloud API required).

## Quick Start

```
/youtube-audio-transcribe <audio_file> [model] [language]
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| audio_file | Yes | - | Path to audio file |
| model | No | medium | Model: tiny, base, small, medium, large-v3 |
| language | No | auto | Language code: en, ja, zh, auto (auto-detect) |

## Examples

- `/youtube-audio-transcribe /tmp/youtube-audio/video.m4a` - Transcribe with default settings
- `/youtube-audio-transcribe audio.mp3 small en` - Use small model, force English
- `/youtube-audio-transcribe podcast.wav medium ja` - Use medium model, Japanese

## How it Works

1. Execute: `{baseDir}/scripts/transcribe.sh "<audio_file>" "<model>" "<language>"`
2. Convert audio to 16kHz mono WAV using ffmpeg
3. Download model if not present
4. Run whisper-cli for transcription
5. Parse and format JSON output

```
┌─────────────────────────────┐
│      transcribe.sh          │
│  audio_file, [model], [lang]│
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   ffmpeg: convert to WAV    │
│   16kHz, mono, pcm_s16le    │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   whisper-cli: transcribe   │
│   with Metal acceleration   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   JSON output               │
│   {text, segments, ...}     │
└─────────────────────────────┘
```

## Output Format

**Success:**
```json
{
  "status": "success",
  "text": "Full transcription text...",
  "language": "en",
  "duration": "3:32",
  "model": "medium",
  "segments": [
    {
      "start": "00:00:00.000",
      "end": "00:00:05.000",
      "text": "First segment..."
    }
  ]
}
```

**Error:**
```json
{
  "status": "error",
  "message": "Error description"
}
```

## Models

| Model | Size | RAM | Speed | Accuracy |
|-------|------|-----|-------|----------|
| tiny | 75MB | ~273MB | Fastest | Low |
| base | 142MB | ~388MB | Fast | Medium |
| small | 466MB | ~852MB | Moderate | Good |
| medium | 1.5GB | ~2.1GB | Slow | High |
| large-v3 | 2.9GB | ~3.9GB | Slowest | Best |

## Notes

- First run downloads the model (~1.5GB for medium)
- Uses Metal acceleration on macOS for faster processing
- Supports auto language detection
- Audio is converted to 16kHz WAV for optimal results
- Requires ffmpeg and whisper-cli (pre-built in bin/)
