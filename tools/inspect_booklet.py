"""Print Gilgal 2025-2026 booklet songs for title review."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SONGS_JSON = ROOT / "assets" / "songs.json"


def preview(text: str, n: int = 100) -> str:
    return (text or "").replace("\n", " | ")[:n]


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    songs = json.loads(SONGS_JSON.read_text(encoding="utf-8"))
    booklet = [s for s in songs if s.get("category") == "Gilgal Worship 2025-2026"]
    for i, s in enumerate(booklet, 1):
        lyr = s.get("lyrics") or ""
        ch = s.get("chords") or ""
        first_lyr = preview(lyr.split("\n")[0] if lyr else "")
        first_ch = preview(ch.split("\n")[0] if ch else "")
        print(f"{i:02} {s['id']} | title={s.get('title')}")
        print(f"    lyr: {first_lyr}")
        print(f"    ch:  {first_ch}")


if __name__ == "__main__":
    main()
