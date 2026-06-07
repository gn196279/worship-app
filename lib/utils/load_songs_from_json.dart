import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';
import '../services/song_storage_service.dart';
import 'json_parser_helper.dart';

/// Loads all songs from the bundled assets/songs.json into Hive and the
/// local JSON cache.
///
/// Uses [JsonParserHelper.parseSongsFromJson] (background isolate) for
/// parsing, then a single [Box.putAll] call instead of 700 individual
/// [Box.put] awaits — the original loop caused Android ANR dialogs.
Future<void> loadSongsFromJson() async {
  try {
    debugPrint('Loading songs from assets/songs.json…');

    final String jsonString = await rootBundle.loadString('assets/songs.json');

    // Parse in a background isolate — avoids blocking the main thread.
    final List<Song> songs = await JsonParserHelper.parseSongsFromJson(jsonString);

    debugPrint('Parsed ${songs.length} songs');

    final box = Hive.box<Song>('songs');
    await box.clear();

    // Single bulk write — vastly faster than 700 individual await box.put() calls.
    await box.putAll({for (final song in songs) song.id: song});

    // Also update the local JSON cache.
    await SongStorageService().saveLocalSongs(songs);

    debugPrint('Successfully saved ${songs.length} songs to Hive and local cache.');
  } catch (e) {
    debugPrint('Error loading songs from JSON: $e');
    rethrow;
  }
}
