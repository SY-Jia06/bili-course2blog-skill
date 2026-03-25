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
  echo "Usage: $0 <bilibili_url> [sub_lang] [output_dir] [browser|browser1,browser2,...]" >&2
  echo "Example: $0 'https://www.bilibili.com/video/BV1zV2QBtE39/?p=6' ai-zh /tmp/bili_sub chrome,safari,edge" >&2
  exit 1
fi

URL="$1"
SUB_LANG="${2:-ai-zh}"
OUT_DIR="${3:-/tmp/bili_sub}"
BROWSERS_RAW="${4:-chrome,edge,safari,firefox}"
mkdir -p "$OUT_DIR"

IFS=',' read -r -a BROWSERS <<< "$BROWSERS_RAW"

run_with_browser() {
  local browser="$1"
  shift
  yt-dlp --cookies-from-browser "$browser" --user-agent "$UA" --referer "$REFERER" "$@"
}

LAST_BROWSER=""

echo "[0/3] 挂起等待防封禁..."
sleep $(awk 'BEGIN{srand(); print int(2+rand()*4)}')

echo "[1/3] Listing subtitle tracks via browser cookies..."
for browser in "${BROWSERS[@]}"; do
  browser="${browser// /}"
  [[ -z "$browser" ]] && continue
  echo "  - trying cookies from: $browser"
  if run_with_browser "$browser" --skip-download --list-subs "$URL"; then
    LAST_BROWSER="$browser"
    break
  fi
done

if [[ -z "$LAST_BROWSER" ]]; then
  echo "Failed to list subtitles using browsers: $BROWSERS_RAW" >&2
  exit 1
fi

echo "[2/3] Downloading subtitle: ${SUB_LANG} (browser=$LAST_BROWSER)"
run_with_browser "$LAST_BROWSER" \
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
