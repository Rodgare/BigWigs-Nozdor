#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# usage example:
# cd C:\Games\WoWNozdor
# python Interface\AddOns\BigWigs\Tools\bwlog_extract.py WTF\Account\CODA\SavedVariables\Transcriptor.lua extracted_boss_log.txt

r"""
Transcriptor saved variable -> BigWigs entity extractor.

Reads the raw Transcriptor.lua (SavedVariables) dump and prints, grouped:
  A) Bosses detected (INSTANCE_ENCOUNTER_ENGAGE_UNIT)
  B) Every unit (mob/player) with its resolved mob id and total cast count
  C) Per mob: each distinct ability event with count, first/last time and the
     median cast->cast interval, so you can build BigWigs timers.

Mob ids are resolved in this order:
  1. INSTANCE_ENCOUNTER_ENGAGE_UNIT / UNIT_TARGET (authoritative)
  2. decoded straight from the creature GUID bits (guid[3:8] hex = npc id),
     exactly like Transcriptor's MobId(), so every summoned add resolves

Usage:
  python bwlog_extract.py <path\to\Transcriptor.lua> [out.txt]
"""
import re
import sys
import collections
import statistics


HDR = re.compile(r"<(?:([\d.]+) )?(\d\d:\d\d:\d\d)>")
CLEU = re.compile(r"\[CLEU\]\s+([^#]+)#(.*)")
IEU = re.compile(r"boss(\d)#(\d)#(\d)#(\d)#([^#]+)#(\d+)#([0-9a-fA-Fx]+)")
UTAR = re.compile(r"\[UNIT_TARGET\]\s+-[^:]+:([^-]+)-\s*\[.*?ID:(\d+)#GUID:([0-9a-fA-Fx]+)")
USCS = re.compile(r"\[UNIT_SPELLCAST_(?:SUCCEEDED|START|STOP)\]")
# summed periodic damage lines written by Transcriptor, e.g. SPELL_PERIODIC_DAMAGE[CONDENSED]
CONDENSED = re.compile(r"#(\d+) Targets#(\d+)#([^#\"]+)")

# COMBATLOG_OBJECT_TYPE_* live in the low 3 nibbles of the GUID's first byte
TYPE_PLAYER, TYPE_NPC, TYPE_PET, TYPE_GUARDIAN, TYPE_VEHICLE = 0x000, 0x003, 0x004, 0x008, 0x005
INPUT_FLAG = 0xF130  # creature guid prefix, e.g. 0xF13000CF080000BD


def unit_type(guid):
    """Return the COMBATLOG unit type from a GUID string, or None."""
    if not guid or not guid.lower().startswith("0x") or len(guid) < 6:
        return None
    try:
        return int(guid[2:5], 16) & 0x00F
    except ValueError:
        return None


def mob_id_from_guid(guid):
    """Decode the npc id from a creature GUID, mirroring Transcriptor's MobId().

    GUID layout: 0x F130 <npcId:4 bytes> <spawnCounter>
    e.g. 0xF13000CF080000BD -> 0xCF08 = 53000
    """
    if not guid or len(guid) < 13:
        return None
    try:
        npc = int(guid[4:12], 16) & 0xFFFF
    except ValueError:
        return None
    return npc or None


def is_player(guid):
    return unit_type(guid) == TYPE_PLAYER


def is_creature(guid):
    return unit_type(guid) in (TYPE_NPC, TYPE_PET, TYPE_GUARDIAN, TYPE_VEHICLE)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    src = sys.argv[1]
    outpath = sys.argv[2] if len(sys.argv) >= 3 else "bwlog_report.txt"

    explicit = {}   # guid -> npc id learnt from emote/engage/target lines
    bosses = []     # [(name, npc id, guid)]
    names = {}      # guid -> last seen name
    abilities = collections.defaultdict(lambda: collections.defaultdict(list))
    # abilities[key][spellId] = [(time, event, spellName, payload)]

    with open(src, "r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.rstrip("\n")
            m = HDR.search(line)
            if not m:
                continue
            t = float(m.group(1)) if m.group(1) else 0.0

            ie = IEU.search(line)
            if ie:
                name, mid, guid = ie.group(5), int(ie.group(6)), ie.group(7)
                explicit[guid] = mid
                names[guid] = name
                entry = (name, mid, guid)
                if entry not in bosses:
                    bosses.append(entry)
                continue

            um = UTAR.search(line)
            if um:
                name, mid, guid = um.group(1), int(um.group(2)), um.group(3)
                explicit[guid] = mid
                names[guid] = name
                continue

            cm = CLEU.search(line)
            if not cm:
                continue
            event = cm.group(1)
            toks = cm.group(2).split("#")
            if len(toks) < 7:
                continue
            srcGUID, srcName, dstGUID, dstName = toks[0], toks[1], toks[2], toks[3]
            payload = ""
            if "[CONDENSED]" in event:
                cond = CONDENSED.search(cm.group(2))
                sid = int(cond.group(2)) if cond else 0
                spellName = cond.group(3) if cond else ""
                payload = "%s targets" % cond.group(1) if cond else ""
            else:
                try:
                    sid = int(toks[4])
                except (TypeError, ValueError):
                    continue
                spellName = toks[5]
                if event.startswith("SPELL_AURA_"):
                    payload = toks[6] if len(toks) > 6 else ""
                    if len(toks) > 7 and toks[7] not in ("nil", ""):
                        payload += " dose %s" % toks[7]
                elif event == "SPELL_MISSED":
                    payload = toks[6] if len(toks) > 6 else ""

            if not (event.startswith(("SPELL_CAST", "SPELL_SUMMON", "SPELL_EXTRA_ATTACKS",
                                      "SPELL_AURA_APPLIED", "SPELL_AURA_REMOVED",
                                      "SPELL_DAMAGE", "SPELL_PERIODIC_DAMAGE"))):
                continue

            if srcName:
                names.setdefault(srcGUID, srcName)
            if dstName:
                names.setdefault(dstGUID, dstName)

            if is_player(srcGUID):
                key = "P:" + (srcName or srcGUID)
            elif is_creature(srcGUID):
                mid = explicit.get(srcGUID) or mob_id_from_guid(srcGUID)
                key = "M%06d" % mid if mid else "M:UNKNOWN:" + (srcName or srcGUID)
            else:
                continue

            abilities[key][sid].append((t, event, spellName or "?", payload))

    by_id = {}
    for guid, mid in explicit.items():
        n = names.get(guid)
        if n and n != "??":
            by_id.setdefault(mid, n)

    out = open(outpath, "w", encoding="utf-8")

    def p(*a):
        print(*a, file=out)

    p("==== A) BOSSES (INSTANCE_ENCOUNTER_ENGAGE_UNIT) ====")
    for name, mid, guid in bosses:
        p("  mobId=%-6d  name=%-40s guid=%s" % (mid, name, guid))

    def label(key):
        if key.startswith("P:"):
            return key[2:].strip() or "(player)"
        try:
            mid = int(key[1:])
        except ValueError:
            return key[len("M:UNKNOWN:"):]
        return by_id.get(mid) or names.get(key) or "mob %d" % mid

    p("\n==== B) UNITS by cast-count ====")
    rows = []
    for key, ab in abilities.items():
        total = sum(len(v) for v in ab.values())
        rows.append((total, label(key), key))
    rows.sort(key=lambda r: (-r[0], r[1]))

    p("%-8s %-4s %-46s %s" % ("events", "type", "unit", "key"))
    for total, name, key in rows:
        kind = "PLYR" if key.startswith("P:") else "MOB "
        p("%-8d %-4s %-46s %s" % (total, kind, name[:46], key))

    p("\n==== C) ABILITIES per mob (for timers) ====")
    for total, name, key in rows:
        if key.startswith("P:"):
            continue
        p("\n-- %s (%d events) %s" % (name, total, key))
        for sid, evs in sorted(abilities[key].items(), key=lambda kv: -len(kv[1])):
            evs.sort()
            kinds = sorted({e[1] for e in evs})
            name_s = evs[0][2]
            payload = evs[0][3]
            times = [e[0] for e in evs]
            line = "    spellId=%-6d %-34s x%-3d %s" % (
                sid, name_s[:34], len(evs), "/".join(k.replace("SPELL_", "") for k in kinds))
            if payload:
                line += "  [%s]" % payload
            if len(times) >= 3:
                iv = [b - a for a, b in zip(times, times[1:]) if b > a]
                if iv:
                    line += "  ~%.1fs med, min %.1f max %.1f" % (
                        statistics.median(iv), min(iv), max(iv))
            line += "  t=%.1f..%.1f" % (times[0], times[-1])
            p(line)

    out.close()
    print("wrote %s" % outpath)
    return 0


if __name__ == "__main__":
    sys.exit(main())
