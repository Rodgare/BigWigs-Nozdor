#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# usage:
#   cd C:\Games\WoWNozdor
#   python Interface\AddOns\BigWigs\Tools\bwlog_extract.py WTF\Account\CODA\SavedVariables\Transcriptor.lua
#
# useful switches:
#   --list                 show the encounter index only, write nothing
#   --out DIR              output folder (default: Tools\extracted)
#   --zone TEXT            only zones whose name contains TEXT
#   --since YYYY-MM-DD     ignore older archives
#   --until YYYY-MM-DD     ignore newer archives
#   --min-pull SEC         drop combat segments shorter than SEC (default 10)
#   --keep-trash           keep non-boss pulls too (off by default)
#   --all                  also keep PvP arenas/battlegrounds (off by default)
#   --split-timeline SEC   split .log timelines into SEC-wide blocks (default 300)
#   --no-bigwigs-index     do not read installed BigWigs modules for boss mob ids

r"""
Transcriptor.lua -> BigWigs filling material.

The SavedVariables dump is streamed line by line, one pass, constant memory:
no part of it is ever loaded whole, even at 150k+ lines. Only the parsed,
already-reduced events of the current archive are buffered, then grouped into
pulls and written out archive by archive.

What an archive actually contains (this is why a naive COMBAT-only parser fails):
  ["COMBAT"]  - engage / regen / unit-target bookkeeping lines only
  ["total"]   - the full event log (CLEU, casts, yells, ...), order not fixed
Both are merged, markers by timestamp, before encounters are built.

Only instance content is kept: raid/dungeon archives are parsed, PvP archives
(arena / battleground zone ids and Type:pvp/arena) are skipped.

Boss detection order for a pull: INSTANCE_ENCOUNTER_ENGAGE_UNIT, then the npc
ids of installed BigWigs modules (BigWigs_WrathOfTheLichKing & co), then npcs
that yell/emote, then a conservative heuristic. Each pull is tagged in the
output as source = engage / bigwigs / yell / guess, so guessed trash pulls can
be deleted safely.

Output (Tools\extracted):

  index.md
  _sessions/<date>_<hhmm>_<Zone>_timers.txt   Transcriptor TIMERS (yells/emotes/casts)
  <zone-id>_<Zone>/
    <Boss>_<mobId>/
      summary.txt                    everything needed to write a boss module
      <date>_<hhmmss>.log            one file per pull, readable timeline

summary.txt contains, per boss:
  * PULLS        - date, wall clock, duration, units (mob ids, boss flags)
  * ABILITIES    - per unit and spell: count, first cast offset, cast interval
                   median/min/max -> directly usable for CDBar timers
  * SUGGESTED    - ready self:CDBar(spellId, interval) lines
  * TALK         - yells/emotes/whispers with their pull-relative times
  * UNITS        - every mob seen in the fight with its resolved npc id
  * module       - matching BigWigs module name / encounterId when installed

Timeline times are seconds from pull, so a line can be copied into:
  self:CDBar(spellId, interval)
  self:Message(spellId, "red", L["..."])
"""

import argparse
import bisect
import collections
import datetime
import os
import re
import statistics
import sys

# --- zones we never want (arena / battleground) ------------------------------
PVP_ZONE_IDS = {
    30, 31, 32, 33, 34,          # Alterac Valley, Warsong, Arathi ...
    489, 529, 566, 607, 628,     # WSG, AB, EotS, SotA, IoC
    559, 562, 572, 617, 618,     # arenas
    4197, 726,                   # Wintergrasp / Tol Barad
}
PVP_TYPES = {"pvp", "arena", "battleground"}
PVP_ZONE_NAMES = (
    "арена", "arena", "ущелье песни войны", "warsong", "низина арати", "arathi",
    "альтерак", "alterac", "око бури", "eye of the storm", "берег древних",
    "strand of the ancients", "осада крепости древних", "isle of conquest",
)

CS_RE = re.compile(r"\|c[0-9a-fA-F]{8}|\|r|\|H[^|]*\|h|\|h")
ARCHIVE_RE = re.compile(r'^\t\["(?P<hdr>.*)"\] = \{$')
SECTION_RE = re.compile(r'^\t\t\["(?P<name>[A-Za-z_0-9]+)"\] = \{$')
HDR_RE = re.compile(r"^<(?P<t>[\d.]+) (?P<clock>\d\d:\d\d:\d\d)>")
ENGAGE_RE = re.compile(
    r"#(boss[1-4])#(?:nil|\d+)#(?:nil|\d+)#(?:nil|\d+)#([^#]*)#(\d+)#(0x[0-9A-Fa-f]+|nil)#")
TARGET_RE = re.compile(r"-target:(?P<name>.*?)- \[(?P<rest>[^\]]*)\]")
UNITCAST_RE = re.compile(
    r"^(?P<name>[^(]+)\([^)]*\)\{Target:(?P<target>[^}]*)\} -(?P<spell>.*?)-(?: (?P<dur>[\d.]+)s)? "
    r"\[\[(?P<mode>[^:\]]*):")

BAD_NAMES = {"?", "??", "nil", "", "Неизвестно", "Unknown"}
# Fallback instance ids for archives whose header zone is unknown ("?").
# Keyed by the zone name reported by ZONE_CHANGED* inside the archive.
ZONE_NAME_IDS = {
    "нексус": 576, "the nexus": 576,
    "азжол-неруб": 601, "azjol-nerub": 601,
    "ан'кахет: старое королевство": 619, "ahn'kahet: the old kingdom": 619,
    "зал высшего прародителя": 599, "halls of stone": 599,
    "крепость драк'тарон": 600, "drak'tharon keep": 600,
    "гундрак": 604, "gundrak": 604,
    "чертоги отражений": 668, "halls of reflection": 668,
    "кузня душ": 632, "the forge of souls": 632,
    "яма сарона": 658, "pit of saron": 658,
    "осада даларана": 961,
}
BOSS_CLASSES = {"elite", "worldboss", "rareelite", "rare", "boss"}

KIND_MAP = {
    "SPELL_CAST_START": "CAST_START",
    "SPELL_CAST_SUCCESS": "CAST_OK",
    "SPELL_AURA_APPLIED": "AURA+",
    "SPELL_AURA_APPLIED_DOSE": "AURA+DOSE",
    "SPELL_AURA_REFRESH": "AURA~",
    "SPELL_AURA_REMOVED": "AURA-",
    "SPELL_SUMMON": "SUMMON",
    "SPELL_INTERRUPT": "INTERRUPT",
    "SPELL_DISPEL": "DISPEL",
    "SPELL_MISSED": "MISS",
}
TALK_MAP = {
    "CHAT_MSG_MONSTER_YELL": "YELL",
    "CHAT_MSG_MONSTER_SAY": "SAY",
    "CHAT_MSG_MONSTER_EMOTE": "EMOTE",
    "CHAT_MSG_MONSTER_WHISPER": "WHISPER",
    "CHAT_MSG_RAID_BOSS_EMOTE": "BOSS_EMOTE",
    "CHAT_MSG_RAID_BOSS_WHISPER": "BOSS_WHISPER",
}

# only real casts give meaningful repeat intervals; aura re-applies are per target
IV_KINDS = {"CAST_START", "CAST_OK", "SUMMON", "U_START", "U_SUCCEEDED"}


# --------------------------------------------------------------------------- helpers
def clean(text):
    return CS_RE.sub("", text).replace("\\n", " ").strip()


def creature_id(guid):
    """0xF130006D3900001A -> 27961 (same rule as Transcriptor's MobId())."""
    if not guid or len(guid) < 12 or guid[:5].lower() not in ("0xf13", "0xf14", "0xf15"):
        return 0
    try:
        return (int(guid[4:12], 16) & 0xFFFF) or 0
    except ValueError:
        return 0


def guid_is_pet(guid):
    return bool(guid) and guid[:5].lower() == "0xf14"


def load_bigwigs_index(addons_root):
    """mob id -> {module, name, zoneId, encounterId, file} from installed BigWigs."""
    idx = {}
    for addon in ("BigWigs_WrathOfTheLichKing", "BigWigs_Azeroth", "LittleWigs"):
        root = os.path.join(addons_root, addon)
        if not os.path.isdir(root):
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if d != "Locales" and not d.startswith("!")]
            for fn in filenames:
                if not fn.endswith(".lua") or fn.startswith("!"):
                    continue
                path = os.path.join(dirpath, fn)
                try:
                    with open(path, "r", encoding="utf-8", errors="replace") as f:
                        text = f.read()
                except OSError:
                    continue
                m = re.search(r'BigWigs:NewBoss\(\s*"([^"]+)"\s*,\s*(\d+)\s*,\s*(\d+)', text)
                if not m:
                    continue
                rec = {"module": m.group(1), "zoneId": int(m.group(2)),
                       "encounterId": int(m.group(3)), "file": fn}
                for mm in re.finditer(r"RegisterEnableMob\(([^)]*)\)", text):
                    for num in re.findall(r"\d+", mm.group(1)):
                        idx[int(num)] = rec
    return idx


def safe_name(text, limit=64):
    t = re.sub(r'[<>:"/\\|?*\x00-\x1f]', " ", text or "")
    t = re.sub(r"\s+", "_", t).strip(" ._-")
    return t[:limit] or "unknown"


def parse_header(hdr):
    info = {"raw": hdr, "date": "0000-00-00", "time": "00:00:00",
            "zoneId": 0, "zone": "?", "subzone": "", "difficulty": 0,
            "difficultyText": "?", "type": "?", "player": "?", "display": "?"}
    m = re.match(r"\[(\d{4}-\d\d-\d\d)\]@\[(\d\d:\d\d:\d\d)\]", hdr)
    if m:
        info["date"], info["time"] = m.group(1), m.group(2)
    m = re.search(r"Zone:(\d+) = ([^,]+), Difficulty:(\d+) \(([^)]*)\), Type:([^,]+),", hdr)
    if m:
        info["zoneId"] = int(m.group(1))
        info["zone"] = m.group(2).strip()
        info["difficulty"] = int(m.group(3))
        info["difficultyText"] = m.group(4)
        info["type"] = m.group(5).strip()
    if "/" in info["zone"]:
        info["zoneName"], info["subzone"] = [x.strip() for x in info["zone"].split("/", 1)]
    else:
        info["zoneName"], info["subzone"] = info["zone"], ""
    display = info["zoneName"]
    if display in BAD_NAMES and info["subzone"]:
        display = info["subzone"]
    info["display"] = display or "Zone_%d" % info["zoneId"]
    m = re.search(r"Player: ([^ ]+)", hdr)
    if m:
        info["player"] = m.group(1)
    return info


def iter_transcriptor(path):
    """Yield archive/section/line events for one pass over the file.

    Only one raw line is held at a time, whatever the file size.
    """
    archive = None
    section = None
    with open(path, "r", encoding="utf-8-sig", errors="replace", buffering=1 << 20) as f:
        for raw in f:
            line = raw.rstrip("\r\n")
            stripped = line.strip()
            indent = len(line) - len(line.lstrip("\t"))
            if archive is None:
                m = ARCHIVE_RE.match(line)
                if m and "Zone:" in m.group("hdr") and "Difficulty:" in m.group("hdr"):
                    archive = parse_header(m.group("hdr").replace('\\"', '"'))
                    section = None
                    yield ("archive", archive)
                continue
            if section is None:
                if stripped in ("},", "}"):
                    if indent <= 1:
                        yield ("archive_end", archive)
                        archive = None
                    continue
                if indent == 2:
                    m = SECTION_RE.match(line)
                    if m:
                        section = m.group("name")
                        yield ("section", archive, section)
                continue
            if stripped in ("},", "}"):
                if indent >= 3:
                    continue
                yield ("section_end", archive, section)
                section = None
                continue
            yield ("line", archive, section, line)
    if archive is not None:
        if section is not None:
            yield ("section_end", archive, section)
        yield ("archive_end", archive)


def unwrap(line):
    """`\\t\\t\\t"<1.56 01:19:12> [CLEU] ...", -- [12]` -> `<1.56 01:19:12> [CLEU] ...`"""
    s = line.strip()
    if s.startswith('"'):
        s = s[1:]
    idx = s.rfind('", -- [')
    if idx >= 0:
        s = s[:idx]
    elif s.endswith('"],'):
        s = s[:-2]
    elif s.endswith('",'):
        s = s[:-2]
    elif s.endswith('"'):
        s = s[:-1]
    return s


# --------------------------------------------------------------------------- data
class Pull(object):
    def __init__(self, archive, t0):
        self.archive = archive
        self.t0 = t0
        self.t_end = t0
        self.units = {}       # guid -> {name, mob, boss, klass}
        self.by_name = {}     # name -> mob
        self.engages = []     # [(name, mob, guid, is_boss)]
        self.events = []      # (abs_t, mob, unit_name, kind, spell_id, spell_name, extra)
        self.talk = []        # (abs_t, kind, npc, text)
        self.primary = None
        self.klass = ""
        self.module = None
        self.conf = "guess"

    # -- units ------------------------------------------------------------
    def add_engage(self, name, mob, guid, is_boss):
        if guid == "nil" or name in BAD_NAMES:
            return
        u = self.units.get(guid)
        if u is None:
            u = self.units[guid] = {"name": name, "mob": int(mob), "boss": is_boss,
                                    "klass": "", "pet": guid_is_pet(guid)}
        else:
            u["boss"] = u["boss"] or is_boss
        self.engages.append((name, int(mob), guid, is_boss))
        self.by_name.setdefault(name, int(mob))

    def add_target(self, name, mob, guid, klass):
        if not mob or name in BAD_NAMES:
            return
        u = self.units.get(guid)
        if u is None:
            self.units[guid] = {"name": name, "mob": mob, "boss": False,
                                "klass": klass, "pet": guid_is_pet(guid)}
            self.by_name.setdefault(name, mob)
        else:
            if u["name"] in BAD_NAMES:
                u["name"] = name
            if klass:
                u["klass"] = klass

    def unit_for(self, guid, name):
        u = self.units.get(guid)
        if u is not None:
            if name and u["name"] in BAD_NAMES:
                u["name"] = name
            return u
        mob = creature_id(guid)
        if not mob:
            return None
        u = self.units[guid] = {"name": name or "?", "mob": mob, "boss": False,
                                "klass": "", "pet": guid_is_pet(guid)}
        if name:
            self.by_name.setdefault(name, mob)
        return u

    def _candidates(self):
        """unit records that may be the encounter boss, best first"""
        counts = collections.Counter()
        for _t, mob, _u, _k, _sid, _s, _e in self.events:
            if mob:
                counts[mob] += 1
        out = []
        for u in self.units.values():
            if u["pet"]:
                continue
            out.append((u["klass"] in BOSS_CLASSES, u["boss"], counts.get(u["mob"], 0),
                        u["name"], u["mob"], u["klass"]))
        out.sort(key=lambda c: (-c[0], -c[1], -c[2]))
        return out

    def pick_primary(self, hints=frozenset(), index=None):
        real = [e for e in self.engages if e[3]]
        if not real:
            real = [e for e in self.engages if e[1]]
        if real:
            counts = collections.Counter((e[0], e[1]) for e in real)
            self.primary = counts.most_common(1)[0][0]
            self.module = (index or {}).get(self.primary[1])
            return
        # no engage data (some servers/dungeons): BigWigs mob ids win,
        # then npc names that yell/emote, then the busiest creature.
        index = index or {}
        cands = self._candidates()
        indexed = [c for c in cands if c[4] in index]
        hinted = [c for c in cands if c[3] in hints]
        if indexed:
            cands = indexed
        elif hinted:
            cands = hinted
        if cands:
            self.primary = (cands[0][3], cands[0][4])
            self.klass = cands[0][5]
            self.module = index.get(self.primary[1])

    def confidence(self, hints=frozenset(), index=None):
        if self.engages:
            return "engage"
        if self.primary and (index or {}).get(self.primary[1]):
            return "bigwigs"
        if self.primary and self.primary[0] in hints:
            return "yell"
        return "guess"

    def is_boss_like(self, min_time, hints=frozenset(), index=None):
        if self.engages:
            return True
        if self.duration() < min_time or not self.events or not self.primary:
            return False
        if (index or {}).get(self.primary[1]):
            return True
        if self.primary[0] in hints:
            return True
        if self.duration() < min_time:
            return False
        cands = self._candidates()
        if not cands:
            return False
        _is_elite, _boss, n, _name, mob, klass = cands[0]
        if klass in BOSS_CLASSES:
            return self.duration() >= max(35.0, min_time) and n >= 20
        # no classification known: demand a long, busy, multi-ability fight
        spells = {(sid, sname) for _t, m, _u, k, sid, sname, _e in self.events
                  if m == mob and k.startswith(("CAST", "U_"))}
        return self.duration() >= max(60.0, min_time * 2.0) and n >= 40 and len(spells) >= 5

    def duration(self):
        return max(0.0, self.t_end - self.t0)

    def wall_start(self):
        info = self.archive
        try:
            base = datetime.datetime.strptime(
                "%s %s" % (info["date"], info["time"]), "%Y-%m-%d %H:%M:%S")
        except ValueError:
            return info["date"], "000000"
        wall = base + datetime.timedelta(seconds=int(self.t0))
        return wall.strftime("%Y-%m-%d"), wall.strftime("%H%M%S")

    def spell_times(self):
        out = collections.defaultdict(list)
        for t, mob, uname, kind, sid, sname, _ in self.events:
            out[(mob, uname, sid, sname, kind)].append(t - self.t0)
        for v in out.values():
            v.sort()
        return out

    def talk_times(self):
        out = collections.defaultdict(list)
        for t, kind, npc, text in self.talk:
            out[(kind, npc, text)].append(t - self.t0)
        for v in out.values():
            v.sort()
        return out


class Session(object):
    def __init__(self, archive):
        self.archive = archive
        self.timers = collections.defaultdict(dict)
        self.markers = set()      # (t, 'on'/'off')
        self.engages = []         # (t, [(name, mob, guid, is_boss)])
        self.targets = []         # (t, name, mob, guid, klass)
        self.events = []          # (t, mob, name, kind, sid, sname, extra)
        self.talk = []            # (t, kind, npc, text)
        self.zones = []           # (t, zone name) from ZONE_CHANGED*
        self.boss_names = set()   # npc names that yell/emote -> real bosses
        self.pulls = []


class Collector(object):
    def __init__(self, args, boss_index=None):
        self.args = args
        self.boss_index = boss_index or {}
        self.sessions = []
        self.sess = None
        self.skipped = 0
        self.last_t = 0.0
        self.last_content = ""
        self.timer_sub = None

    # -- archive ---------------------------------------------------------
    def on_archive(self, info):
        self.sess = None
        self.timer_sub = None
        self.last_t = 0.0
        self.last_content = ""
        if self._skip(info):
            self.skipped += 1
            return
        self.sess = Session(info)
        self.sessions.append(self.sess)

    def _skip(self, info):
        if self.args.all:
            return False
        if info["zoneId"] in PVP_ZONE_IDS or info["type"].lower() in PVP_TYPES:
            return True
        low = info["display"].lower()
        if any(n in low for n in PVP_ZONE_NAMES):
            return True
        if self.args.since and info["date"] < self.args.since:
            return True
        if self.args.until and info["date"] > self.args.until:
            return True
        if self.args.zone:
            z = self.args.zone.lower()
            if z not in info["display"].lower() and z not in info["zone"].lower():
                return True
        return False

    # -- sections --------------------------------------------------------
    def on_section(self, info, section):
        self.last_t = 0.0
        self.last_content = ""
        self.timer_sub = None

    def on_section_end(self, info, section):
        pass

    def on_archive_end(self, info):
        if self.sess is not None:
            if self.sess.archive["display"] in BAD_NAMES and self.sess.zones:
                self.sess.archive["display"] = self.sess.zones[0][1]
            self._build_pulls(self.sess)
            self.sess = None

    # -- lines -----------------------------------------------------------
    def on_line(self, info, section, line):
        if self.sess is None:
            return
        if section == "TIMERS":
            self._timers(line)
        elif section in ("total", "COMBAT"):
            self._record(line, section)

    def _record(self, line, section):
        content = unwrap(line)
        m = HDR_RE.match(content)
        if m:
            self.last_t = float(m.group("t"))
            self.last_content = content
            content = content
        else:
            content = self.last_content
        if not content:
            return
        t = self.last_t
        sess = self.sess

        if "INSTANCE_ENCOUNTER_ENGAGE_UNIT" in content:
            blocks = []
            for bm in ENGAGE_RE.finditer(content):
                idx, name, mob, guid = bm.groups()
                if guid != "nil" and name.strip() not in BAD_NAMES:
                    blocks.append((name.strip(), int(mob), guid, idx == "boss1"))
            if blocks:
                sess.engages.append((t, blocks))
            return

        if "UNIT_TARGET" in content:
            tm = TARGET_RE.search(content)
            if tm:
                rest = tm.group("rest")
                idm = re.search(r"#ID:(\d+)#GUID:(0x[0-9A-Fa-f]+)#", rest)
                if idm:
                    cm = re.search(r"#Classification:([^#]*)", rest)
                    sess.targets.append((t, clean(tm.group("name")), int(idm.group(1)),
                                         idm.group(2), (cm.group(1) if cm else "").strip()))
            return

        if "PLAYER_REGEN_DISABLED" in content:
            sess.markers.add((t, "on"))
            return
        if "PLAYER_REGEN_ENABLED" in content:
            sess.markers.add((t, "off"))
            return

        if section == "COMBAT":
            return

        pos = content.find("> ")
        if pos < 0:
            return
        body = content[pos + 2:].strip()
        if not body.startswith("["):
            return
        end = body.find("]")
        if end < 0:
            return
        event = body[1:end]
        rest = body[end + 1:].strip()

        if event == "CLEU":
            self._cleu(t, rest)
        elif event.startswith("UNIT_SPELLCAST_"):
            self._unitcast(t, event, rest)
        elif event in TALK_MAP:
            parts = rest.split("#")
            text = clean(parts[0])
            npc = clean(parts[1]) if len(parts) > 1 else ""
            kind = TALK_MAP[event]
            if npc and kind in ("YELL", "BOSS_EMOTE", "BOSS_WHISPER"):
                sess.boss_names.add(npc)
            if text:
                sess.talk.append((t, kind, npc, text.replace("%s", npc)))
        elif event in ("ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS"):
            parts = rest.split("#")
            zone = clean(parts[0])
            if zone:
                sess.zones.append((t, zone))

    def _cleu(self, t, rest):
        event, _, data = rest.partition("#")
        condensed = event.endswith("[CONDENSED]")
        if condensed:
            event = event[:-11]
        kind = KIND_MAP.get(event)
        toks = data.split("#")
        if len(toks) < 5:
            return
        src, src_name, dst, dst_name = toks[0], toks[1], toks[2], toks[3]
        if event == "UNIT_DIED":
            if creature_id(dst):
                self.sess.events.append((t, creature_id(dst), clean(dst_name), "DIED", 0, "", ""))
            return
        if kind is None:
            return
        mob = creature_id(src)
        if not mob or guid_is_pet(src):
            return
        if condensed:
            cm = re.search(r"#(\d+) Targets#(\d+)#([^#\"]*)", data)
            if not cm:
                return
            sid, sname = int(cm.group(2)), clean(cm.group(3))
            extra = cm.group(1) + " targets"
        else:
            if len(toks) < 6:
                return
            try:
                sid = int(toks[4])
            except ValueError:
                return
            sname = clean(toks[5])
            extra = ""
            if kind in ("AURA+", "AURA~", "AURA-", "AURA+DOSE"):
                if dst_name and dst_name != src_name:
                    extra = clean(dst_name)
                if len(toks) > 7 and toks[7] not in ("nil", ""):
                    extra = (extra + " x" + toks[7]).strip()
            elif kind in ("SUMMON", "MISS", "DISPEL", "INTERRUPT"):
                extra = clean(dst_name) if dst_name not in BAD_NAMES else ""
        self.sess.events.append((t, mob, clean(src_name), kind, sid, sname, extra))

    def _unitcast(self, t, event, rest):
        m = UNITCAST_RE.match(rest)
        if not m:
            return
        name = clean(m.group("name")).strip()
        spell = clean(m.group("spell")).strip()
        if not name or not spell:
            return
        self.sess.events.append((t, 0, name, "U_" + event.replace("UNIT_SPELLCAST_", ""),
                                 0, spell, m.group("mode") or ""))

    def _timers(self, line):
        s = unwrap(line).strip()
        if not s:
            return
        m = re.match(r'^\s*\["([^"]+)"\] = \{', line)
        if m:
            self.timer_sub = m.group(1)
            return
        if " = pull:" not in s:
            return
        key, _, tail = s.rpartition(" = pull:")
        if not key:
            return
        vals = [float(x) for x in re.findall(r"\d+(?:\.\d+)?", tail)]
        if not vals:
            return
        sub = self.timer_sub or "MISC"
        key = clean(key)
        if sub in ("YELLS", "EMOTES") and "-npc:" in key:
            npc = key.rsplit("-npc:", 1)[1].split("-")[0].strip()
            if npc:
                self.sess.boss_names.add(npc)
        self.sess.timers[sub][key] = vals

    # -- pull building ---------------------------------------------------
    def _build_pulls(self, sess):
        markers = sorted(sess.markers)
        windows = []
        start = None
        for t, state in markers:
            if state == "on":
                if start is None:
                    start = t
            elif start is not None:
                windows.append((start, max(t, start)))
                start = None
        if start is not None:
            end = max([e[0] for e in sess.events] + [start])
            windows.append((start, end))
        if not windows:
            return

        # a boss engage usually lands a second before PLAYER_REGEN_DISABLED
        engage_ts = [t for t, _b in sess.engages]
        fixed_windows = []
        for a, b in windows:
            near = [t for t in engage_ts if a - 12.0 <= t <= a + 5.0]
            if near:
                a = min(a, min(near))
            fixed_windows.append((a, b))
        windows = fixed_windows

        pulls = [Pull(sess.archive, a) for a, _b in windows]
        starts = [p.t0 for p in pulls]

        def owner(t, pre=0.0):
            i = bisect.bisect_right(starts, t) - 1
            if i < 0:
                return pulls[0] if starts and starts[0] - t <= pre else None
            p = pulls[i]
            if t <= windows[i][1] + 1.0:
                return p
            return None

        for t, blocks in sess.engages:
            p = owner(t, pre=12.0)
            if p is not None:
                for name, mob, guid, is_boss in blocks:
                    p.add_engage(name, mob, guid, is_boss)
        for t, name, mob, guid, klass in sess.targets:
            p = owner(t, pre=12.0)
            if p is not None:
                p.add_target(name, mob, guid, klass)

        # assign a unit mob id by name for UNIT_SPELLCAST lines
        events = sorted(sess.events, key=lambda e: e[0])
        talk = sorted(sess.talk, key=lambda e: e[0])
        for e in events:
            p = owner(e[0])
            if p is not None:
                p.events.append(e)
                if e[1] and e[2]:
                    p.by_name.setdefault(e[2], e[1])
        for e in talk:
            p = owner(e[0])
            if p is not None:
                p.talk.append(e)

        for p in pulls:
            p.t_end = max(p.t_end, p.t0)
            if p.events:
                p.t_end = max(p.t_end, p.events[-1][0])
            # UNIT_SPELLCAST carries no guid: resolve by name, drop player pets
            unit_by_name = {}
            for u in p.units.values():
                unit_by_name.setdefault(u["name"], u)
            fixed = []
            for t, mob, name, kind, sid, sname, extra in p.events:
                if not mob:
                    u = unit_by_name.get(name)
                    if u is None or u["pet"]:
                        continue
                    mob = u["mob"]
                fixed.append((t, mob, name, kind, sid, sname, extra))
            p.events = fixed
            for t, mob, name, _k, _sid, _s, _e in p.events:
                if mob and name not in p.by_name:
                    p.by_name[name] = mob
            # zone this pull happened in (archives can span several dungeons)
            zone = sess.archive["display"]
            for zt, zname in sess.zones:
                if zt <= p.t0:
                    zone = zname
                else:
                    break
            p.zone = zone
            p.zone_id = sess.archive["zoneId"] if zone in (
                sess.archive["display"], sess.archive["zoneName"], sess.archive["subzone"]) else ZONE_NAME_IDS.get(zone.lower(), 0)
            # servants / adds whose src name was unknown get the resolved name
            mob_names = {u["mob"]: u["name"] for u in p.units.values()}
            p.events = [
                (t, mob, mob_names.get(mob, name) if name in BAD_NAMES else name,
                 kind, sid, sname, extra)
                for t, mob, name, kind, sid, sname, extra in p.events]
            p.pick_primary(sess.boss_names, self.boss_index)
            if p.primary is None:
                continue
            if p.duration() < self.args.min_pull:
                continue
            if not self.args.keep_trash and not p.is_boss_like(
                    self.args.min_boss, sess.boss_names, self.boss_index):
                continue
            p.conf = p.confidence(sess.boss_names, self.boss_index)
            sess.pulls.append(p)


# --------------------------------------------------------------------------- rendering
def write_text(path, text):
    d = os.path.dirname(path)
    if d and not os.path.isdir(d):
        os.makedirs(d)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


def write_timeline(path, pull, block):
    name, mob = pull.primary
    date, clock = pull.wall_start()
    info = pull.archive
    units = []
    seen_mobs = set()
    for u in pull.units.values():
        if u["mob"] in seen_mobs:
            continue
        seen_mobs.add(u["mob"])
        units.append("%s(%d)%s" % (u["name"], u["mob"], "*" if u["boss"] else ""))
    out = [
        "# %s  mob=%d  %s  %s  %s  duration=%.1fs" % (
            name, mob, pull.zone, info["difficultyText"], info["type"], pull.duration()),
        "# pull start: %s %s:%s:%s" % (date, clock[0:2], clock[2:4], clock[4:6]),
        "# source: %s%s" % (
            pull.conf,
            ("   module: %s (encounter %d, %s)" % (
                pull.module["module"], pull.module["encounterId"], pull.module["file"]))
            if pull.module else ""),
        "# units: " + ", ".join(units),
        "# legend: CAST_START/CAST_OK = CLEU, U_START/U_SUCCEEDED = UNIT_SPELLCAST, "
        "AURA+/AURA-/AURA~, SUMMON, DIED, YELL/SAY/EMOTE/BOSS_EMOTE",
        "",
    ]
    # collapse identical (second, unit, kind, spell) rows
    seen = collections.OrderedDict()
    for t, emob, uname, kind, sid, sname, extra in pull.events:
        key = (int(t), emob, uname, kind, sid, sname)
        if key in seen:
            seen[key][1] += 1
        else:
            seen[key] = [extra, 1]
    rows = [(t - pull.t0, emob, uname, kind, sid, sname, v[0], v[1])
            for (t, emob, uname, kind, sid, sname), v in seen.items()]
    for t, kind, npc, text in pull.talk:
        rows.append((t - pull.t0, 0, npc, kind, 0, text, "", 1))
    rows.sort(key=lambda r: (r[0], r[2]))

    block_n = 0
    for rel, emob, uname, kind, sid, sname, extra, n in rows:
        if block > 0:
            b = int(rel // block)
            if b != block_n:
                block_n = b
                out.append("")
                out.append("# ---- %d..%ds ----" % (b * block, (b + 1) * block))
        ability = sname if not sid else "%s (%d)" % (sname, sid)
        out.append("%8.2f  %-30s %-11s %-38s %3d  %s" % (
            rel, (uname or "")[:30], kind[:11], ability[:38], n, extra[:30]))
    write_text(path, "\n".join(out) + "\n")


def aggregate(boss_pulls):
    spells = collections.OrderedDict()
    talk = collections.OrderedDict()
    units = collections.OrderedDict()
    for pull in boss_pulls:
        for key, times in pull.spell_times().items():
            st = spells.get(key)
            if st is None:
                st = spells[key] = {"n": 0, "pulls": 0, "firsts": [], "iv": []}
            st["n"] += len(times)
            st["pulls"] += 1
            st["firsts"].append(times[0])
            if key[4] in IV_KINDS:
                st["iv"].extend(b - a for a, b in zip(times, times[1:])
                                if 0.05 <= b - a <= 1200.0)
        for key, times in pull.talk_times().items():
            tt = talk.get(key)
            if tt is None:
                tt = talk[key] = {"n": 0, "pulls": 0, "firsts": [], "iv": []}
            tt["n"] += len(times)
            tt["pulls"] += 1
            tt["firsts"].append(times[0])
            tt["iv"].extend(b - a for a, b in zip(times, times[1:]))
        for u in pull.units.values():
            uu = units.get(u["mob"])
            if uu is None:
                uu = units[u["mob"]] = {"name": u["name"], "boss": False, "klass": u["klass"]}
            uu["boss"] = uu["boss"] or u["boss"]
            if not uu["klass"] and u["klass"]:
                uu["klass"] = u["klass"]
        for name, umob in pull.by_name.items():
            if umob and umob not in units:
                units[umob] = {"name": name, "boss": False, "klass": ""}
    return spells, talk, units


def write_summary(path, boss_name, mob, boss_pulls, timeline_files):
    info = boss_pulls[0].archive
    total = sum(p.duration() for p in boss_pulls)
    spells, talk, units = aggregate(boss_pulls)
    out = []
    out.append("=" * 78)
    out.append(" BOSS: %s   mob=%d" % (boss_name, mob))
    mod = next((p.module for p in boss_pulls if p.module), None)
    zi = boss_pulls[0].zone_id or (mod["zoneId"] if mod else 0)
    out.append(" zone: %s%s  difficulty: %s  type: %s" % (
        boss_pulls[0].zone, (" (%d)" % zi) if zi else "",
        info["difficultyText"], info["type"]))
    out.append(" pulls: %d   combat time: %.1fs" % (len(boss_pulls), total))
    if mod:
        out.append(" module: %s   encounterId: %d   (%s)" % (
            mod["module"], mod["encounterId"], mod["file"]))
    out.append(" source: %s" % next((p.conf for p in boss_pulls if p.conf), "?"))
    out.append(" sources: " + ", ".join(sorted({
        "%s %s" % (p.archive["date"], p.archive["time"]) for p in boss_pulls})))
    out.append("=" * 78)
    out.append("")
    out.append("-- PULLS " + "-" * 69)
    for pull, fname in zip(boss_pulls, timeline_files):
        date, clock = pull.wall_start()
        seen_m = set()
        pick = []
        for u in pull.units.values():
            if (u["boss"] or u["mob"] == mob) and u["mob"] not in seen_m:
                seen_m.add(u["mob"])
                pick.append(u)
        units_s = ", ".join("%s %d%s" % (u["name"], u["mob"], "*" if u["boss"] else "")
                            for u in pick)
        out.append("  %s %s:%s:%s  %7.1fs  %s" % (
            date, clock[0:2], clock[2:4], clock[4:6], pull.duration(), fname))
        out.append("      units: %s" % units_s)
    out.append("")
    out.append("-- ABILITIES (timer candidates) " + "-" * 45)
    out.append("  %-28s %-7s %-7s %-31s %-12s %5s %7s %16s" % (
        "unit", "mob", "spellId", "ability", "event", "n", "first", "interval med"))
    by_unit = collections.defaultdict(list)
    for key, st in spells.items():
        by_unit[(key[0], key[1])].append((key, st))
    for (umob, uname), items in sorted(
            by_unit.items(), key=lambda kv: (-sum(s["n"] for _, s in kv[1]), str(kv[0]))):
        out.append("")
        out.append("  --- %s (mob %d)" % (uname, umob))
        items.sort(key=lambda kv: (min(kv[1]["firsts"]), -kv[1]["n"]))
        for (m, un, sid, sname, kind), st in items:
            first = statistics.median(st["firsts"]) if st["firsts"] else 0.0
            line = "  %-28s %-7d %-7s %-31s %-12s %5d %7.1f" % (
                uname[:28], umob, sid or "-", sname[:31], kind, st["n"], first)
            if len(st["iv"]) >= 2:
                line += "  %6.1f (%.1f-%.1f)" % (
                    statistics.median(st["iv"]), min(st["iv"]), max(st["iv"]))
            elif st["iv"]:
                line += "  %6.1f" % st["iv"][0]
            out.append(line)
    out.append("")
    out.append("-- SUGGESTED CDBar(spellId, interval) " + "-" * 41)
    allowed_mobs = {p.primary[1] for p in boss_pulls}
    for p in boss_pulls:
        allowed_mobs.update(u["mob"] for u in p.units.values() if u["boss"] or not u["pet"] and u["klass"] in BOSS_CLASSES)
    suggestions = []
    for (m, un, sid, sname, kind), st in spells.items():
        if m not in allowed_mobs:
            continue
        if not sid or kind not in ("CAST_START", "CAST_OK", "U_SUCCEEDED"):
            continue
        if len(st["iv"]) < 2:
            continue
        med = statistics.median(st["iv"])
        if med < 1.5:
            continue
        spread = max(st["iv"]) - min(st["iv"])
        suggestions.append((med, sid, sname, un, st["n"], min(st["iv"]), max(st["iv"]),
                            spread <= med * 0.5))
    suggestions.sort()
    if not suggestions:
        out.append("  (not enough repeated casts)")
    for med, sid, sname, un, n, lo, hi, stable in suggestions:
        out.append("  self:CDBar(%d, %.1f)  -- %-32s %-22s x%-3d (%.1f-%.1f)%s" % (
            sid, med, sname[:32], un[:22], n, lo, hi, "" if stable else "  irregular"))
    out.append("")
    out.append("-- TALK / EMOTES " + "-" * 61)
    if not talk:
        out.append("  (none)")
    for (kind, npc, text), st in sorted(
            talk.items(), key=lambda kv: (min(kv[1]["firsts"]), kv[0][0])):
        first = statistics.median(st["firsts"]) if st["firsts"] else 0.0
        line = "  [%7.1f] %-12s %-22s \"%s\"  x%d" % (
            first, kind, npc[:22], text[:70], st["n"])
        if len(st["iv"]) >= 2:
            line += "  repeats ~%.1fs (%.1f-%.1f)" % (
                statistics.median(st["iv"]), min(st["iv"]), max(st["iv"]))
        out.append(line)
    out.append("")
    out.append("-- UNITS " + "-" * 69)
    for umob, u in sorted(units.items(), key=lambda kv: (not kv[1]["boss"], str(kv[1]["name"]))):
        out.append("  mob %-7d %-40s %s%s" % (
            umob, u["name"], "boss" if u["boss"] else "",
            ("  " + u["klass"]) if u["klass"] else ""))
    write_text(path, "\n".join(out) + "\n")


def write_timers(path, session):
    out = ["# Transcriptor TIMERS - %s %s - %s (%d)" % (
        session.archive["date"], session.archive["time"],
        session.archive["display"], session.archive["zoneId"]), ""]
    for sub in ("YELLS", "EMOTES", "SPELL_CAST_START", "SPELL_CAST_SUCCESS",
                "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED",
                "SPELL_AURA_APPLIED", "HIDDEN_AURAS", "PLAYER_AURAS"):
        data = session.timers.get(sub)
        if not data:
            continue
        out.append("== %s ==" % sub)
        for key in sorted(data):
            vals = data[key]
            out.append("  %s = pull:%.2f%s" % (
                key, vals[0], "".join(", %.2f" % v for v in vals[1:6])))
        out.append("")
    if len(out) <= 2:
        return None
    write_text(path, "\n".join(out) + "\n")
    return path


# --------------------------------------------------------------------------- main
def main(argv=None):
    ap = argparse.ArgumentParser(description="Transcriptor.lua -> BigWigs encounter data")
    ap.add_argument("source")
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "extracted"))
    ap.add_argument("--zone")
    ap.add_argument("--since")
    ap.add_argument("--until")
    ap.add_argument("--min-pull", type=float, default=10.0)
    ap.add_argument("--min-boss", type=float, default=25.0,
                    help="minimum length of a boss-like pull without engage data")
    ap.add_argument("--split-timeline", type=float, default=300.0)
    ap.add_argument("--keep-trash", action="store_true")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--addons-root",
                    default=os.path.dirname(os.path.dirname(os.path.dirname(
                        os.path.abspath(__file__)))),
                    help="folder that contains BigWigs_WrathOfTheLichKing etc.")
    ap.add_argument("--no-bigwigs-index", action="store_true",
                    help="do not read installed BigWigs modules for boss mob ids")
    args = ap.parse_args(argv)

    if not os.path.isfile(args.source):
        print("no such file: %s" % args.source)
        return 1

    boss_index = {}
    if not args.no_bigwigs_index:
        boss_index = load_bigwigs_index(args.addons_root)
        print("BigWigs boss index: %d mob ids" % len(boss_index))

    col = Collector(args, boss_index)
    lines = 0
    for ev in iter_transcriptor(args.source):
        kind = ev[0]
        if kind == "archive":
            col.on_archive(ev[1])
        elif kind == "section":
            col.on_section(ev[1], ev[2])
        elif kind == "line":
            lines += 1
            col.on_line(ev[1], ev[2], ev[3])
        elif kind == "section_end":
            col.on_section_end(ev[1], ev[2])
        elif kind == "archive_end":
            col.on_archive_end(ev[1])

    all_pulls = []
    for sess in col.sessions:
        all_pulls.extend(sess.pulls)
    if not all_pulls:
        print("no instance encounters found (%d lines scanned, %d pvp/other archives skipped)" % (
            lines, col.skipped))
        return 0

    zones = collections.OrderedDict()            # zone name -> bosses
    zone_ids = {}
    for pull in all_pulls:
        zones.setdefault(pull.zone, collections.OrderedDict())
        zones[pull.zone].setdefault(pull.primary, []).append(pull)
        if pull.module and pull.module["zoneId"]:
            zone_ids[pull.zone] = pull.module["zoneId"]
        elif pull.zone_id:
            zone_ids.setdefault(pull.zone, pull.zone_id)

    if args.list:
        for zname, bosses in zones.items():
            for (bname, bmob), pulls in bosses.items():
                print("%-34s %-30s %-7d %-3s %3d %8.1fs" % (
                    zname[:34], bname[:30], bmob, pulls[0].conf, len(pulls),
                    sum(p.duration() for p in pulls)))
        print("\n%d pulls in %d zones" % (len(all_pulls), len(zones)))
        return 0

    for sess in col.sessions:
        if not sess.timers:
            continue
        info = sess.archive
        write_timers(os.path.join(args.out, "_sessions", "%s_%s_%s_timers.txt" % (
            info["date"], info["time"].replace(":", "")[:4],
            safe_name(info["display"], 40))), sess)

    index = ["# Transcriptor extraction", "",
             "source: `%s`" % os.path.abspath(args.source),
             "generated: %s" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
             "lines scanned: %d, pulls kept: %d, archives skipped (pvp/other): %d" % (
                 lines, len(all_pulls), col.skipped),
             "",
             "| zone | boss | mob | module | source | pulls | combat time | folder |",
             "|---|---|---|---|---|---|---|---|"]

    for zname, bosses in zones.items():
        zid = zone_ids.get(zname, 0)
        zfolder = ("%d_%s" % (zid, safe_name(zname))) if zid else safe_name(zname)
        zdir = os.path.join(args.out, zfolder)
        for (bname, bmob), pulls in bosses.items():
            bdir = os.path.join(zdir, "%s_%d" % (safe_name(bname), bmob))
            pulls.sort(key=lambda p: (p.archive["date"], p.t0))
            files = []
            for pull in pulls:
                date, clock = pull.wall_start()
                fname = "%s_%s.log" % (date, clock)
                path = os.path.join(bdir, fname)
                n = 2
                while os.path.exists(path):
                    path = os.path.join(bdir, "%s_%s_%d.log" % (date, clock, n))
                    n += 1
                write_timeline(path, pull, args.split_timeline)
                files.append(os.path.basename(path))
            write_summary(os.path.join(bdir, "summary.txt"), bname, bmob, pulls, files)
            label = ("%s (%d)" % (zname, zid)) if zid else zname
            mod = next((p.module["module"] for p in pulls if p.module), "")
            conf = next((p.conf for p in pulls if p.conf), "")
            index.append("| %s | %s | %d | %s | %s | %d | %.1fs | `%s` |" % (
                label, bname, bmob, mod, conf, len(pulls),
                sum(p.duration() for p in pulls),
                os.path.relpath(bdir, args.out).replace("\\", "/")))
            print("wrote %s  (%d pulls)" % (os.path.relpath(bdir, args.out), len(pulls)))

    write_text(os.path.join(args.out, "index.md"), "\n".join(index) + "\n")
    print("\n%d pulls in %d zones -> %s" % (len(all_pulls), len(zones), args.out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
