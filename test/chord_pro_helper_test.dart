import 'package:flutter_test/flutter_test.dart';
import 'package:gilgal_telugu_worship/utils/chord_pro_helper.dart';

void main() {
  test('normalizes inline ChordPro chords', () {
    const raw = '[G]Hello [C]world';
    final out = ChordProHelper.normalizeFromLegacy(chords: raw, title: 'Test');
    expect(out, contains('[G]'));
    expect(out, contains('{title: Test}'));
  });

  test('merges chord line above lyric line', () {
    const chords = 'D    A\nNeevu Naa Thodu';
    final out = ChordProHelper.normalizeFromLegacy(chords: chords);
    expect(out, contains('[D]'));
    expect(out, contains('Neevu'));
  });

  test('stripChords removes bracket chords', () {
    const text = '[G]దేవా [C]నీ ఆవరణం';
    expect(ChordProHelper.stripChords(text), 'దేవా నీ ఆవరణం');
  });
}
