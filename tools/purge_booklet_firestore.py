"""Scan and delete corrupted Gilgal 2025 booklet songs from Firestore."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KEY_PATH = ROOT / "firestore-key.json"
PROJECT_ID = "my-worship-app-2cf1e"
COLLECTION = "songs"
BOOKLET_CATEGORY = "Gilgal Worship 2025-2026"
BOOKLET_PREFIX = "gilgal2025_"
DEFAULT_IDS = ROOT / "tools" / "removed_gilgal2025_ids.txt"


def get_client():
    from google.cloud import firestore

    if KEY_PATH.exists():
        return firestore.Client.from_service_account_json(str(KEY_PATH))
    return firestore.Client(project=PROJECT_ID)


def has_chord_field(data: dict) -> bool:
    cp = (data.get("chordProText") or "").strip()
    ch = (data.get("chords") or "").strip()
    return bool(cp or ch)


def is_booklet(data: dict, doc_id: str) -> bool:
    raw_id = (data.get("id") or doc_id or "").strip()
    category = (data.get("category") or "").strip()
    if category == BOOKLET_CATEGORY:
        return True
    if raw_id.startswith(BOOKLET_PREFIX):
        return True
    return False


def scan(db):
    booklet = []
    chord_songs = []
    total = 0
    for doc in db.collection(COLLECTION).stream():
        total += 1
        data = doc.to_dict() or {}
        doc_id = doc.id
        if is_booklet(data, doc_id):
            booklet.append((doc_id, data))
        if has_chord_field(data):
            title = data.get("title") or doc_id
            chord_songs.append((doc_id, title, data))

    return total, booklet, chord_songs


def delete_ids(db, ids: list[str]) -> int:
    deleted = 0
    batch = db.batch()
    batch_count = 0
    for doc_id in ids:
        batch.delete(db.collection(COLLECTION).document(doc_id))
        batch_count += 1
        deleted += 1
        if batch_count >= 400:
            batch.commit()
            batch = db.batch()
            batch_count = 0
    if batch_count:
        batch.commit()
    return deleted


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    mode = sys.argv[1] if len(sys.argv) > 1 else "scan"
    db = get_client()

    total, booklet, chord_songs = scan(db)
    print(f"Firestore/{COLLECTION}: total={total}")
    print(f"booklet_docs={len(booklet)}")
    print(f"with_chord_fields={len(chord_songs)}")
    print("\n--- chord songs in Firestore ---")
    for i, (doc_id, title, data) in enumerate(chord_songs, 1):
        booklet_flag = is_booklet(data, doc_id)
        print(f"{i:3}. {doc_id} | {title} | booklet={booklet_flag}")

    if mode != "delete":
        print("\nRun with 'delete' to remove booklet docs from Firestore:")
        print("  python tools/purge_booklet_firestore.py delete")
        return

    ids_to_delete = sorted({doc_id for doc_id, _ in booklet})
    if DEFAULT_IDS.exists():
        for line in DEFAULT_IDS.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line:
                ids_to_delete.append(line)
    ids_to_delete = sorted(set(ids_to_delete))

    if not ids_to_delete:
        print("Nothing to delete.")
        return

    print(f"\nDeleting {len(ids_to_delete)} booklet documents...")
    deleted = delete_ids(db, ids_to_delete)
    print(f"Deleted {deleted} documents.")

    _, booklet_after, chord_after = scan(db)
    print(f"\nAfter delete: booklet_docs={len(booklet_after)}, with_chord_fields={len(chord_after)}")
    if chord_after:
        print("Remaining chord songs (expected ~3):")
        for doc_id, title, _ in chord_after:
            print(f"  - {doc_id} | {title}")


if __name__ == "__main__":
    main()
