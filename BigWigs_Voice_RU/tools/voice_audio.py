#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Shared audio helper: convert generated MP3/WAV to 44.1 kHz mono OGG Vorbis."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import soundfile as sf


def _resample_linear(data: np.ndarray, old_rate: int, new_rate: int) -> np.ndarray:
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


def convert_to_ogg(src: Path, keep_source: bool = False) -> Path:
    src = Path(src)
    dst = src.with_suffix(".ogg")
    data, rate = sf.read(str(src), dtype="float32", always_2d=False)
    data = _resample_linear(data, rate, 44100)
    sf.write(str(dst), data, 44100, format="OGG", subtype="VORBIS")
    if not keep_source:
        src.unlink()
    return dst
