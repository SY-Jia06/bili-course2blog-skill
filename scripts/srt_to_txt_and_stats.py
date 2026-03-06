#!/usr/bin/env python3
import argparse
import re
from pathlib import Path

TIME_RE = re.compile(r"^\d{2}:\d{2}:\d{2},\d{3} --> ")

def srt_to_text_lines(content: str):
    lines = []
    for raw in content.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.isdigit():
            continue
        if TIME_RE.match(line):
            continue
        lines.append(line)
    return lines


def parse_last_end_time(content: str):
    last = None
    for raw in content.splitlines():
        if " --> " in raw and TIME_RE.match(raw.strip()):
            last = raw.split(" --> ", 1)[1].strip()
    return last


def to_seconds(ts: str):
    hh, mm, rest = ts.split(":")
    ss, ms = rest.split(",")
    return int(hh) * 3600 + int(mm) * 60 + int(ss) + int(ms) / 1000.0


def main():
    ap = argparse.ArgumentParser(description="Convert SRT to plain text and print stats")
    ap.add_argument("srt_file", help="Input .srt file")
    ap.add_argument("--txt-out", help="Output txt file path (default: <srt>.txt)")
    args = ap.parse_args()

    srt_path = Path(args.srt_file)
    if not srt_path.exists():
        raise SystemExit(f"SRT file not found: {srt_path}")

    content = srt_path.read_text(encoding="utf-8")
    lines = srt_to_text_lines(content)
    text = "\n".join(lines) + ("\n" if lines else "")

    txt_out = Path(args.txt_out) if args.txt_out else srt_path.with_suffix(srt_path.suffix + ".txt")
    txt_out.write_text(text, encoding="utf-8")

    block_count = sum(1 for line in content.splitlines() if line.strip().isdigit())
    char_count = sum(len(x) for x in lines)
    last_end = parse_last_end_time(content)

    print(f"srt_file={srt_path}")
    print(f"txt_file={txt_out}")
    print(f"blocks={block_count}")
    print(f"text_lines={len(lines)}")
    print(f"chars={char_count}")
    if last_end:
        sec = to_seconds(last_end)
        print(f"last_end={last_end}")
        print(f"duration_sec={sec:.3f}")
        print(f"duration_min={sec/60:.2f}")


if __name__ == "__main__":
    main()
