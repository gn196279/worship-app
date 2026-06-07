import re
from pathlib import Path

def is_telugu(s: str) -> bool:
    return bool(re.search(r"[\u0C00-\u0C7F]", s))

lines = Path('all_songs.txt').read_text(encoding='utf-8').splitlines()

songs = []
current = None
song_header_re = re.compile(r"^SONG #\d+:")

for line in lines:
    if line.startswith('################################################################################'):
        continue
    if song_header_re.match(line):
        if current:
            songs.append(current)
        current = {'title': line.strip(), 'lines': []}
        continue
    if current is None:
        continue
    if is_telugu(line):
        if line.strip() in {'à°ªà°¾à°Ÿ à°°à°šà°¯à°¿à°¤:'}:
            continue
        current['lines'].append(line.strip())

if current:
    songs.append(current)

output_lines = []
for idx, song in enumerate(songs, 1):
    first_two = song['lines'][:2]
    output_lines.append(f"{idx}. {song['title']}")
    if first_two:
        output_lines.extend([f"   {l}" for l in first_two])
    else:
        output_lines.append("   (Telugu lines not found)")

Path('two_lines_per_song.txt').write_text("\n".join(output_lines), encoding='utf-8')
print(f"Wrote {len(output_lines)} lines for {len(songs)} songs.")
