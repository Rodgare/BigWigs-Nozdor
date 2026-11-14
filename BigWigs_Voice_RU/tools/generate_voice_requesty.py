#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Batch voice generation through Requesty (OpenAI-compatible TTS endpoint).

Endpoint:
    POST https://router.requesty.ai/v1/audio/speech

Setup:
    set REQUESTY_API_KEY=sk-...
    (PowerShell: $env:REQUESTY_API_KEY = "sk-...")

Usage:
    python generate_voice_requesty.py --limit 5
    python generate_voice_requesty.py --voice alloy --force
    python generate_voice_requesty.py --model openai/gpt-4o-mini-tts --voice nova

Writes Sounds/<key>.mp3. BigWigs_Voice_RU supports .mp3.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

CYRILLIC_RE = re.compile(r"[А-Яа-яЁё]")
AUDIO_EXTS = (".ogg", ".mp3", ".wav")
API_URL = "https://router.requesty.ai/v1/audio/speech"


def load_rows(csv_path: Path):
    with csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        for row in csv.DictReader(handle):
            key = (row.get("key") or "").strip()
            text = (row.get("text") or "").strip()
            if key and text:
                yield key, text


def synthesize(api_key: str, model: str, voice: str, text: str, instructions: str, speed: float, retries: int) -> bytes:
    payload = {
        "model": model,
        "input": text,
        "voice": voice,
        "response_format": "mp3",
        "speed": speed,
    }
    if instructions:
        payload["instructions"] = instructions

    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    last_error: Exception | None = None

    for attempt in range(1, retries + 1):
        request = urllib.request.Request(
            API_URL,
            data=data,
            method="POST",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            last_error = RuntimeError(f"HTTP {exc.code}: {body[:300]}")
            if exc.code in (429, 500, 502, 503, 504) and attempt < retries:
                wait = float(exc.headers.get("Retry-After") or attempt)
                time.sleep(min(wait, 30))
                continue
            break
        except Exception as exc:
            last_error = exc
            if attempt < retries:
                time.sleep(1.5 * attempt)
                continue
            break

    raise last_error or RuntimeError("Requesty TTS failed")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", help="manifest CSV (default: voice_manifest.csv)")
    parser.add_argument("--api-key", default=os.environ.get("REQUESTY_API_KEY", ""))
    parser.add_argument("--model", default="openai/gpt-4o-mini-tts")
    parser.add_argument("--voice", default="alloy")
    parser.add_argument("--instructions", default="Говори по-русски, чётко и энергично, как рейдовое оповещение.")
    parser.add_argument("--speed", type=float, default=1.0)
    parser.add_argument("--include-english", action="store_true")
    parser.add_argument("--english-only", action="store_true")
    parser.add_argument("--force", action="store_true", help="overwrite and remove old formats")
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--retries", type=int, default=3)
    args = parser.parse_args()

    if not args.api_key:
        print("REQUESTY_API_KEY is not set (or pass --api-key).", file=sys.stderr)
        return 1

    here = Path(__file__).resolve().parent
    voice_root = here.parent
    sounds = voice_root / "Sounds"
    csv_path = Path(args.csv).resolve() if args.csv else here / "voice_manifest.csv"

    if not csv_path.is_file():
        print(f"Manifest not found: {csv_path}", file=sys.stderr)
        return 1

    sounds.mkdir(parents=True, exist_ok=True)
    rows = list(load_rows(csv_path))
    if args.limit:
        rows = rows[: args.limit]

    made = skipped = skipped_english = errors = 0
    characters = 0

    for index, (key, text) in enumerate(rows, 1):
        russian = bool(CYRILLIC_RE.search(text))
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
            audio = synthesize(
                args.api_key, args.model, args.voice, text,
                args.instructions, args.speed, args.retries,
            )
            out.write_bytes(audio)
            made += 1
            characters += len(text)
        except Exception as exc:
            errors += 1
            print(f"ERROR {key}: {exc}", file=sys.stderr)
            continue

        if index % 25 == 0:
            print(f"  {index}/{len(rows)}...")

    print(f"Generated: {made}, skipped existing: {skipped}, skipped non-Russian: {skipped_english}, errors: {errors}")
    print(f"Characters billed: {characters}")
    return 0 if errors == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
