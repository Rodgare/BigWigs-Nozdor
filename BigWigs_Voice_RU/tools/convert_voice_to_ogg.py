#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convert generated MP3 voice files to 44.1 kHz mono OGG Vorbis.

WoW 3.3.5 voice packs use OGG and the client plays it reliably; this also
avoids the 24 kHz MP3 output produced by Edge/OpenAI TTS.

Usage:
    python convert_voice_to_ogg.py
    python convert_voice_to_ogg.py --keep-mp3
    python convert_voice_to_ogg.py --file 190206.mp3
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import soundfile as sf


def resample_linear(data: np.ndarray, old_rate: int, new_rate: int) -> np.ndarray:
    if old_rate == new_rate:
        return data
    channels = 1 if data.ndim == 1 else data.shape[1]
    old_len = data.shape[0]
    new_len = int(round(old_len * new_rate / old_rate))
    old_x = np.linspace(0.0, 1.0, old_len, endpoint=False)
    new_x = np.linspace(0.0, 1.0, new_len, endpoint=False)
    if channels == 1:
        return np.interp(new_x, old_x, data).astype(np.float32)
    out = np.empty((new_len, channels), dtype=np.float32)
    for channel in range(channels):
        out[:, channel] = np.interp(new_x, old_x, data[:, channel])
    return out


def convert(src: Path, keep_mp3: bool) -> bool:
    dst = src.with_suffix(".ogg")
    try:
        data, rate = sf.read(str(src), dtype="float32", always_2d=False)
        data = resample_linear(data, rate, 44100)
        sf.write(str(dst), data, 44100, format="OGG", subtype="VORBIS")
    except Exception as exc:
        print(f"ERROR {src.name}: {exc}", file=sys.stderr)
        return False

    if not keep_mp3:
        src.unlink()
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--file", help="convert one file in Sounds/")
    parser.add_argument("--keep-mp3", action="store_true")
    args = parser.parse_args()

    sounds = Path(__file__).resolve().parent.parent / "Sounds"
    if args.file:
        files = [sounds / args.file]
    else:
        files = sorted(sounds.glob("*.mp3"))

    if not files:
        print(f"No MP3 files in {sounds}")
        return 0

    ok = 0
    for index, path in enumerate(files, 1):
        if convert(path, args.keep_mp3):
            ok += 1
        if index % 50 == 0:
            print(f"  {index}/{len(files)}...")

    print(f"Converted: {ok}/{len(files)}")
    return 0 if ok == len(files) else 2


if __name__ == "__main__":
    raise SystemExit(main())
