import '../models/song.dart';
import 'lyrics_display_helper.dart';

/// Converts legacy chord/lyric fields to ChordPro text and resolves the best
/// chart source for display.
class ChordProHelper {
  ChordProHelper._();

  static final RegExp _inlineChord = RegExp(r'\[[^\]]+\]');
  static final RegExp _sectionBracket = RegExp(
    r'^\[(Verse|Chorus|Bridge|Pre-Chorus|Outro|Intro)([^\]]*)\]',
    caseSensitive: false,
  );
  static final RegExp _sectionInline = RegExp(
    r'\[(Chorus|Verse|Pallavi|Intro|Bridge)[^\]]*\]',
    caseSensitive: false,
  );
  static final RegExp _ocrMarker = RegExp(
    r'[lL]Gh|/tl|tl(?=[A-Z\u0C00-\u0C7F])|/[భత]{1,3}|ఘl',
  );
  static final RegExp _chordToken = RegExp(
    r'^(?:N\.?C\.?|'
    r'[A-Ga-g][#b]?(?:m|maj|min|sus|add|dim|aug)?(?:[0-9]+)?'
    r'(?:/[A-Ga-g][#b]?)?)$',
  );
  static final RegExp _inlineChordToken = RegExp(
    r'\b(?:N\.?C\.?|'
    r'[A-Ga-g][#b]?(?:m|maj|min|sus|add|dim|aug)?(?:[0-9]+)?'
    r'(?:/[A-Ga-g][#b]?)?)\b',
  );

  /// Preferred chart text for rendering (ChordPro / inline bracket format).
  static String resolve(Song song) {
    final stored = song.chordProText?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return normalizeFromLegacy(
      chords: song.chords,
      lyrics: song.lyrics,
      title: song.displayTitle,
    );
  }

  /// Builds ChordPro from legacy [chords] / [lyrics] columns.
  static String normalizeFromLegacy({
    String? chords,
    String? lyrics,
    String? title,
  }) {
    final rawChords = chords?.trim() ?? '';
    final rawLyrics = lyrics?.trim() ?? '';

    if (rawChords.isEmpty && rawLyrics.isEmpty) return '';

    if (rawChords.isNotEmpty && _hasInlineChordMarkers(rawChords)) {
      return _withTitle(rawChords, title);
    }

    if (rawChords.isNotEmpty) {
      final expanded = _needsDenseExpansion(rawChords)
          ? _expandDenseBookletSheet(rawChords)
          : rawChords;
      return _withTitle(_convertLineBasedSheet(expanded), title);
    }

    return _withTitle(rawLyrics, title);
  }

  static String _withTitle(String body, String? title) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return '';
    if (title == null || title.trim().isEmpty) return trimmed;
    if (trimmed.contains('{title:')) return trimmed;
    return '{title: ${_escapeMeta(title.trim())}}\n$trimmed';
  }

  static String _escapeMeta(String value) => value.replaceAll('}', '\\}');

  static bool _hasInlineChordMarkers(String raw) {
    for (final match in _inlineChord.allMatches(raw)) {
      final inner = match.group(0)!.replaceAll(RegExp(r'[\[\]]'), '');
      if (_sectionInline.hasMatch('[${inner}]')) continue;
      if (_isChordToken(inner.replaceAll(RegExp(r'[|/\\.]'), ''))) {
        return true;
      }
    }
    return false;
  }

  static bool _needsDenseExpansion(String raw) {
    final lineCount = raw.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).length;
    return lineCount <= 3 ||
        LyricsDisplayHelper.looksLikeChordSheet(raw) ||
        _ocrMarker.hasMatch(raw);
  }

  /// Breaks single-line PDF imports into chord + lyric lines for the Chart tab.
  static String _expandDenseBookletSheet(String raw) {
    var text = raw.replaceAll(_ocrMarker, '');
    text = text.replaceAll('||', '\n||\n');
    text = text.replaceAllMapped(_sectionInline, (m) => '\n${m.group(0)!}\n');
    text = text.replaceAllMapped(
      RegExp(r'\(\d+\)|X\d+'),
      (m) => '\n${m.group(0)!}\n',
    );

    // Chord cluster before Telugu lyric chunk → separate lines.
    text = text.replaceAllMapped(
      RegExp(
        r'((?:[A-Ga-g][#b]?(?:m|maj|min|sus|add|dim|aug)?(?:[0-9]+)?'
        r'(?:/[A-Ga-g][#b]?)?\s*){2,})([\u0C00-\u0C7F])',
      ),
      (m) => '${m.group(1)!.trim()}\n${m.group(2)}',
    );

    // Chord cluster before a section marker.
    text = text.replaceAllMapped(
      RegExp(r'((?:[A-Ga-g][#b]?m?\s*)+)\[(Chorus|Verse)', caseSensitive: false),
      (m) => '${m.group(1)!.trim()}\n[${m.group(2)}',
    );

    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  static String _convertLineBasedSheet(String raw) {
    var prepared = raw.replaceAllMapped(
      _sectionInline,
      (m) => '\n${m.group(0)!}\n',
    );
    final lines = prepared.split(RegExp(r'\r?\n'));
    final out = <String>[];
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      final section = _sectionBracket.firstMatch(trimmed);
      if (section != null) {
        final type = section.group(1)!.toLowerCase().replaceAll('-', '_');
        final label = section.group(2)?.trim();
        final name = label != null && label.isNotEmpty ? label : type;
        out.add('{start_of_$type: $name}');
        i++;
        continue;
      }

      if (i + 1 < lines.length && _isChordOnlyLine(trimmed)) {
        final next = lines[i + 1].trim();
        if (next.isNotEmpty && !_isChordOnlyLine(next)) {
          out.add(_mergeChordLineWithLyric(trimmed, next));
          i += 2;
          continue;
        }
      }

      if (_isMixedChordLyricLine(trimmed)) {
        out.add(_splitMixedLine(trimmed));
        i++;
        continue;
      }

      if (_inlineChord.hasMatch(trimmed)) {
        out.add(trimmed);
      } else if (_isChordOnlyLine(trimmed)) {
        out.add('{comment: $trimmed}');
      } else {
        out.add(trimmed);
      }
      i++;
    }

    return out.join('\n');
  }

  static bool _isMixedChordLyricLine(String line) {
    if (!_inlineChordToken.hasMatch(line)) return false;
    return RegExp(r'[\u0C00-\u0C7F]').hasMatch(line);
  }

  static String _splitMixedLine(String line) {
    final tokens = line.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final chords = <String>[];
    final lyrics = <String>[];

    for (final token in tokens) {
      if (_isChordToken(token.replaceAll(RegExp(r'[|/\\.]'), ''))) {
        chords.add(token.replaceAll(RegExp(r'[|/\\.]'), ''));
      } else if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(token) ||
          !RegExp(r'^[A-Ga-g]').hasMatch(token)) {
        lyrics.add(token);
      }
    }

    if (chords.isEmpty || lyrics.isEmpty) return line.trim();
    return _mergeChordLineWithLyric(chords.join(' '), lyrics.join(' '));
  }

  static bool _isChordOnlyLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    if (_inlineChord.hasMatch(trimmed)) return false;
    if (_sectionBracket.hasMatch(trimmed)) return false;
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(trimmed)) return false;

    final tokens =
        trimmed.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return false;

    var chordCount = 0;
    for (final token in tokens) {
      if (_isChordToken(token)) chordCount++;
    }
    return chordCount > 0 && chordCount >= (tokens.length / 2).ceil();
  }

  static bool _isChordToken(String token) {
    final cleaned = token.replaceAll(RegExp(r'[|/\\.]'), '');
    if (cleaned.isEmpty) return false;
    return _chordToken.hasMatch(cleaned);
  }

  static String _mergeChordLineWithLyric(String chordLine, String lyricLine) {
    final chords = chordLine
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && _isChordToken(t))
        .toList();
    if (chords.isEmpty) return lyricLine.trim();

    final words =
        lyricLine.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final wordList = words.toList();
    if (wordList.isEmpty) return lyricLine.trim();

    final buffer = StringBuffer();
    for (var i = 0; i < wordList.length; i++) {
      if (i < chords.length) {
        buffer.write('[${chords[i]}]');
      }
      buffer.write(wordList[i]);
      if (i < wordList.length - 1) buffer.write(' ');
    }
    for (var i = wordList.length; i < chords.length; i++) {
      buffer.write(' [${chords[i]}]');
    }
    return buffer.toString();
  }

  /// Strips bracket chords to plain lyrics (for syncing the lyrics field).
  static String stripChords(String chordProText) {
    return chordProText
        .replaceAll(_inlineChord, '')
        .replaceAll(RegExp(r'\{[^}]+\}'), '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static const List<String> commonChords = [
    'C',
    'D',
    'E',
    'F',
    'G',
    'A',
    'Am',
    'Bm',
    'Dm',
    'Em',
    'F#m',
    'G7',
    'C/E',
    'D/F#',
  ];

  static const List<String> sectionSnippets = [
    '{start_of_verse: Verse 1}',
    '{start_of_chorus: Chorus}',
    '{start_of_bridge: Bridge}',
    '{end_of_chorus}',
  ];
}
