import json
import sys

sys.stdout.reconfigure(encoding="utf-8")

with open("assets/songs.json", encoding="utf-8") as f:
    songs = json.load(f)

chord_songs = []
for s in songs:
    cp = (s.get("chordProText") or "").strip()
    ch = (s.get("chords") or "").strip()
    if cp or ch:
        chord_songs.append(s)

print(f"total_songs={len(songs)}")
print(f"with_chordProText={sum(1 for s in songs if (s.get('chordProText') or '').strip())}")
print(f"with_legacy_chords={sum(1 for s in songs if (s.get('chords') or '').strip())}")
print(f"with_any_chord_field={len(chord_songs)}")
print(f"without_chord_fields={len(songs) - len(chord_songs)}")
print("\n--- chord songs ---")
for i, s in enumerate(chord_songs, 1):
    title = s.get("title") or s.get("id")
    cp = bool((s.get("chordProText") or "").strip())
    ch = bool((s.get("chords") or "").strip())
    print(f"{i:3}. {title}  [chordPro={cp}, legacy={ch}]")
