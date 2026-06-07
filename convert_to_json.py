import json
import re
import sys

# Ensure UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

def parse_songs_from_txt():
    with open('all_songs.txt', 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    songs = []
    song_num = 0
    current_song = None
    collecting_lyrics = None
    telugu_lines = []
    english_lines = []
    song_count = 0
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Check for song title
        title_match = re.match(r'SONG #(\d+):\s*(.+)', stripped)
        if title_match:
            song_count += 1
            # Save previous song if exists
            if current_song and telugu_lines:
                lyrics = '\n'.join(telugu_lines).strip()
                english = '\n'.join(english_lines).strip()
                if len(lyrics) > 30:
                    song_num += 1
                    current_song['id'] = f"song_{song_num}"
                    current_song['lyrics'] = lyrics
                    if english:
                        current_song['lyricsEnglish'] = english
                    songs.append(current_song)
                    # print(f"[+] Song {current_song['pageNumber']}: {current_song['title']} ({len(lyrics)} chars)")
                # else:
                    # print(f"[-] Skipped song {current_song['pageNumber']}: {current_song['title']} (lyrics: {len(lyrics)} chars)")
            
            # Start new song
            song_number = int(title_match.group(1))
            title = title_match.group(2).strip()
            current_song = {
                "title": title,
                "pageNumber": song_number,
                "category": "Worship"
            }
            telugu_lines = []
            english_lines = []
            collecting_lyrics = None
            if song_count <= 15 or song_count % 100 == 0:
                print(f"Found song #{song_number}: {title}")
            continue
        
        # Check for Audio marker OR Telugu Lyrics marker
        if stripped == 'Telugu Lyrics':
            collecting_lyrics = 'telugu'
            continue
        if stripped == 'English Lyrics':
            collecting_lyrics = 'english'
            continue
        if stripped == 'Audio':
            collecting_lyrics = None
            continue
        
        # Collect lyrics if we're in collecting mode
        if collecting_lyrics and current_song and stripped:
            if collecting_lyrics == 'telugu':
                has_telugu = bool(re.search(r'[\u0C00-\u0C7F]', stripped))
                if has_telugu:
                    telugu_lines.append(stripped)
                elif len(stripped) < 10 and not stripped[0].isupper():
                    telugu_lines.append(stripped)
            elif collecting_lyrics == 'english':
                english_lines.append(stripped)
    
    # Don't forget the last song
    if current_song and telugu_lines:
        lyrics = '\n'.join(telugu_lines).strip()
        english = '\n'.join(english_lines).strip()
        if len(lyrics) > 30:
            song_num += 1
            current_song['id'] = f"song_{song_num}"
            current_song['lyrics'] = lyrics
            if english:
                current_song['lyricsEnglish'] = english
            songs.append(current_song)
            print(f"[+] Song {current_song['pageNumber']}: {current_song['title']} ({len(lyrics)} chars)")
        else:
            print(f"[-] Skipped song {current_song['pageNumber']}: {current_song['title']} (lyrics: {len(lyrics)} chars)")
    
    return songs

if __name__ == '__main__':
    print("Starting conversion...")
    print("=" * 80)
    songs = parse_songs_from_txt()
    print("=" * 80)
    print(f"\nTotal song titles found in file: (check output above)")
    print(f"Total songs with valid lyrics (>30 chars): {len(songs)}")
    
    # Write to JSON file
    with open('assets/songs.json', 'w', encoding='utf-8') as f:
        json.dump(songs, f, ensure_ascii=False, indent=2)
    
    print(f"Successfully written {len(songs)} songs to assets/songs.json")
