import 'package:flutter_test/flutter_test.dart';
import 'package:gilgal_telugu_worship/utils/chord_pro_helper.dart';
import 'package:gilgal_telugu_worship/utils/lyrics_display_helper.dart';

void main() {
  test('detects OCR chord sheet text', () {
    const raw = 'ఆధtlRAAధన [Chorus] C#m B F#m';
    expect(LyricsDisplayHelper.looksLikeChordSheet(raw), isTrue);
    expect(LyricsDisplayHelper.looksLikeChordSheet('మేలు చేయక'), isFalse);
  });

  test('cleanForTeluguTab removes chords and OCR markers', () {
    const raw =
        'Offering Song - Test - E B C\n[Chorus] C#m B F#m ఆలlGhRAAధనlGhKU (2)';
    final cleaned = LyricsDisplayHelper.cleanForTeluguTab(raw);
    expect(cleaned, isNot(contains('C#m')));
    expect(cleaned, isNot(contains('lGh')));
    expect(cleaned, contains('Chorus'));
  });

  test('normalizeFromLegacy expands dense booklet lines', () {
    const raw =
        'D G Bm [Chorus] D G Bm ఆరాధన చేయని D A G నీకే ఆరాధన';
    final out = ChordProHelper.normalizeFromLegacy(chords: raw, title: 'Test');
    expect(out, contains('{start_of_chorus'));
    expect(out, contains('\n'));
  });
}
