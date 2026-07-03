"""Fix Gilgal Worship 2025-2026 booklet entries in assets/songs.json."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SONGS_JSON = ROOT / "assets" / "songs.json"
CATEGORY = "Gilgal Worship 2025-2026"
ID_PREFIX = "gilgal2025_"

# Curated titles for the 2025–2026 chord booklet (PDF import had bad OCR on some).
MANUAL_TITLES: dict[str, str] = {
    "gilgal2025_01": "Aradhana Yesu Neeku",
    "gilgal2025_02": "Ascharya Karudu",
    "gilgal2025_03": "Kruthagnathatho (Offering Song)",
    "gilgal2025_04": "Neevu Nadhiche Dharulalo",
    "gilgal2025_05": "Lekkinchaleni (Blessing Song)",
    "gilgal2025_06": "Kruthagnathatho Sthuthi Paddedu",
    "gilgal2025_07": "Jaya (Blessing Song)",
    "gilgal2025_08": "Athyunnatha Simhasanamupai",
    "gilgal2025_09": "Ascharya Karudu (Alt)",
    "gilgal2025_10": "Nee Chethitho Nannu Pattuko",
    "gilgal2025_11": "Aradhana Yogyuda (Offering Song)",
    "gilgal2025_12": "Mee Prema Lekka Ledu (Blessing Song)",
    "gilgal2025_13": "Ramudu Parishudhathmuda",
    "gilgal2025_14": "Thandri Deva",
    "gilgal2025_15": "Kruthagnathatho Sthuthi Paddedu (Alt)",
    "gilgal2025_16": "Thandri Deva (Alt)",
    "gilgal2025_17": "Prema Yesuni Prema",
    "gilgal2025_18": "Sthiraparachuvaadavu",
    "gilgal2025_19": "Venkateswara Bankaraal",
    "gilgal2025_20": "Sudigalainanu",
    "gilgal2025_21": "Yehova Naamam (Capo 3)",
    "gilgal2025_22": "Thandri Deva (Capo)",
    "gilgal2025_23": "Vandanam (Capo 2)",
    "gilgal2025_24": "Vandanam – Mee Prema",
    "gilgal2025_25": "Natho Matladamayya",
    "gilgal2025_26": "Preminchedham",
    "gilgal2025_27": "Atruna Thamthula Thamilaranama",
    "gilgal2025_28": "Tallala Tallaa Naa Tanu",
    "gilgal2025_29": "Sampoornuda Parishudhathmuda",
    "gilgal2025_30": "Inthavaraku Neevu Nannu Nadipinchutaku",
    "gilgal2025_31": "Ghana Keerthana (Booklet)",
    "gilgal2025_32": "Ghana Keerthana (Telugu)",
    "gilgal2025_33": "Natho Matladamayya (Alt)",
    "gilgal2025_34": "Ramudu Parishudhathmuda (Alt)",
    "gilgal2025_35": "Aaradhana Yesu Ki",
    "gilgal2025_36": "Evarevareyee Vai Na Nu",
    "gilgal2025_37": "Ebenezer",
    "gilgal2025_38": "Padivelalo Athisundaruda",
    "gilgal2025_39": "Yehova Rapha",
    "gilgal2025_40": "Vandanam (Alt)",
}


def extract_title(lyrics: str, chords: str, fallback: str) -> str:
    raw = (lyrics or chords or "").strip()
    if not raw:
        return fallback

    first = raw.split("\n")[0].strip()
    # Drop trailing chord blocks and section markers.
    title = re.split(
        r"\s-\s*(?=[A-Ga-g#b]|Am|Em|Dm|Gm|Bm|Cm|Fm|Chorus|Verse|\[|Transponse|Transpose)",
        first,
        maxsplit=1,
    )[0]
    title = re.split(r"\[(?:Chorus|Verse|Pallavi|Intro)\s*\d*\]", title, maxsplit=1)[0]
    title = re.sub(r"\bChorus\s*$", "", title, flags=re.I).strip()
    title = re.sub(
        r"^(Offering Song:\s*|Oﬀering Song:\s*|Blessing Song\s*-\s*|Blessing song\s*-\s*)",
        "",
        title,
        flags=re.I,
    ).strip()
    title = re.sub(r"\s+", " ", title).strip(" -")

    if not title or title == "Vandanam - Capo 2":
        return fallback
    if len(title) > 72:
        title = title[:72].rstrip() + "..."
    return title


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    songs = json.loads(SONGS_JSON.read_text(encoding="utf-8"))

    fixed = 0
    re_id = 0
    seq = 0
    for song in songs:
        if song.get("category") != CATEGORY:
            continue
        seq += 1
        new_id = f"{ID_PREFIX}{seq:02d}"
        if song.get("id") != new_id:
            song["id"] = new_id
            re_id += 1

        manual = MANUAL_TITLES.get(new_id)
        if manual:
            new_title = manual
        else:
            new_title = extract_title(
                song.get("lyrics") or "",
                song.get("chords") or "",
                song.get("title") or "Untitled",
            )
        if song.get("title") != new_title:
            song["title"] = new_title
            fixed += 1

        if song.get("pageNumber") != seq:
            song["pageNumber"] = seq

    ids = [s.get("id") for s in songs if s.get("id")]
    dupes = {i for i in ids if ids.count(i) > 1}
    if dupes:
        raise SystemExit(f"Duplicate ids remain: {sorted(dupes)[:10]}")

    SONGS_JSON.write_text(
        json.dumps(songs, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    booklet = [s for s in songs if s.get("category") == CATEGORY]
    with_chords = [
        s
        for s in songs
        if (s.get("chords") or "").strip() or (s.get("chordProText") or "").strip()
    ]
    print(f"Booklet songs: {len(booklet)}")
    print(f"Titles updated: {fixed}")
    print(f"Ids reassigned: {re_id}")
    print(f"Total songs with chord data: {len(with_chords)}")
    print("\nBooklet titles:")
    for i, s in enumerate(booklet, 1):
        print(f"  {i:2}. {s['title']}")


if __name__ == "__main__":
    main()
