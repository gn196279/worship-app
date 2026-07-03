/// Cleans PDF/OCR chord-sheet text for the Telugu lyrics tab.
class LyricsDisplayHelper {
  LyricsDisplayHelper._();

  static final RegExp _telugu = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _ocrMarker = RegExp(
    r'[lL]Gh|/tl|tl(?=[A-Z\u0C00-\u0C7F])|/[భత]{1,3}|ఘl',
  );
  static final RegExp _sectionMarker = RegExp(
    r'\[?(Chorus|Verse|Pallavi|Intro|Bridge)\s*\d*\]?',
    caseSensitive: false,
  );
  static final RegExp _chordToken = RegExp(
    r'\b(?:N\.?C\.?|'
    r'[A-Ga-g][#b]?(?:m|maj|min|sus|add|dim|aug)?(?:[0-9]+)?'
    r'(?:/[A-Ga-g][#b]?)?)\b',
  );
  static final RegExp _offeringHeader = RegExp(
    r'^(?:Offering Song|Oﬀering Song|Blessing Song)[^\n]*\n?',
    caseSensitive: false,
    multiLine: true,
  );

  /// True when [text] looks like a musician chord sheet, not plain lyrics.
  static bool looksLikeChordSheet(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    if (_ocrMarker.hasMatch(text)) return true;
    if (RegExp(r'\[Chorus\]|\[Verse\s*\d*\]', caseSensitive: false)
        .hasMatch(text)) {
      return true;
    }
    final chordHits = _chordToken.allMatches(text).length;
    if (chordHits >= 6 && text.length < 12000) return true;
    return false;
  }

  /// Best-effort Telugu lyrics for the lyrics tab (no chords).
  static String cleanForTeluguTab(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    var text = raw.replaceAll('||', '\n||');
    text = text.replaceAllMapped(
      _sectionMarker,
      (m) => '\n${m.group(0)!.replaceAll('[', '').replaceAll(']', '')}\n',
    );
    text = text.replaceAll(_offeringHeader, '');

    final lines = <String>[];
    for (final part in text.split('\n')) {
      final line = part.trim();
      if (line.isEmpty) continue;

      if (_sectionMarker.hasMatch(line) ||
          RegExp(r'^(Chorus|Verse|Pallavi|Intro|Bridge)\s*\d*$',
                  caseSensitive: false)
              .hasMatch(line)) {
        lines.add(line.replaceAll(RegExp(r'[\[\]]'), '').trim());
        continue;
      }

      var cleaned = line;
      cleaned = cleaned.replaceAll(_ocrMarker, '');
      cleaned = cleaned.replaceAll(_chordToken, ' ');
      cleaned = cleaned.replaceAll(RegExp(r'[A-Za-z0-9#./\\|]+'), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'\(\d+\)|X\d+'), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ').trim();

      final teluguChunks =
          RegExp(r'[\u0C00-\u0C7F][\u0C00-\u0C7F\s\|\-\(\)…\.·]*')
              .allMatches(cleaned)
              .map((m) => m.group(0)!.trim())
              .where((chunk) => chunk.length >= 4)
              .toList();

      if (teluguChunks.isEmpty) continue;
      final merged = teluguChunks.join(' ').replaceAll(RegExp(r' +'), ' ');
      if (_teluguCharCount(merged) >= 4) {
        lines.add(merged);
      }
    }

    if (lines.isEmpty) return '';

    final deduped = <String>[];
    for (final line in lines) {
      if (deduped.isEmpty || deduped.last != line) {
        deduped.add(line);
      }
    }
    return deduped.join('\n');
  }

  static int _teluguCharCount(String text) =>
      _telugu.allMatches(text).length;

  /// Message when booklet OCR lyrics cannot be recovered cleanly.
  static const String bookletLyricsFallback =
      'Clean Telugu lyrics are not available for this imported chord sheet yet.\n\n'
      'Musicians and admins: open the Chart tab for chords.\n'
      'You can also edit this song to paste proper lyrics from the PDF.';
}
