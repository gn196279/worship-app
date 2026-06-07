import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SONGS_JSON = ROOT / "assets" / "songs.json"


def normalize(text: str) -> str:
    return " ".join((text or "").strip().lower().split())


def load_songs():
    with SONGS_JSON.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_songs(songs):
    with SONGS_JSON.open("w", encoding="utf-8") as f:
        json.dump(songs, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main(csv_path: str):
    if not SONGS_JSON.exists():
        raise FileNotFoundError(f"Missing {SONGS_JSON}")

    songs = load_songs()
    by_id = {s.get("id"): s for s in songs if s.get("id")}
    by_title = {normalize(s.get("title", "")): s for s in songs}

    updated = 0
    missing = 0

    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            song_id = (row.get("id") or "").strip()
            title = normalize(row.get("title") or "")
            chords = (row.get("chords") or "").strip()
            if not chords:
                continue

            target = None
            if song_id and song_id in by_id:
                target = by_id[song_id]
            elif title and title in by_title:
                target = by_title[title]

            if target is None:
                missing += 1
                continue

            target["chords"] = chords
            updated += 1

    save_songs(songs)
    print(f"Updated chords for {updated} songs. Missing: {missing}.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python tools/import_chords_from_csv.py <chords.csv>")
        sys.exit(1)
    main(sys.argv[1])

