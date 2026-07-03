import '../models/song.dart';
import '../utils/chord_pro_helper.dart';
import '../utils/lyrics_display_helper.dart';

/// Turns OCR / PDF text into [Song] fields with lyrics and chart text separated.
class SongImportParser {
  SongImportParser._();

  static final RegExp _telugu = RegExp(r'[\u0C00-\u0C7F]');
  static final RegExp _sectionLine = RegExp(
    r'^\[?(Chorus|Verse|Pallavi|Intro|Bridge)\s*\d*\]?$',
    caseSensitive: false,
  );
  static final RegExp _chordToken = RegExp(
    r'^(?:N\.?C\.?|'
    r'[A-Ga-g][#b]?(?:m|maj|min|sus|add|dim|aug)?(?:[0-9]+)?'
    r'(?:/[A-Ga-g][#b]?)?)$',
  );

  static String inferTitleFromText(String text) => _inferTitle(text);

  /// Build a song from raw extracted text (OCR or PDF page).
  static Song fromExtractedText({
    required String rawText,
    required String id,
    String? title,
    int? pageNumber,
    String category = 'Worship',
  }) {
    final cleaned = rawText.trim();
    if (cleaned.isEmpty) {
      return Song(
        id: id,
        title: title ?? 'Untitled',
        pageNumber: pageNumber,
        category: category,
      );
    }

    final inferredTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : _inferTitle(cleaned);

    final lyricLines = <String>[];
    for (final line in cleaned.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (_sectionLine.hasMatch(trimmed)) continue;
      if (_isChordOnlyLine(trimmed)) continue;
      if (_telugu.hasMatch(trimmed)) {
        lyricLines.add(trimmed);
      }
    }

    final lyrics = lyricLines.join('\n').trim();
    final chordPro = ChordProHelper.normalizeFromLegacy(
      chords: cleaned,
      lyrics: lyrics.isNotEmpty ? lyrics : null,
      title: inferredTitle,
    );

    return Song(
      id: id,
      title: inferredTitle,
      lyrics: lyrics.isNotEmpty
          ? lyrics
          : (chordPro.isNotEmpty
              ? ChordProHelper.stripChords(chordPro)
              : cleaned),
      chords: chordPro.isNotEmpty ? chordPro : null,
      chordProText: chordPro.isNotEmpty ? chordPro : null,
      pageNumber: pageNumber,
      category: category,
    );
  }

  /// Normalize an edited/imported song before local + cloud save.
  /// Preserves musician spacing in [Song.chordProText] when already set.
  static Song normalizeForSave(Song song, {int fallbackIndex = 0}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = song.id.isNotEmpty ? song.id : 'song_${now}_$fallbackIndex';
    final title =
        song.title.trim().isEmpty ? 'Untitled' : song.title.trim();

    final editedChart = song.chordProText?.trim();
    final legacyChords = song.chords?.trim();
    final chart = editedChart?.isNotEmpty == true
        ? editedChart!
        : legacyChords?.isNotEmpty == true
            ? legacyChords!
            : ChordProHelper.normalizeFromLegacy(
                chords: legacyChords,
                lyrics: song.lyrics,
                title: title,
              );

    final lyrics = song.lyrics?.trim();
    final cleanLyrics = lyrics?.isNotEmpty == true
        ? lyrics!
        : (chart.isNotEmpty ? ChordProHelper.stripChords(chart) : '');

    return Song(
      id: id,
      title: title,
      lyrics: cleanLyrics.isNotEmpty ? cleanLyrics : null,
      lyricsEnglish: song.lyricsEnglish?.trim().isNotEmpty == true
          ? song.lyricsEnglish!.trim()
          : null,
      chords: chart.isNotEmpty ? chart : null,
      chordProText: chart.isNotEmpty ? chart : null,
      pageNumber: song.pageNumber ?? fallbackIndex + 1,
      category: song.category ?? 'Worship',
      createdAt: song.createdAt,
    );
  }

  static String _inferTitle(String text) {
    for (final line in text.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (_isChordOnlyLine(trimmed)) continue;
      if (LyricsDisplayHelper.looksLikeChordSheet(trimmed) &&
          !_telugu.hasMatch(trimmed)) {
        continue;
      }
      if (_telugu.hasMatch(trimmed) && trimmed.length <= 80) {
        return trimmed.length > 60 ? '${trimmed.substring(0, 60)}...' : trimmed;
      }
    }
    return 'Untitled';
  }

  static bool _isChordOnlyLine(String line) {
    if (_telugu.hasMatch(line)) return false;
    final tokens =
        line.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return false;
    var chordCount = 0;
    for (final token in tokens) {
      if (_chordToken.hasMatch(token.replaceAll(RegExp(r'[|/\\.]'), ''))) {
        chordCount++;
      }
    }
    return chordCount > 0 && chordCount >= (tokens.length / 2).ceil();
  }
}
