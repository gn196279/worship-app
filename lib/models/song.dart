import 'package:hive/hive.dart';

import '../utils/chord_pro_helper.dart';
import '../utils/lyrics_display_helper.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? lyrics;

  @HiveField(7)
  String? lyricsEnglish;

  @HiveField(3)
  int? pageNumber;

  @HiveField(4)
  String? category;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? chords;

  /// ChordPro source text — inline [G] chords aligned above lyrics when rendered.
  @HiveField(8)
  String? chordProText;

  Song({
    required this.id,
    required this.title,
    this.lyrics,
    this.lyricsEnglish,
    this.pageNumber,
    this.category,
    this.chords,
    this.chordProText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Best chart text for rendering (stored ChordPro or legacy migration).
  String get effectiveChordProText {
    final stored = chordProText?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    final legacy = chords?.trim();
    if (legacy != null && legacy.isNotEmpty) {
      return ChordProHelper.normalizeFromLegacy(
        chords: chords,
        lyrics: lyrics,
        title: displayTitle,
      );
    }
    return lyrics?.trim() ?? '';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'lyrics': lyrics,
        'lyricsEnglish': lyricsEnglish,
        'pageNumber': pageNumber,
        'category': category,
        'chords': chords,
        'chordProText': chordProText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] as String,
        title: json['title'] as String,
        lyrics: json['lyrics'] as String?,
        lyricsEnglish: json['lyricsEnglish'] as String?,
        pageNumber: json['pageNumber'] as int?,
        category: json['category'] as String?,
        chords: json['chords'] as String?,
        chordProText: json['chordProText'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  /// True when legacy chords or ChordPro text is present.
  bool get hasChordData {
    final pro = chordProText?.trim();
    if (pro != null && pro.isNotEmpty) return true;
    final legacy = chords?.trim();
    return legacy != null && legacy.isNotEmpty;
  }

  /// For UI: prefer stored title (booklet titles are fixed in JSON).
  String get displayTitle => title;

  /// Plain Telugu lyrics for the lyrics tab — never raw chord-sheet OCR text.
  String get displayLyrics {
    final raw = lyrics?.trim();
    if (raw == null || raw.isEmpty) return '';

    final chordField = chords?.trim();
    final isDuplicatedChordSheet = chordField != null &&
        chordField.isNotEmpty &&
        raw == chordField;

    if (!isDuplicatedChordSheet &&
        !LyricsDisplayHelper.looksLikeChordSheet(raw)) {
      return raw;
    }

    final cleaned = LyricsDisplayHelper.cleanForTeluguTab(raw);
    if (cleaned.length >= 24) return cleaned;
    return LyricsDisplayHelper.bookletLyricsFallback;
  }

  /// True when lyrics tab should warn that Chart tab has the musician view.
  bool get usesBookletLyricsFallback =>
      hasChordData &&
      displayLyrics == LyricsDisplayHelper.bookletLyricsFallback;

  /// Derive a display title from lyrics when the stored title is the generic PDF header.
  static String deriveTitleFromLyrics(String? rawTitle, String? lyrics) {
    if (rawTitle != null && rawTitle != 'Vandanam - Capo 2') return rawTitle;
    final lines = (lyrics ?? '').split(RegExp(r'\r?\n'));
    final trimmed =
        lines.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (trimmed.isEmpty) return rawTitle ?? 'Untitled';
    final first = trimmed.first;
    return first.length > 50 ? '${first.substring(0, 50)}...' : first;
  }
}
