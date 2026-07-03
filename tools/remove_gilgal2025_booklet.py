"""Remove corrupted Gilgal 2025-2026 booklet entries from assets/songs.json."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SONGS_JSON = ROOT / "assets" / "songs.json"
CATEGORY = "Gilgal Worship 2025-2026"
ID_PREFIX = "gilgal2025_"


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    songs = json.loads(SONGS_JSON.read_text(encoding="utf-8"))
    removed = [s for s in songs if s.get("category") == CATEGORY or str(s.get("id", "")).startswith(ID_PREFIX)]
    kept = [s for s in songs if s not in removed]

    SONGS_JSON.write_text(
        json.dumps(kept, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    ids_path = ROOT / "tools" / "removed_gilgal2025_ids.txt"
    ids_path.write_text("\n".join(s["id"] for s in removed if s.get("id")), encoding="utf-8")

    print(f"Removed {len(removed)} booklet songs from {SONGS_JSON.name}")
    print(f"Remaining songs: {len(kept)}")
    print(f"IDs saved to {ids_path.name} (for Firestore cleanup)")


if __name__ == "__main__":
    main()
