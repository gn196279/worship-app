import 'package:hive/hive.dart';

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

  Song({
    required this.id,
    required this.title,
    this.lyrics,
    this.lyricsEnglish,
    this.pageNumber,
    this.category,
    this.chords,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'lyrics': lyrics,
        'lyricsEnglish': lyricsEnglish,
        'pageNumber': pageNumber,
        'category': category,
        'chords': chords,
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
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  /// For UI: use first line of lyrics when title is the generic PDF section header.
  String get displayTitle {
    if (title != 'Vandanam - Capo 2') return title;
    final lines = (lyrics ?? '').split(RegExp(r'\r?\n'));
    final trimmed =
        lines.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (trimmed.isEmpty) return title;
    final first = trimmed.first;
    return first.length > 50 ? '${first.substring(0, 50)}...' : first;
  }

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
