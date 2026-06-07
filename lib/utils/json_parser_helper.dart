import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/song.dart';

/// Parse JSON songs in background isolate to avoid blocking UI
class JsonParserHelper {
  static Future<List<Song>> parseSongsFromJson(String jsonString) async {
    return compute(_parseSongs, jsonString);
  }

  static List<Song> _parseSongs(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    final Set<String> seenIds = {};
    int pdfCounter = 0;
    final List<Song> loadedSongs = [];

    for (int i = 0; i < jsonList.length; i++) {
      final e = jsonList[i] as Map<String, dynamic>;

      // Skip songs from the Gilgal 2025-2026 PDF booklet (hidden for now).
      final category = e['category']?.toString();
      if (category == 'Gilgal Worship 2025-2026') continue;
      final rawTitle = e['title']?.toString();

      String id = e['id']?.toString() ?? 'song_$i';
      if (seenIds.contains(id)) id = 'song_pdf_${++pdfCounter}';
      seenIds.add(id);
      final safeTitle = rawTitle ?? 'Untitled';
      final title =
          Song.deriveTitleFromLyrics(safeTitle, e['lyrics']?.toString());
      final song = Song(
        id: id,
        title: title,
        lyrics: e['lyrics'] as String?,
        lyricsEnglish: e['lyricsEnglish'] as String?,
        pageNumber: e['pageNumber'] as int?,
        category: e['category'] as String?,
        chords: e['chords'] as String?,
        createdAt: e['createdAt'] != null
            ? DateTime.tryParse(e['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
      loadedSongs.add(song);
    }

    // Sort once at the end
    loadedSongs.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
    return loadedSongs;
  }
}
