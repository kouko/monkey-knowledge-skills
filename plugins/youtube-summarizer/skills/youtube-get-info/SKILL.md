---
name: youtube-get-info
description: Get YouTube video info and summarize content. Use when user provides a YouTube URL and wants video details or summary.
license: MIT
metadata:
  version: 1.0.0
  author: kouko
  tags:
    - youtube
    - info
    - summary
compatibility:
  claude-code: ">=1.0.0"
---

# YouTube Video Info

Get video details and generate content summary.

## Quick Start

```
/youtube-get-info <URL>
```

## Examples

```
/youtube-get-info https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

## How it Works

1. Execute: `{baseDir}/scripts/info.sh "<URL>"`
2. Parse JSON to get video metadata
3. Try to get subtitles for summarization
4. Generate summary based on subtitle content
5. If no subtitles, display video info only

## Output Format

```json
{
  "title": "Video Title",
  "channel": "Channel Name",
  "duration_string": "10:30",
  "view_count": 1234567,
  "upload_date": "20240101",
  "language": "en",
  "description": "Video description (first 1000 chars)",
  "has_subtitles": true,
  "subtitle_languages": ["en", "ja", "zh-Hant"],
  "has_auto_captions": true,
  "auto_caption_count": 157
}
```

### Fields

| Field | Description |
|-------|-------------|
| `title` | Video title |
| `channel` | Channel name |
| `duration_string` | Duration (e.g., "10:30") |
| `view_count` | Number of views |
| `upload_date` | Upload date (YYYYMMDD) |
| `language` | Primary language (ISO 639-1 code) |
| `description` | Video description (truncated to 1000 chars) |
| `has_subtitles` | Whether manual subtitles exist |
| `subtitle_languages` | Array of available subtitle language codes |
| `has_auto_captions` | Whether auto-generated captions exist |
| `auto_caption_count` | Number of auto-generated caption languages |

### Content Summary
(Generated from subtitle analysis)
- Key point 1
- Key point 2
- ...

## Notes

- On first run, if yt-dlp or jq is not installed, it will be auto-downloaded
