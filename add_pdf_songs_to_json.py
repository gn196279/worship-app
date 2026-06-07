import PyPDF2
import json
import re
import os

PDF_PATH = 'hosannaaanandakeerthanlau-21.pdf'
JSON_PATH = 'assets/songs.json'
CATEGORY = 'Hosanna Hymn'

# 1. Extract text from PDF
def extract_pdf_text(pdf_path):
    text = ''
    with open(pdf_path, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text + '\n'
    return text

# 2. Parse songs from extracted text (simple heuristic: split by numbers or titles)
def parse_songs_from_text(text):
    # This regex splits on lines that look like a song number (e.g., 1. or 12.)
    song_blocks = re.split(r'\n\s*(\d{1,3})[\.|\)]\s+', text)
    songs = []
    for i in range(1, len(song_blocks), 2):
        number = song_blocks[i]
        content = song_blocks[i+1].strip()
        # Try to extract title (first line) and lyrics (rest)
        lines = content.split('\n')
        title = lines[0].strip() if lines else f'Hosanna Song {number}'
        lyrics = '\n'.join(lines[1:]).strip() if len(lines) > 1 else ''
        if len(lyrics) > 20:
            songs.append({
                'title': title,
                'pageNumber': int(number),
                'category': CATEGORY,
                'lyrics': lyrics
            })
    return songs

# 3. Append new songs to existing JSON
def append_songs_to_json(new_songs, json_path):
    if os.path.exists(json_path):
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    else:
        data = []
    # Assign unique IDs
    max_id = 0
    for song in data:
        if 'id' in song and str(song['id']).startswith('song_'):
            try:
                max_id = max(max_id, int(str(song['id']).replace('song_', '')))
            except:
                pass
    for i, song in enumerate(new_songs, 1):
        song['id'] = f'song_{max_id + i}'
        data.append(song)
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f'Appended {len(new_songs)} songs to {json_path}')

if __name__ == '__main__':
    text = extract_pdf_text(PDF_PATH)
    new_songs = parse_songs_from_text(text)
    append_songs_to_json(new_songs, JSON_PATH)
    print('Done.')
