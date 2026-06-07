import json

with open('assets/songs.json', encoding='utf-8') as f:
    data = json.load(f)

print(f'Total songs in JSON: {len(data)}')
print(f'First song: {data[0]["title"]}')
print(f'Last song: {data[-1]["title"]}')
print(f'Sample song (#100): {data[99]["title"] if len(data) > 99 else "N/A"}')
