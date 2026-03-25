# Bilibili AI Blog Toolkit

> Turn a Bilibili tutorial or course video into clean subtitles, precise screenshots, and an AI-ready Markdown blog workflow.
>
> 中文简介：这是一个给 AI Agent 用的 B 站课程转博客工具链。它负责抽字幕、抓关键帧、产出干净文本，再交给大模型生成结构化笔记或博客。

## Disclaimer

This project is for personal learning, note-taking, and local workflow automation research only.
Please respect copyright, platform terms, and the original creator's work. Do not use extracted subtitles, screenshots, or generated outputs for unauthorized redistribution or commercial use.

## What It Does

This repository is designed as skill infrastructure for AI agents such as Codex, Claude Code, Cursor, or Aider.

Instead of using a heavy browser automation stack, it uses:

- `yt-dlp` for authenticated subtitle/audio/video extraction
- `ffmpeg` for precise frame capture
- lightweight cleanup scripts for subtitle-to-text conversion

The result is a fast pipeline for:

- extracting subtitles from Bilibili videos
- converting subtitles into clean text
- capturing key frames without player UI
- feeding the result into an LLM to generate notes or blog posts

## Why Not Browser Automation?

Typical browser automation approaches rely on Selenium or Playwright, which are often slow and fragile for this task.

This toolkit avoids that by:

- reading cookies from your local browser profile
- downloading raw subtitle/audio/video streams directly
- extracting frames from the underlying media rather than from page screenshots

That means cleaner captures, less UI noise, and much less operational overhead.

## Agent Workflow

### Phase 1: Subtitle Extraction

Fetch subtitles with browser-cookie fallback:

```bash
./scripts/fetch_bili_subtitle.sh '<bilibili_url>' ai-zh /tmp/bili_sub chrome,safari,edge
```

Convert the downloaded `.srt` file into plain text:

```bash
python3 ./scripts/srt_to_txt_and_stats.py /tmp/bili_sub/<filename>.srt
```

By default, the script writes:

- `<filename>.txt`
- and a backward-compatible alias `<filename>.srt.txt`

### Phase 2: Screenshot Extraction

Capture key frames at important timestamps:

```bash
./scripts/screenshot_bili_frame.sh '<bilibili_url>' '04:30' '<output_dir>' 'slide_01.png' chrome,safari,edge
```

Use this for diagrams, summary slides, tables, or code screenshots that are important for the final blog.

### Phase 3: Blog Generation

Once subtitles and screenshots are ready, let the LLM produce the final Markdown article:

- remove filler speech
- keep the core concepts and teaching logic
- preserve important examples and metaphors
- insert screenshots into the correct sections
- explain each image in plain language

## Included Scripts

- `scripts/fetch_bili_subtitle.sh`
  Download Bilibili subtitles with browser-cookie fallback.
- `scripts/srt_to_txt_and_stats.py`
  Convert `.srt` into plain text and print basic stats.
- `scripts/screenshot_bili_frame.sh`
  Download a short media segment and extract a clean frame.
- `scripts/asr_bili_audio_fallback.sh`
  Fallback ASR pipeline when subtitle tracks are unavailable.

## Browser Cookie Strategy

The extraction scripts support an optional final argument for browser cookies, for example:

```bash
chrome
chrome,safari,edge
```

If omitted, the scripts try this fallback order by default:

```text
chrome,edge,safari,firefox
```

## Requirements

- `yt-dlp`
- `ffmpeg`
- Python 3

Optional:

- `mlx_whisper`
- `faster-whisper`

## Output Characteristics

This toolkit is optimized for:

- clean subtitle extraction
- agent-friendly plain text
- high-quality frame capture
- reproducible local workflows

It is not intended to be a polished end-user GUI product.

## Examples

See the `examples/` directory for generated article samples:

- [OS-10.md](examples/OS-10.md)
- [OS-16.md](examples/OS-16.md)
- [OS-17.md](examples/OS-17.md)
- [OS-18.md](examples/OS-18.md)
- [OS-19.md](examples/OS-19.md)
- [OS-20.md](examples/OS-20.md)

## Scope

Although this repository is Bilibili-focused, the underlying approach is general.
Because it relies on `yt-dlp`, the same architecture can often be adapted to other platforms with minimal changes:

- subtitle language selection
- subtitle format compatibility
- platform-specific URL parsing

In other words, this can serve as the foundation for a more general `VideoCourse2Blog` skill.
