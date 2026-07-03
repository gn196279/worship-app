import '../models/song.dart';

/// Result of PDF/image import before preview.
class ImportParseResult {
  final List<Song> songs;
  final String? errorMessage;

  const ImportParseResult({
    required this.songs,
    this.errorMessage,
  });

  bool get hasSongs => songs.isNotEmpty;
}
