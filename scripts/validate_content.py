"""Validate Signcaster content JSON against docs/DATA_FORMATS.md.

Usage: python scripts/validate_content.py [--strict]

Errors fail the run (exit 1). Warnings (like missing art during development) only fail with --strict.
Standard library only, so it runs anywhere.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
CONTENT = GAME / "content"

WORD_KINDS = {"fingerspell", "word_sign"}
REVIEW_STATUSES = {"placeholder", "needs_review", "reviewed"}
UNLOCK_TYPES = {"default", "level", "stars"}
BUBBLE_STYLES = {"stay", "fade", "flash"}
DIRECTIONS = {"sign_it", "read_it"}
TWISTS = {None, "audible", "decoy"}
SLOTS = {
    "qb": {"helmet", "jersey", "cleats", "stadium", "celebration", "football"},
    "wizard": {"robe", "wand", "hat", "spell_color", "pet", "boots"},
}
# Store items are cosmetic only. Any of these keys means an item is trying to change gameplay.
GAMEPLAY_KEYS = {"speed", "time_bonus", "timer", "multiplier", "score", "points", "difficulty", "boost",
                 "extra_time", "coins_bonus", "power"}
# Content must never describe how a sign is made. Sign media is human-made and reviewed.
SIGN_TEXT_KEYS = {"description", "how_to_sign", "handshape", "instructions", "sign_description"}
WORD_RE = re.compile(r"^[A-Z]+$")
ID_RE = re.compile(r"^[a-z0-9_]+(\.[a-z0-9_]+)*$")


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.warnings: list[str] = []

    def error(self, where: str, msg: str) -> None:
        self.errors.append(f"ERROR   {where}: {msg}")

    def warn(self, where: str, msg: str) -> None:
        self.warnings.append(f"WARNING {where}: {msg}")


def load(path: Path, rep: Report):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        rep.error(str(path.relative_to(ROOT)), "file is missing")
    except json.JSONDecodeError as exc:
        rep.error(str(path.relative_to(ROOT)), f"invalid JSON: {exc}")
    return None


def require(obj: dict, keys: list[str], where: str, rep: Report) -> bool:
    ok = True
    for key in keys:
        if key not in obj:
            rep.error(where, f"missing key '{key}'")
            ok = False
    return ok


def check_version(obj: dict, where: str, rep: Report) -> None:
    if not isinstance(obj.get("version"), int) or obj.get("version", 0) < 1:
        rep.error(where, "'version' must be an integer >= 1")


def check_unlock(unlock, where: str, rep: Report, allow_default: bool, group_ids: set[str]) -> None:
    if unlock is None:
        return
    if not isinstance(unlock, dict) or unlock.get("type") not in UNLOCK_TYPES:
        rep.error(where, f"unlock must be null or have type in {sorted(UNLOCK_TYPES)}")
        return
    kind = unlock["type"]
    if kind == "default" and not allow_default:
        rep.error(where, "unlock type 'default' is only for word packs; use null for store items")
    if kind == "level":
        level_id = unlock.get("level_id", "")
        parts = level_id.split(".")
        if len(parts) != 3 or parts[0] not in SLOTS or parts[1] not in group_ids or not parts[2].isdigit():
            rep.error(where, f"level_id '{level_id}' must look like <mode>.<group id>.<n> with a group from difficulty.json")
    if kind == "stars" and (not isinstance(unlock.get("stars"), int) or unlock["stars"] < 1):
        rep.error(where, "stars unlock needs a positive integer 'stars'")


def validate_word_packs(rep: Report, group_ids: set[str]) -> None:
    folder = CONTENT / "word_packs"
    files = sorted(folder.glob("*.json"))
    if not files:
        rep.error("game/content/word_packs", "no word packs found")
    seen_ids: set[str] = set()
    for path in files:
        where = str(path.relative_to(ROOT))
        pack = load(path, rep)
        if pack is None:
            continue
        check_version(pack, where, rep)
        if not require(pack, ["id", "title", "kind", "unlock", "words"], where, rep):
            continue
        pid = pack["id"]
        if not isinstance(pid, str) or not ID_RE.match(pid) or "." in pid:
            rep.error(where, f"pack id '{pid}' must be lowercase letters, digits or underscores")
        if pack["kind"] not in WORD_KINDS:
            rep.error(where, f"kind must be one of {sorted(WORD_KINDS)}")
        check_unlock(pack["unlock"], where, rep, allow_default=True, group_ids=group_ids)
        if not isinstance(pack["words"], list) or not pack["words"]:
            rep.error(where, "words must be a non-empty list")
            continue
        for i, word in enumerate(pack["words"]):
            w_where = f"{where} words[{i}]"
            if not isinstance(word, dict):
                rep.error(w_where, "each word must be an object")
                continue
            if not require(word, ["id", "word", "kid_safe", "media", "review_status"], w_where, rep):
                continue
            bad_keys = SIGN_TEXT_KEYS & set(word)
            if bad_keys:
                rep.error(w_where, f"text descriptions of signs are not allowed: {sorted(bad_keys)}")
            text = word["word"]
            if not isinstance(text, str) or not WORD_RE.match(text):
                rep.error(w_where, f"word '{text}' must be uppercase A to Z only")
            elif pack["kind"] == "fingerspell" and not 2 <= len(text) <= 8:
                rep.error(w_where, f"fingerspelled word '{text}' must be 2 to 8 letters")
            expected_id = f"{pid}.{str(text).lower()}"
            if word["id"] != expected_id:
                rep.error(w_where, f"id should be '{expected_id}'")
            if word["id"] in seen_ids:
                rep.error(w_where, f"duplicate word id '{word['id']}'")
            seen_ids.add(word["id"])
            if not isinstance(word["kid_safe"], bool):
                rep.error(w_where, "kid_safe must be true or false")
            if word["review_status"] not in REVIEW_STATUSES:
                rep.error(w_where, f"review_status must be one of {sorted(REVIEW_STATUSES)}")
            media = word["media"]
            if not isinstance(media, dict) or "word_sign" not in media:
                rep.error(w_where, "media must be an object with a 'word_sign' key")
            elif pack["kind"] == "word_sign" and not media["word_sign"]:
                rep.warn(w_where, "word_sign pack entry has no sign media yet")


def validate_store(rep: Report, group_ids: set[str]) -> None:
    all_ids: set[str] = set()
    for mode in ("qb", "wizard"):
        path = CONTENT / "store" / f"{mode}_catalog.json"
        where = str(path.relative_to(ROOT))
        cat = load(path, rep)
        if cat is None:
            continue
        check_version(cat, where, rep)
        if not require(cat, ["mode", "items"], where, rep):
            continue
        if cat["mode"] != mode:
            rep.error(where, f"mode should be '{mode}'")
        free_slots: set[str] = set()
        for i, item in enumerate(cat["items"]):
            i_where = f"{where} items[{i}]"
            if not require(item, ["id", "name", "slot", "price", "unlock", "art"], i_where, rep):
                continue
            bad = GAMEPLAY_KEYS & set(item)
            if bad:
                rep.error(i_where, f"store items are cosmetic only, remove gameplay keys {sorted(bad)}")
            if not str(item["id"]).startswith(f"{mode}.") or not ID_RE.match(str(item["id"])):
                rep.error(i_where, f"id '{item['id']}' must start with '{mode}.' and be lowercase")
            if item["id"] in all_ids:
                rep.error(i_where, f"duplicate item id '{item['id']}'")
            all_ids.add(item["id"])
            if item["slot"] not in SLOTS[mode]:
                rep.error(i_where, f"slot '{item['slot']}' is not valid for {mode}: {sorted(SLOTS[mode])}")
            if not isinstance(item["price"], int) or item["price"] < 0:
                rep.error(i_where, "price must be a whole number >= 0")
            elif item["price"] == 0:
                free_slots.add(item["slot"])
            check_unlock(item["unlock"], i_where, rep, allow_default=False, group_ids=group_ids)
            art = str(item["art"])
            if not art.startswith(f"res://skins/{mode}/"):
                rep.error(i_where, f"art must be a res://skins/{mode}/ path")
            elif not (GAME / art.removeprefix("res://")).exists():
                rep.warn(i_where, f"art file not found yet: {art}")
        for slot in sorted(SLOTS[mode] - free_slots):
            rep.warn(where, f"no free starting item for slot '{slot}'")


def number(obj: dict, key: str, where: str, rep: Report, low: float | None = None, high: float | None = None):
    value = obj.get(key)
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        rep.error(where, f"'{key}' must be a number")
        return None
    if low is not None and value < low or high is not None and value > high:
        rep.error(where, f"'{key}' = {value} is outside {low} to {high}")
    return value


def validate_difficulty(rep: Report) -> set[str]:
    path = CONTENT / "config" / "difficulty.json"
    where = str(path.relative_to(ROOT))
    cfg = load(path, rep)
    if cfg is None:
        return set()
    check_version(cfg, where, rep)
    if not require(cfg, ["challenges_per_level", "modes", "tiers", "groups", "adaptive", "review"], where, rep):
        return set()
    number(cfg, "challenges_per_level", where, rep, 1, 20)
    for mode in SLOTS:
        m = cfg["modes"].get(mode)
        m_where = f"{where} modes.{mode}"
        if m is None:
            rep.error(where, f"missing mode '{mode}'")
            continue
        number(m, "study_seconds", m_where, rep, 0, 60)
        number(m, "timer_scale", m_where, rep, 0.5, 3)
        number(m, "max_new_words_per_level", m_where, rep, 0, 10)
        if m.get("default_bubble") not in BUBBLE_STYLES:
            rep.error(m_where, f"default_bubble must be one of {sorted(BUBBLE_STYLES)}")
    tier_ids: set[str] = set()
    for i, tier in enumerate(cfg["tiers"]):
        t_where = f"{where} tiers[{i}]"
        if not require(tier, ["id", "live_seconds", "word_length", "bubble_style", "directions", "twist", "is_boss"],
                       t_where, rep):
            continue
        if tier["id"] in tier_ids:
            rep.error(t_where, f"duplicate tier id '{tier['id']}'")
        tier_ids.add(tier["id"])
        number(tier, "live_seconds", t_where, rep, 2, 60)
        wl = tier["word_length"]
        if not (isinstance(wl, list) and len(wl) == 2 and all(isinstance(x, int) for x in wl) and 2 <= wl[0] <= wl[1] <= 8):
            rep.error(t_where, "word_length must be [min, max] with 2 <= min <= max <= 8")
        if tier["bubble_style"] is not None and tier["bubble_style"] not in BUBBLE_STYLES:
            rep.error(t_where, "bubble_style must be null or one of stay, fade, flash")
        if not tier["directions"] or not set(tier["directions"]) <= DIRECTIONS:
            rep.error(t_where, "directions must be a non-empty list of sign_it and read_it")
        if tier["twist"] not in TWISTS:
            rep.error(t_where, "twist must be null, 'audible' or 'decoy'")
        if "challenges" in tier:
            number(tier, "challenges", t_where, rep, 1, 20)
    group_ids: set[str] = set()
    for i, group in enumerate(cfg["groups"]):
        g_where = f"{where} groups[{i}]"
        if not require(group, ["id", "tiers"], g_where, rep):
            continue
        if not ID_RE.match(group["id"]) or "." in group["id"]:
            rep.error(g_where, "group id must be lowercase letters, digits or underscores")
        group_ids.add(group["id"])
        for tid in group["tiers"]:
            if tid not in tier_ids:
                rep.error(g_where, f"unknown tier '{tid}'")
    a = cfg["adaptive"]
    a_where = f"{where} adaptive"
    number(a, "window", a_where, rep, 1, 50)
    number(a, "fails_to_ease", a_where, rep, 1, 10)
    number(a, "fasts_to_harden", a_where, rep, 1, 10)
    number(a, "ease_factor", a_where, rep, 1.0, 2.0)
    number(a, "max_ease", a_where, rep, 1.0, 2.0)
    number(a, "harden_factor", a_where, rep, 0.5, 1.0)
    number(a, "max_harden", a_where, rep, 0.5, 1.0)
    r = cfg["review"]
    r_where = f"{where} review"
    boxes = number(r, "boxes", r_where, rep, 2, 10)
    number(r, "review_share", r_where, rep, 0, 1)
    due = r.get("due_every_sessions")
    if not isinstance(due, list) or (boxes is not None and len(due) != boxes):
        rep.error(r_where, "due_every_sessions must have one entry per box")
    return group_ids


def validate_simple_config(rep: Report) -> None:
    scoring_path = CONTENT / "config" / "scoring.json"
    s = load(scoring_path, rep)
    if s is not None:
        w = str(scoring_path.relative_to(ROOT))
        check_version(s, w, rep)
        number(s, "fast_threshold", w, rep, 0, 1)
        number(s, "base_points", w, rep, 1, 100000)
        number(s, "combo_step", w, rep, 0, 1)
        number(s, "combo_cap", w, rep, 1, 10)
        stars = s.get("stars", {})
        number(stars, "two_star_success_rate", f"{w} stars", rep, 0, 1)
        number(stars, "three_star_fast_rate", f"{w} stars", rep, 0, 1)
    economy_path = CONTENT / "config" / "economy.json"
    e = load(economy_path, rep)
    if e is not None:
        w = str(economy_path.relative_to(ROOT))
        check_version(e, w, rep)
        for key in ("coins_per_success", "fast_bonus", "perfect_level_bonus", "daily_challenge_bonus",
                    "streak_freeze_every_days", "max_streak_freezes"):
            number(e, key, w, rep, 0, 100000)


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Signcaster content JSON.")
    parser.add_argument("--strict", action="store_true", help="treat warnings as errors")
    args = parser.parse_args()
    rep = Report()
    group_ids = validate_difficulty(rep)
    validate_simple_config(rep)
    validate_word_packs(rep, group_ids)
    validate_store(rep, group_ids)
    for line in rep.errors + rep.warnings:
        print(line)
    failed = bool(rep.errors) or (args.strict and bool(rep.warnings))
    print(f"\n{len(rep.errors)} errors, {len(rep.warnings)} warnings. {'FAILED' if failed else 'OK'}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
