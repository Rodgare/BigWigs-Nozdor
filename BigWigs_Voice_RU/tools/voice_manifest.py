#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build a BigWigs_Voice_RU manifest from BigWigs boss modules.

The voice pack plays Sounds/<option-key>.ogg (or .mp3/.wav) for every
BigWigs_Voice message. Option keys are usually spell IDs, but they can also
be strings like "stages", "wells" or "berserk".

Usage:
    python voice_manifest.py                 # scan, write CSV, print report
    python voice_manifest.py --prune         # dry-run: list unused audio files
    python voice_manifest.py --prune --yes   # delete unused audio files

Generated files (next to this script):
    voice_manifest.csv   key,text,module,source
    voice_missing.txt    keys without any audio file
    voice_unused.txt     audio files that no module uses
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

FLAGS = {
    "BAR", "MESSAGE", "ICON", "PULSE", "SOUND", "SAY", "PROXIMITY",
    "FLASH", "ME_ONLY", "EMPHASIZE", "TANK", "HEALER", "TANK_HEALER",
    "DISPEL", "ALTPOWER", "VOICE", "COUNTDOWN", "INFOBOX", "CASTBAR",
    "SAY_COUNTDOWN", "ME_ONLY_EMPHASIZE", "NAMEPLATEBAR", "OFF",
}

ADDONS = [
    "BigWigs_WrathOfTheLichKing",
    "BigWigs_Azeroth",
    "LittleWigs",
]

AUDIO_EXTS = (".ogg", ".mp3", ".wav")

COMMENT_RE = re.compile(r"--\s*(.+?)\s*$")
CYRILLIC_RE = re.compile(r"[А-Яа-яЁё]")
LOCALE_RE = re.compile(r"\bL\[\s*(-?\d+)\s*\]\s*=\s*\"((?:\\.|[^\"\\])*)\"")
MODULE_RE = re.compile(r"NewBoss\s*\(\s*\"([^\"]+)\"")


def extract_block(text: str, start: int) -> str | None:
    """Return the contents of the first {...} block at/after start."""
    open_idx = text.find("{", start)
    if open_idx < 0:
        return None

    depth = 0
    i = open_idx
    quote = None
    escaped = False
    while i < len(text):
        ch = text[i]
        if quote:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
        elif ch in ("\"", "'"):
            quote = ch
        elif ch == "-" and text.startswith("--", i):
            nl = text.find("\n", i)
            i = len(text) if nl < 0 else nl
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[open_idx + 1:i]
        i += 1
    return None


def option_blocks(text: str):
    """Yield the bodies of mod.toggleOptions / mod:GetOptions / abilities."""
    for anchor in (r"mod\.toggleOptions\s*=\s*", r"function\s+mod:GetOptions\s*\("):
        match = re.search(anchor, text)
        if match:
            block = extract_block(text, match.end())
            if block:
                yield "options", block

    match = re.search(r"local\s+abilities\s*=\s*", text)
    if match:
        block = extract_block(text, match.end())
        if block:
            yield "abilities", block


def strip_comments(block: str) -> str:
    """Remove Lua line comments, keeping strings intact."""
    out: list[str] = []
    quote = None
    escaped = False
    i = 0
    while i < len(block):
        ch = block[i]
        if quote:
            out.append(ch)
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
        elif ch in ("\"", "'"):
            quote = ch
            out.append(ch)
        elif ch == "-" and block.startswith("--", i):
            nl = block.find("\n", i)
            if nl < 0:
                break
            out.append("\n")
            i = nl
        else:
            out.append(ch)
        i += 1
    return "".join(out)


def parse_keys(block: str, kind: str = "options") -> list[str]:
    keys: list[str] = []
    block = strip_comments(block)

    if kind == "abilities":
        for match in re.finditer(r"\bkey\s*=\s*(-?\d{3,})\b", block):
            value = match.group(1)
            if value not in keys:
                keys.append(value)
        for match in re.finditer(r"\bkey\s*=\s*\"([A-Za-z_][\w.-]*)\"", block):
            value = match.group(1)
            if value not in keys:
                keys.append(value)
        return keys

    for match in re.finditer(r"(?<![\w.])(-?\d{3,})(?![\w.])", block):
        value = match.group(1)
        if value not in keys:
            keys.append(value)

    for match in re.finditer(r"\"([A-Za-z_][\w.-]*)\"|'([A-Za-z_][\w.-]*)'", block):
        value = match.group(1) or match.group(2)
        if value and value not in FLAGS and value not in keys:
            keys.append(value)

    return keys


def parse_texts(text: str) -> tuple[dict[str, str], dict[str, str]]:
    """Return locale names and inline comments per numeric key."""
    names: dict[str, str] = {}
    comments: dict[str, str] = {}

    for match in LOCALE_RE.finditer(text):
        key, value = match.group(1), match.group(2)
        value = value.replace("\\\"", "\"").replace("\\\\", "\\")
        if value and key not in names:
            names[key] = value

    for line in text.splitlines():
        if line.lstrip().startswith("--"):
            continue
        match = re.search(r"(?<![\w.])(-?\d{3,})(?![\w.])", line)
        comment_start = line.find("--")
        if not match or comment_start < 0 or comment_start < match.start():
            continue
        key = match.group(1)
        value = line[comment_start + 2:].strip()
        value = re.sub(r"\s*\([^)]*\)\s*$", "", value).strip()
        if value and not value.lower().startswith(("npc id", "id ", "todo")):
            comments.setdefault(key, value)

    return names, comments


def scan(addons_root: Path):
    rows: dict[str, dict[str, str]] = {}
    conflicts: list[tuple[str, str, str]] = []

    for addon in ADDONS:
        addon_dir = addons_root / addon
        if not addon_dir.is_dir():
            continue

        for path in sorted(addon_dir.rglob("*.lua")):
            parts = {part.lower() for part in path.parts}
            if "libs" in parts or "locales" in parts or "options" in parts:
                continue

            try:
                text = path.read_text(encoding="utf-8", errors="replace")
            except OSError as exc:
                print(f"skip {path}: {exc}", file=sys.stderr)
                continue

            keys: list[str] = []
            for kind, block in option_blocks(text):
                keys.extend(parse_keys(block, kind))
            if not keys:
                continue

            module_match = MODULE_RE.search(text)
            module = module_match.group(1) if module_match else path.stem
            names, comments = parse_texts(text)
            source = str(path.relative_to(addons_root))

            for key in keys:
                value = names.get(key) or comments.get(key) or ""
                current = rows.get(key)
                if current is None:
                    rows[key] = {
                        "key": key,
                        "text": value,
                        "module": module,
                        "source": source,
                    }
                elif value:
                    if not current["text"]:
                        current["text"] = value
                        current["module"] = module
                        current["source"] = source
                    elif current["text"] != value:
                        conflicts.append((key, current["text"], value))

    return rows, conflicts


def key_sort(key: str):
    try:
        return (0, int(key), "")
    except ValueError:
        return (1, 0, key)


def audio_stems(sounds: Path) -> dict[str, Path]:
    found: dict[str, Path] = {}
    if not sounds.is_dir():
        return found
    for path in sounds.iterdir():
        if path.is_file() and path.suffix.lower() in AUDIO_EXTS:
            found.setdefault(path.stem, path)
    return found


def find_export(addons_root: Path) -> Path | None:
    wtf = addons_root.parent.parent / "WTF"
    if not wtf.is_dir():
        return None
    candidates = list(wtf.glob("Account/*/SavedVariables/BigWigs_Voice_RU.lua"))
    if not candidates:
        return None
    return max(candidates, key=lambda path: path.stat().st_mtime)


def load_export(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    names: dict[str, str] = {}
    pattern = re.compile(r"\[\s*\"?(-?\d+)\"?\s*\]\s*=\s*\"((?:\\.|[^\"\\])*)\"")
    for match in pattern.finditer(text):
        key = match.group(1)
        value = match.group(2).replace("\\\"", "\"").replace("\\\\", "\\")
        if value:
            names.setdefault(key, value)
    return names


def find_logs(addons_root: Path) -> Path | None:
    root = addons_root / "BigWigs" / "Tools" / "extracted"
    return root if root.is_dir() else None


def load_logs(root: Path) -> dict[str, str]:
    names: dict[str, str] = {}
    pattern = re.compile(r"^(.+?)\s*\((\d{3,})\)$")
    for path in root.rglob("*.log"):
        try:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue
        for line in lines:
            if line.startswith("#"):
                continue
            for part in re.split(r"\s{2,}|\t+", line.strip()):
                match = pattern.match(part)
                if not match:
                    continue
                name, key = match.group(1).strip(), match.group(2)
                if name and key not in names:
                    names[key] = name
    return names



def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prune", action="store_true", help="list/delete unused audio files")
    parser.add_argument("--prune-english", action="store_true", help="list/delete audio for rows without Cyrillic text")
    parser.add_argument("--yes", action="store_true", help="actually delete files with --prune")
    parser.add_argument("--names", type=Path, help="BigWigs_Voice_RU.lua SavedVariables with localized names")
    parser.add_argument("--no-names", action="store_true", help="do not merge localized names")
    parser.add_argument("--logs", type=Path, help="BigWigs/Tools/extracted with combat logs")
    parser.add_argument("--no-logs", action="store_true", help="do not merge names from combat logs")
    args = parser.parse_args()

    here = Path(__file__).resolve().parent
    voice_root = here.parent
    addons_root = voice_root.parent
    sounds = voice_root / "Sounds"

    rows, conflicts = scan(addons_root)
    if not rows:
        print("No option keys found. Check the addons path.", file=sys.stderr)
        return 1

    if not args.no_names:
        names_path = args.names or find_export(addons_root)
        if names_path and names_path.is_file():
            names = load_export(names_path)
            for key, value in names.items():
                if key in rows:
                    rows[key]["text"] = value
                else:
                    rows[key] = {"key": key, "text": value, "module": "", "source": "export"}
            print(f"localized names: {len(names)} from {names_path}")
        else:
            print("localized names: none (run /bwvoice export in game, then /reload)")

    if not args.no_logs:
        logs_path = args.logs or find_logs(addons_root)
        if logs_path and logs_path.is_dir():
            log_names = load_logs(logs_path)
            for key, value in log_names.items():
                if key in rows:
                    rows[key]["text"] = value
            print(f"log names: {len(log_names)} from {logs_path}")
        else:
            print("log names: none (BigWigs/Tools/extracted not found)")

    overrides_path = here / "voice_overrides.csv"
    if not overrides_path.exists():
        with overrides_path.open("w", encoding="utf-8-sig", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=["key", "text", "module", "source"])
            writer.writeheader()
            for key in sorted(rows, key=key_sort):
                row = rows[key]
                if row["text"] and not CYRILLIC_RE.search(row["text"]):
                    writer.writerow(row)
        print(f"overrides: seeded {overrides_path} (edit it, then rerun)")
    else:
        overridden = 0
        with overrides_path.open("r", encoding="utf-8-sig", newline="") as handle:
            for item in csv.DictReader(handle):
                key = (item.get("key") or "").strip()
                value = (item.get("text") or "").strip()
                if key and value and key in rows:
                    rows[key]["text"] = value
                    overridden += 1
        print(f"overrides: {overridden} from {overrides_path}")

    skip_path = here / "voice_skip.txt"
    skipped = set()
    if skip_path.exists():
        for line in skip_path.read_text(encoding="utf-8", errors="replace").splitlines():
            key = line.split("#", 1)[0].strip()
            if key and key in rows:
                skipped.add(key)
    if skipped:
        for key in skipped:
            rows[key]["text"] = ""
        print(f"skipped by voice_skip.txt: {len(skipped)}")

    manifest = here / "voice_manifest.csv"
    with manifest.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["key", "text", "module", "source"])
        writer.writeheader()
        for key in sorted(rows, key=key_sort):
            writer.writerow(rows[key])

    untranslated_path = here / "voice_untranslated.csv"
    untranslated = [
        rows[key]
        for key in sorted(rows, key=key_sort)
        if rows[key]["text"] and not CYRILLIC_RE.search(rows[key]["text"])
    ]
    with untranslated_path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["key", "text", "module", "source"])
        writer.writeheader()
        writer.writerows(untranslated)

    blank_path = here / "voice_blank.csv"
    blank = [rows[key] for key in sorted(rows, key=key_sort) if not rows[key]["text"] and key not in skipped]
    with blank_path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["key", "text", "module", "source"])
        writer.writeheader()
        writer.writerows(blank)

    existing = audio_stems(sounds)
    missing = [key for key in rows if key not in existing]
    unused = [stem for stem in existing if stem not in rows and not (stem.endswith("y") and stem[:-1] in rows)]

    (here / "voice_missing.txt").write_text("\n".join(sorted(missing, key=key_sort)) + "\n", encoding="utf-8")
    (here / "voice_unused.txt").write_text("\n".join(sorted(unused)) + "\n", encoding="utf-8")

    print(f"keys: {len(rows)}")
    print(f"audio files: {len(existing)}")
    print(f"missing audio: {len(missing)} -> {here / 'voice_missing.txt'}")
    print(f"unused audio: {len(unused)} -> {here / 'voice_unused.txt'}")
    print(f"untranslated: {len(untranslated)} -> {untranslated_path}")
    print(f"blank text: {len(blank)} -> {blank_path}")
    print(f"manifest: {manifest}")

    if conflicts:
        print(f"text conflicts: {len(conflicts)} (first kept, check CSV if needed)")
        for key, kept, rejected in conflicts[:10]:
            print(f"  {key}: kept {kept!r}, ignored {rejected!r}")

    if args.prune:
        if not unused:
            print("Nothing to prune.")
        elif not args.yes:
            print("Dry run. Re-run with --prune --yes to delete:")
            for stem in sorted(unused):
                print(f"  {existing[stem]}")
        else:
            for stem in sorted(unused):
                existing[stem].unlink()
            print(f"Deleted {len(unused)} unused audio files.")

    if args.prune_english:
        english_keys = {
            key
            for key, row in rows.items()
            if not row["text"] or not CYRILLIC_RE.search(row["text"])
        }
        english_stems = sorted(
            stem
            for stem in existing
            if stem in english_keys or (stem.endswith("y") and stem[:-1] in english_keys)
        )
        if not english_stems:
            print("No English audio to prune.")
        elif not args.yes:
            print("Dry run. Re-run with --prune-english --yes to delete:")
            for stem in english_stems:
                print(f"  {existing[stem]}")
        else:
            for stem in english_stems:
                existing[stem].unlink()
            print(f"Deleted {len(english_stems)} English/blank audio files.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
