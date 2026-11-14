#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Batch Russian voice generation with Microsoft Edge TTS (free neural voices).

Install:
    pip install edge-tts

Usage:
    python generate_voice_edge.py --voice ru-RU-SvetlanaNeural --force
    python generate_voice_edge.py --limit 5
    python generate_voice_edge.py --include-english

The script writes Sounds/<key>.mp3 and removes old .ogg/.mp3/.wav files for
the same key when --force is used. BigWigs_Voice_RU already supports .mp3.
"""

from __future__ import annotations

import argparse
import asyncio
import csv
import re
import sys
from pathlib import Path

CYRILLIC_RE = re.compile(r"[А-Яа-яЁё]")
AUDIO_EXTS = (".ogg", ".mp3", ".wav")


def has_cyrillic(text: str) -> bool:
    return bool(CYRILLIC_RE.search(text))


def load_rows(csv_path: Path):
    with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            key = (row.get("key") or "").strip()
            text = (row.get("text") or "").strip()
            if key and text:
                yield key, text


async def synthesize(text: str, voice: str, rate: str, pitch: str, out: Path, retries: int) -> None:
    import edge_tts

    last_error: Exception | None = None
    for attempt in range(1, retries + 1):
        try:
            communicate = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch)
            await communicate.save(str(out))
            return
        except Exception as exc:  # network / throttling
            last_error = exc
            if attempt < retries:
                await asyncio.sleep(1.5 * attempt)
    raise last_error or RuntimeError("edge-tts failed")


async def main_async(args) -> int:
    here = Path(__file__).resolve().parent
    voice_root = here.parent
    sounds = voice_root / "Sounds"
    csv_path = Path(args.csv).resolve() if args.csv else here / "voice_manifest.csv"

    if not csv_path.is_file():
        print(f"Manifest not found: {csv_path}", file=sys.stderr)
        return 1

    try:
        import edge_tts  # noqa: F401
    except ImportError:
        print("edge-tts is not installed. Run: pip install edge-tts", file=sys.stderr)
        return 1

    sounds.mkdir(parents=True, exist_ok=True)

    made = skipped = skipped_english = errors = 0
    rows = list(load_rows(csv_path))
    if args.limit:
        rows = rows[: args.limit]

    for index, (key, text) in enumerate(rows, 1):
        russian = has_cyrillic(text)
        if args.english_only and russian:
            continue
        if not args.english_only and not args.include_english and not russian:
            skipped_english += 1
            continue

        out = sounds / f"{key}.mp3"
        old = [sounds / f"{key}{ext}" for ext in AUDIO_EXTS]
        old = [path for path in old if path.exists()]

        if old and not args.force:
            skipped += 1
            continue
        for path in old:
            path.unlink()

        try:
            await synthesize(text, args.voice, args.rate, args.pitch, out, args.retries)
            from voice_audio import convert_to_ogg
            convert_to_ogg(out)
            made += 1
        except Exception as exc:
            errors += 1
            print(f"ERROR {key}: {exc}", file=sys.stderr)
            continue

        if args.delay:
            await asyncio.sleep(args.delay)
        if index % 25 == 0:
            print(f"  {index}/{len(rows)}...")

    print(f"Generated: {made}, skipped existing: {skipped}, skipped non-Russian: {skipped_english}, errors: {errors}")
    return 0 if errors == 0 else 2


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", help="manifest CSV (default: voice_manifest.csv)")
    parser.add_argument("--voice", default="ru-RU-SvetlanaNeural", help="Edge TTS voice")
    parser.add_argument("--rate", default="+10%", help="speech rate, e.g. +10%%")
    parser.add_argument("--pitch", default="+0Hz", help="speech pitch, e.g. +0Hz")
    parser.add_argument("--include-english", action="store_true")
    parser.add_argument("--english-only", action="store_true")
    parser.add_argument("--force", action="store_true", help="overwrite and remove old formats")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--delay", type=float, default=0.15, help="pause between requests")
    parser.add_argument("--retries", type=int, default=3)
    args = parser.parse_args()
    return asyncio.run(main_async(args))


if __name__ == "__main__":
    raise SystemExit(main())
