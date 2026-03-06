#!/usr/bin/env bash
# screenshot_bili_frame.sh
# 从 B 站视频中截取指定时间戳的画面（PPT 截图）
#
# 用法:
#   ./screenshot_bili_frame.sh <bilibili_url> <timestamp> <output_dir> [filename]

set -euo pipefail

URL="${1:?用法: $0 <bilibili_url> <timestamp> <output_dir> [filename]}"
TIMESTAMP="${2:?请提供截图时间戳}"
OUTDIR="${3:?请提供输出目录}"
FILENAME="${4:-}"

# 确保输出目录存在
mkdir -p "$OUTDIR"

# 从 URL 中提取 BV 号和分 P
BV=$(echo "$URL" | grep -oE 'BV[a-zA-Z0-9]+')
P_NUM=$(echo "$URL" | grep -oE 'p=[0-9]+' | grep -oE '[0-9]+' || echo "1")

# 自动生成文件名
if [ -z "$FILENAME" ]; then
    TS_SAFE=$(echo "$TIMESTAMP" | tr ':' '_')
    FILENAME="${BV}_p${P_NUM}_${TS_SAFE}.png"
fi

OUTPATH="$OUTDIR/$FILENAME"
TMP_VIDEO="/tmp/bili_snap_${BV}_${P_NUM}.mp4"

echo "[1/2] 下载视频片段 ($TIMESTAMP)..."

# 解析起始时间和结束时间（加 1 秒）
if [[ "$TIMESTAMP" =~ ^[0-9]+$ ]]; then
    # 纯秒数
    END_TIME=$((TIMESTAMP + 1))
    FORMATTED_RANGE="*${TIMESTAMP}-${END_TIME}"
else
    # 类似 05:30 的格式
    FORMATTED_RANGE="*${TIMESTAMP}-inf"
    # 或者用 -t 1 在 ffmpeg 侧截断，不过我们只要第一帧，所以 yt-dlp 多下一两秒也没事
    # yt-dlp 本身 --download-sections 也可以支持 MM:SS-MM:SS
    # 偷懒做法：把这个参数去掉，用 ffmpeg 的 -ss 也是可以的。但为了防盗链，用截取功能
    # 为了避免加减时间，我们直接让它下 05:30 开始的几秒，通过 -f bestvideo 直接获取视频流可能还是报 403。
    # 简单的做法是将 MM:SS 转成秒。为了简单，直接下载从 TIMESTAMP 后的 5 秒保证有关键帧
    SEC=$(echo "$TIMESTAMP" | awk -F: '{ if (NF==3) print $1*3600+$2*60+$3; else if (NF==2) print $1*60+$2; else print $1 }')
    END_TIME=$((SEC + 5))
    FORMATTED_RANGE="*${SEC}-${END_TIME}"
fi

yt-dlp \
    --cookies-from-browser chrome \
    --download-sections "$FORMATTED_RANGE" \
    --force-overwrites \
    -o "$TMP_VIDEO" \
    "$URL" \
    --quiet

echo "[2/2] 提取画面..."

ffmpeg -y \
    -ss 00:00:01 \
    -i "$TMP_VIDEO" \
    -vframes 1 \
    -q:v 1 \
    "$OUTPATH"

rm -f "$TMP_VIDEO"

echo "[3/3] 截图完成: $OUTPATH"
