import json
from google.cloud import firestore

# Path to your service account key
KEY_PATH = "firestore-key.json"
# Path to your songs.json file
SONGS_JSON_PATH = "assets/songs.json"
# Firestore collection name
COLLECTION_NAME = "songs"

def main():
    # Initialize Firestore client
    db = firestore.Client.from_service_account_json(KEY_PATH)

    # Load songs from JSON
    with open(SONGS_JSON_PATH, "r", encoding="utf-8") as f:
        songs = json.load(f)

    # Upload each song as a document
    for song in songs:
        # Use song ID or title as document ID if available, else Firestore will auto-generate
        doc_id = str(song.get("id") or song.get("title") or "")
        if doc_id:
            db.collection(COLLECTION_NAME).document(doc_id).set(song)
        else:
            db.collection(COLLECTION_NAME).add(song)
        print(f"Uploaded: {doc_id or '[auto-id]'}")

    print("All songs uploaded to Firestore.")

if __name__ == "__main__":
    main()