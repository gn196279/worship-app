"""Delete song documents from Firestore by id list."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KEY_PATH = ROOT / "firestore-key.json"
PROJECT_ID = "my-worship-app-2cf1e"
COLLECTION = "songs"
DEFAULT_IDS = ROOT / "tools" / "removed_gilgal2025_ids.txt"


def get_client():
    from google.cloud import firestore

    if KEY_PATH.exists():
        return firestore.Client.from_service_account_json(str(KEY_PATH))
    return firestore.Client(project=PROJECT_ID)


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    ids_file = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_IDS
    if not ids_file.exists():
        raise SystemExit(f"Missing id list: {ids_file}")

    ids = [line.strip() for line in ids_file.read_text(encoding="utf-8").splitlines() if line.strip()]
    if not ids:
        print("No ids to delete.")
        return

    db = get_client()
    deleted = 0
    batch = db.batch()
    batch_count = 0

    for doc_id in ids:
        ref = db.collection(COLLECTION).document(doc_id)
        batch.delete(ref)
        batch_count += 1
        deleted += 1
        if batch_count >= 400:
            batch.commit()
            print(f"Deleted {deleted}...")
            batch = db.batch()
            batch_count = 0

    if batch_count:
        batch.commit()

    print(f"Deleted {deleted} documents from Firestore/{COLLECTION}.")


if __name__ == "__main__":
    main()
