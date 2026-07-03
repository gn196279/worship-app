"""Verify Gilgal booklet songs have chart-ready chord text."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SONGS_JSON = ROOT / "assets" / "songs.json"
CATEGORY = "Gilgal Worship 2025-2026"
SAMPLE_IDS = [
    "gilgal2025_01",
    "gilgal2025_10",
    "gilgal2025_23",
    "gilgal2025_30",
    "gilgal2025_39",
]


def has_chart(song: dict) -> bool:
    cp = (song.get("chordProText") or "").strip()
    ch = (song.get("chords") or "").strip()
    lyr = (song.get("lyrics") or "").strip()
    return bool(cp or ch or lyr)


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    songs = json.loads(SONGS_JSON.read_text(encoding="utf-8"))
    by_id = {s["id"]: s for s in songs}
    booklet = [s for s in songs if s.get("category") == CATEGORY]
    with_chords = [s for s in songs if has_chart(s)]

    print(f"Booklet songs: {len(booklet)}")
    print(f"Songs with chart text: {len(with_chords)}")
    print("\nSample Chart-tab checks:")
    for sid in SAMPLE_IDS:
        s = by_id.get(sid)
        if not s:
            print(f"  {sid}: MISSING")
            continue
        ok = has_chart(s)
        preview = (s.get("chords") or s.get("lyrics") or "")[:60].replace("\n", " ")
        print(f"  {sid} | {s.get('title')} | chart_ok={ok}")
        print(f"    {preview}...")


if __name__ == "__main__":
    main()
