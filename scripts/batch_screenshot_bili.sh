#!/usr/bin/env bash
# batch_screenshot_bili.sh
# 批量截图：每个时间戳下载 5s 小切片 + 抽帧，内建 412 重试和请求间隔
#
# 用法:
#   ./batch_screenshot_bili.sh <bilibili_url> <output_dir> <ts1> <ts2> <ts3> ...
#
# 示例:
#   ./batch_screenshot_bili.sh 'https://www.bilibili.com/video/BV1YE411D7nH/?p=12' \
#       ./images/OS-10  0:10 1:30 4:00 7:00 9:00 13:00 17:00 18:30

set -euo pipefail

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
REFERER="https://www.bilibili.com"
MAX_RETRIES=3
SLEEP_BETWEEN=4  # 每张截图之间等待秒数，防 412

URL="${1:?用法: $0 <bilibili_url> <output_dir> <ts1> [ts2] [ts3] ...}"
OUTDIR="${2:?请提供输出目录}"
shift 2
TIMESTAMPS=("$@")

# Cookie 来源：优先用文件，否则用 Chrome 浏览器
COOKIES_FILE="${BILI_COOKIES_FILE:-}"
if [ -n "$COOKIES_FILE" ]; then
    COOKIE_ARGS="--cookies $COOKIES_FILE"
else
    COOKIE_ARGS="--cookies-from-browser chrome"
fi

if [[ ${#TIMESTAMPS[@]} -eq 0 ]]; then
  echo "请至少提供一个时间戳" >&2
  exit 1
fi

mkdir -p "$OUTDIR"

BV=$(echo "$URL" | grep -oE 'BV[a-zA-Z0-9]+')
P_NUM=$(echo "$URL" | grep -oE 'p=[0-9]+' | grep -oE '[0-9]+' || echo "1")

to_seconds() {
  echo "$1" | awk -F: '{
    if (NF==3) print $1*3600+$2*60+$3;
    else if (NF==2) print $1*60+$2;
    else print $1
  }'
}

TOTAL=${#TIMESTAMPS[@]}
SUCCESS=0
FAIL=0
COUNT=0

echo "📸 批量截图: ${TOTAL} 张 | 间隔 ${SLEEP_BETWEEN}s | BV=${BV} p=${P_NUM}"
echo ""

for ts in "${TIMESTAMPS[@]}"; do
  COUNT=$((COUNT + 1))
  sec=$(to_seconds "$ts")
  END_SEC=$((sec + 8))

  TS_SAFE=$(echo "$ts" | tr ':' '_')
  PADDED=$(printf "%02d" "$COUNT")
  OUTFILE="${OUTDIR}/${PADDED}_${TS_SAFE}.png"
  TMP_VIDEO="/tmp/bili_snap_${BV}_p${P_NUM}_${COUNT}.mp4"

  DONE=false
  for attempt in $(seq 1 $MAX_RETRIES); do
    # 下载 5s 小切片
    if yt-dlp \
      $COOKIE_ARGS \
      --user-agent "$UA" \
      --referer "$REFERER" \
      --add-headers "Origin:https://www.bilibili.com" \
      --download-sections "*${sec}-${END_SEC}" \
      --force-overwrites \
      -o "$TMP_VIDEO" \
      "$URL" --quiet 2>/dev/null; then

      # 抽帧
      if ffmpeg -y -ss 00:00:01 -i "$TMP_VIDEO" -vframes 1 -q:v 1 "$OUTFILE" 2>/dev/null; then
        SIZE=$(du -h "$OUTFILE" | cut -f1)
        echo "  [${COUNT}/${TOTAL}] ✅ ${ts} → $(basename "$OUTFILE") (${SIZE})"
        SUCCESS=$((SUCCESS + 1))
        DONE=true
        rm -f "$TMP_VIDEO"
        break
      fi
    fi

    # 重试
    if [[ $attempt -lt $MAX_RETRIES ]]; then
      WAIT=$(( attempt * SLEEP_BETWEEN ))
      echo "  [${COUNT}/${TOTAL}] ⚠️ ${ts} 失败 (${attempt}/${MAX_RETRIES})，等 ${WAIT}s..."
      sleep "$WAIT"
    fi
  done

  if [[ "$DONE" != "true" ]]; then
    echo "  [${COUNT}/${TOTAL}] ❌ ${ts} → 跳过"
    FAIL=$((FAIL + 1))
  fi

  rm -f "$TMP_VIDEO"

  # 请求间隔（最后一张不需要等）
  if [[ $COUNT -lt $TOTAL ]]; then
    sleep "$SLEEP_BETWEEN"
  fi
done

echo ""
echo "🎉 完成！成功 ${SUCCESS}/${TOTAL}，失败 ${FAIL}"
[[ $SUCCESS -gt 0 ]] && ls -lh "$OUTDIR"
