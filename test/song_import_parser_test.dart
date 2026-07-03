import 'package:flutter_test/flutter_test.dart';
import 'package:gilgal_telugu_worship/models/song.dart';
import 'package:gilgal_telugu_worship/services/song_import_parser.dart';

void main() {
  test('normalizeForSave preserves edited ChordPro spacing', () {
    const chart = '{start_of_verse: Verse 1}\n'
        '[G]Hello   [C]world';
    final song = Song(
      id: 'test_1',
      title: 'Test Song',
      lyrics: 'Hello world',
      chordProText: chart,
      chords: chart,
    );

    final saved = SongImportParser.normalizeForSave(song);
    expect(saved.chordProText, chart);
    expect(saved.chords, chart);
    expect(saved.lyrics, 'Hello world');
  });
}
