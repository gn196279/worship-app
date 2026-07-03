"""Upload assets/songs.json to Firestore project my-worship-app-2cf1e."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SONGS_JSON = ROOT / "assets" / "songs.json"
KEY_PATH = ROOT / "firestore-key.json"
PROJECT_ID = "my-worship-app-2cf1e"
COLLECTION = "songs"


def get_client():
    from google.cloud import firestore

    if KEY_PATH.exists():
        return firestore.Client.from_service_account_json(str(KEY_PATH))
    return firestore.Client(project=PROJECT_ID)


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    if not SONGS_JSON.exists():
        raise SystemExit(f"Missing {SONGS_JSON}")

    songs = json.loads(SONGS_JSON.read_text(encoding="utf-8"))
    db = get_client()
    batch = db.batch()
    batch_count = 0
    uploaded = 0

    for song in songs:
        doc_id = str(song.get("id") or "").strip()
        if not doc_id:
            continue
        ref = db.collection(COLLECTION).document(doc_id)
        batch.set(ref, song)
        batch_count += 1
        uploaded += 1

        if batch_count >= 400:
            batch.commit()
            print(f"Committed {uploaded} songs...")
            batch = db.batch()
            batch_count = 0

    if batch_count:
        batch.commit()

    print(f"Uploaded {uploaded} songs to Firestore/{COLLECTION}.")


if __name__ == "__main__":
    main()
