#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <bilibili_url> [output_dir] [mlx_model_repo] [fw_model]" >&2
  echo "Example: $0 'https://www.bilibili.com/video/BV1zV2QBtE39/?p=7' /tmp/bili_asr_p7 mlx-community/whisper-large-v3-mlx small" >&2
  exit 1
fi

URL="$1"
OUT_DIR="${2:-/tmp/bili_asr}"
MLX_MODEL="${3:-mlx-community/whisper-large-v3-mlx}"
FW_MODEL="${4:-small}"
mkdir -p "$OUT_DIR"

if ! command -v yt-dlp >/dev/null 2>&1; then
  echo "yt-dlp not found. Install: brew install yt-dlp" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found. Install: brew install ffmpeg" >&2
  exit 1
fi

echo "[1/3] Downloading audio via Chrome cookies..."
yt-dlp \
  --cookies-from-browser chrome \
  -f ba \
  --extract-audio \
  --audio-format mp3 \
  -o "$OUT_DIR/audio.%(ext)s" \
  "$URL"

AUDIO_FILE="$OUT_DIR/audio.mp3"
if [[ ! -f "$AUDIO_FILE" ]]; then
  echo "Audio file not found: $AUDIO_FILE" >&2
  exit 1
fi

if command -v mlx_whisper >/dev/null 2>&1; then
  echo "[2/3] ASR with mlx_whisper (${MLX_MODEL})..."
  mlx_whisper \
    --model "$MLX_MODEL" \
    --language zh \
    --task transcribe \
    --output-format all \
    --output-name asr \
    --output-dir "$OUT_DIR" \
    "$AUDIO_FILE"
else
  echo "[2/3] mlx_whisper not found, fallback to faster-whisper (${FW_MODEL})..."
  python3 - <<PY
from pathlib import Path
import importlib.util

if importlib.util.find_spec("faster_whisper") is None:
    raise SystemExit("faster-whisper not installed. Install: python3 -m pip install -U faster-whisper")

from faster_whisper import WhisperModel

audio = Path("$AUDIO_FILE")
out_dir = Path("$OUT_DIR")
srt_path = out_dir / "asr.srt"
txt_path = out_dir / "asr.txt"
json_path = out_dir / "asr.json"

model = WhisperModel("$FW_MODEL", device="cpu", compute_type="int8")
segments, info = model.transcribe(str(audio), language="zh", vad_filter=True)
segments = list(segments)

def fmt(t):
    h = int(t // 3600)
    m = int((t % 3600) // 60)
    s = int(t % 60)
    ms = int(round((t - int(t)) * 1000))
    if ms == 1000:
        s += 1
        ms = 0
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"

with srt_path.open("w", encoding="utf-8") as fs, txt_path.open("w", encoding="utf-8") as ft:
    for i, seg in enumerate(segments, 1):
        text = seg.text.strip()
        fs.write(f"{i}\\n{fmt(seg.start)} --> {fmt(seg.end)}\\n{text}\\n\\n")
        ft.write(text + "\\n")

import json
stats = {
    "segment_count": len(segments),
    "char_count": sum(len(seg.text.strip()) for seg in segments),
    "audio_duration_sec": float(info.duration),
    "covered_duration_sec": float((segments[-1].end - segments[0].start) if segments else 0),
    "first_ts_sec": float(segments[0].start) if segments else None,
    "last_ts_sec": float(segments[-1].end) if segments else None,
    "language": info.language,
    "language_probability": float(info.language_probability),
}
json_path.write_text(json.dumps(stats, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"Wrote: {srt_path}")
print(f"Wrote: {txt_path}")
print(f"Wrote: {json_path}")
PY
fi

echo "[3/3] Done. Files in: $OUT_DIR"
ls -lh "$OUT_DIR" | sed -n '1,120p'
