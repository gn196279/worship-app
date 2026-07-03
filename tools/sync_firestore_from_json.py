"""Replace Firestore songs with assets/songs.json (full overwrite, not merge).

Also deletes Firestore-only docs (manual uploads, old booklet ids).
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SONGS_JSON = ROOT / "assets" / "songs.json"
KEY_PATH = ROOT / "firestore-key.json"
PROJECT_ID = "my-worship-app-2cf1e"
COLLECTION = "songs"
BOOKLET_PREFIX = "gilgal2025_"
BOOKLET_CATEGORY = "Gilgal Worship 2025-2026"


def get_client():
    from google.cloud import firestore

    if KEY_PATH.exists():
        return firestore.Client.from_service_account_json(str(KEY_PATH))
    return firestore.Client(project=PROJECT_ID)


def normalize_song(song: dict) -> dict:
    """Ensure chord fields are explicit so Firestore does not keep stale data."""
    out = dict(song)
    cp = (out.get("chordProText") or "").strip()
    ch = (out.get("chords") or "").strip()
    if cp:
        out["chordProText"] = cp
    else:
        out.pop("chordProText", None)
    if ch:
        out["chords"] = ch
    else:
        out.pop("chords", None)
    return out


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    if not SONGS_JSON.exists():
        raise SystemExit(f"Missing {SONGS_JSON}")

    songs = json.loads(SONGS_JSON.read_text(encoding="utf-8"))
    local_ids = set()
    db = get_client()

    batch = db.batch()
    batch_count = 0
    written = 0

    for song in songs:
        doc_id = str(song.get("id") or "").strip()
        if not doc_id:
            continue
        local_ids.add(doc_id)
        payload = normalize_song(song)
        batch.set(db.collection(COLLECTION).document(doc_id), payload)
        batch_count += 1
        written += 1
        if batch_count >= 400:
            batch.commit()
            print(f"Written {written} songs...")
            batch = db.batch()
            batch_count = 0

    if batch_count:
        batch.commit()
    print(f"Overwrote {written} songs from {SONGS_JSON.name}")

    deleted = 0
    batch = db.batch()
    batch_count = 0
    for doc in db.collection(COLLECTION).stream():
        data = doc.to_dict() or {}
        doc_id = doc.id
        raw_id = str(data.get("id") or doc_id)
        category = (data.get("category") or "").strip()

        remove = False
        if doc_id not in local_ids:
            remove = True
        if raw_id.startswith(BOOKLET_PREFIX):
            remove = True
        if category == BOOKLET_CATEGORY:
            remove = True
        if doc_id.startswith("manual_"):
            remove = True

        if not remove:
            continue

        batch.delete(doc.reference)
        batch_count += 1
        deleted += 1
        if batch_count >= 400:
            batch.commit()
            batch = db.batch()
            batch_count = 0

    if batch_count:
        batch.commit()
    print(f"Deleted {deleted} extra Firestore-only / booklet / manual docs")

    chord_count = 0
    total = 0
    for doc in db.collection(COLLECTION).stream():
        total += 1
        data = doc.to_dict() or {}
        cp = (data.get("chordProText") or "").strip()
        ch = (data.get("chords") or "").strip()
        if cp or ch:
            chord_count += 1
            print(f"  chord: {doc.id} | {data.get('title') or doc.id}")

    print(f"Firestore now: total={total}, with_chords={chord_count}")


if __name__ == "__main__":
    main()
