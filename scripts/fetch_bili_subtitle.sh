#!/usr/bin/env bash
set -euo pipefail

# ── Anti-412: B站会拦截不带浏览器 UA / Referer 的请求 ──
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
REFERER="https://www.bilibili.com"

if ! command -v yt-dlp >/dev/null 2>&1; then
  echo "yt-dlp not found. Install: brew install yt-dlp" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <bilibili_url> [sub_lang] [output_dir]" >&2
  echo "Example: $0 'https://www.bilibili.com/video/BV1zV2QBtE39/?p=6' ai-zh /tmp/bili_sub" >&2
  exit 1
fi

URL="$1"
SUB_LANG="${2:-ai-zh}"
OUT_DIR="${3:-/tmp/bili_sub}"
mkdir -p "$OUT_DIR"

echo "[0/3] 挂起等待防封禁..."
sleep $(awk 'BEGIN{srand(); print int(2+rand()*4)}')

echo "[1/3] Listing subtitle tracks via Chrome cookies..."
yt-dlp --cookies-from-browser chrome --user-agent "$UA" --referer "$REFERER" \
  --skip-download --list-subs "$URL"

echo "[2/3] Downloading subtitle: ${SUB_LANG}"
yt-dlp \
  --cookies-from-browser chrome \
  --user-agent "$UA" \
  --referer "$REFERER" \
  --skip-download \
  --write-subs \
  --sub-langs "$SUB_LANG" \
  --sub-format srt \
  -o "$OUT_DIR/%(id)s.%(ext)s" \
  "$URL"

SUB_COUNT="$(find "$OUT_DIR" -maxdepth 1 -type f -name '*.srt' | wc -l | tr -d ' ')"
if [[ "${SUB_COUNT}" == "0" ]]; then
  echo "[3/3] No subtitle file downloaded for language=${SUB_LANG}. Try fallback ASR script." >&2
  exit 2
fi

echo "[3/3] Done. Files in: $OUT_DIR"
ls -lh "$OUT_DIR" | sed -n '1,80p'
