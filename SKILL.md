---
name: bilibili-ai-blog-toolkit
description: "This skill should be used when the user asks to summarize a Bilibili video, create a blog post from a Bilibili tutorial, extract subtitles, or capture precise screenshots from Bilibili videos. It automates the extraction of pure subtitles and video frames using yt-dlp and ffmpeg, and structures them into a high-quality Markdown blog."
category: content-creation
risk: safe
source: user
tags: "[automation, bilibili, blog-generator, video-scraping]"
date_added: "2026-03-06"
---

# Bilibili AI Blog Toolkit

Use this skill when the user wants to convert a Bilibili video (like a tutorial, course, or lecture) into a structured Markdown blog post with screenshots, or simply needs to extract subtitles/screenshots from a Bilibili video without opening a heavy browser.

## Workflow

When triggered to generate a blog from a Bilibili video URL, you must orchestrate the following automated workflow:

### Phase 1: Subtitle Extraction
Execute the subtitle fetching script. By default, this uses the local Chrome browser's cookies to authenticate.

```bash
# Example: Fetching subtitles for a specific P(part) of a video
./scripts/fetch_bili_subtitle.sh '<bilibili_url>' ai-zh /tmp/bili_sub
```

Once the `.srt` file is downloaded, clean it up to pure text using the Python script so you can read it easily without timestamps distracting you:
```bash
python3 ./scripts/srt_to_txt_and_stats.py /tmp/bili_sub/<filename>.srt
```
*Read the resulting `.txt` file using the `view_file` tool to understand the content of the video.*

### Phase 2: Frame Extraction (Screenshots)
Based on your reading of the video transcript, identify key moments (timestamps) where important visual information is conceptually introduced (e.g., diagrams, architecture layouts, summary tables). 
For each key moment, extract a screenshot using the specialized screenshot script:

```bash
# Example: Extracting a frame at 04:30
./scripts/screenshot_bili_frame.sh '<bilibili_url>' '04:30' '<blog_output_directory>' 'custom_name.png'
```
*Note: Do not string multiple screenshot commands together with `&&` if they are prone to timeout. Call them individually or in small batches.*

### Phase 3: Blog Generation
Generate the final Markdown file in the user's requested directory. Follow these strict formatting rules:

1. **Header**: Start with a source attribution block.
   `> 📖 笔记整理自：【视频标题】PXX`
   `> 🟡 **重要度：必考 / 核心 / 快速了解**`
2. **Body Structure**: Filter out informal filler words. Extract core concepts, step-by-step logic, and note any common pitfalls (using ⭐). 
3. **Crucial Examples (HARD RULE)**: Teachers often use metaphors, real-life examples, or specific value traces to explain complex concepts. **NEVER OMIT THESE EXAMPLES.** You must extract them and highlight them using blocks like `> 💡 关键例子：` or `> 🌰 生动比喻：`.
4. **Diagram Explanations**: Embed the screenshots you extracted using Markdown syntax (e.g., `![Alt text](custom_name.png)`). Below **each** image, add a `> 🖼️ **图解说明**：` block where you verbally explain what the image shows, breaking down its visual elements into layman's terms.
4. **Summary**: Conclude the blog post with a one-sentence "golden" summary.

## Tool Requirements
To execute this skill, the host machine must have `yt-dlp` and `ffmpeg` installed. The scripts are located in the `scripts/` directory relative to this `SKILL.md` file.

- **`scripts/fetch_bili_subtitle.sh`**: Fetches CC subtitles.
- **`scripts/srt_to_txt_and_stats.py`**: Cleans SRT to TXT.
- **`scripts/screenshot_bili_frame.sh`**: Captures a single lossless frame from the raw video stream to avoid UI elements.
