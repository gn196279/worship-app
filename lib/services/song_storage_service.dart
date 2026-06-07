import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song.dart';

class SongStorageService {
  static const String _localFileName = 'songs_local.json';

  Future<File> _getLocalSongsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_localFileName');
  }

  /// Loads songs from the local JSON file.
  ///
  /// [json.decode] on 700+ songs with full Telugu/English lyrics is CPU-heavy
  /// and blocks the main thread for several seconds on slower devices, which
  /// triggers Android ANR dialogs. We offload it to a background isolate.
  Future<List<Song>> loadLocalSongs() async {
    try {
      final file = await _getLocalSongsFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.isEmpty) return [];
      return await compute(_decodeAndParseSongs, raw);
    } catch (e) {
      debugPrint('Failed to load local songs: $e');
      return [];
    }
  }

  /// Top-level static function required by [compute] — runs in background isolate.
  static List<Song> _decodeAndParseSongs(String raw) {
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Song.fromJson)
        .toList();
  }

  /// Saves songs to the local JSON file.
  ///
  /// [json.encode] on 700 songs (each with full lyrics) blocks the main thread.
  /// The toJson() step (creating 700 small maps) is fast and stays on the main
  /// thread; only the expensive string serialisation runs in an isolate.
  Future<void> saveLocalSongs(List<Song> songs) async {
    try {
      final file = await _getLocalSongsFile();
      final payload = songs.map((s) => s.toJson()).toList();
      final encoded = await compute(_encodeToJson, payload);
      await file.writeAsString(encoded, flush: true);
    } catch (e) {
      debugPrint('Failed to save local songs: $e');
    }
  }

  /// Top-level static function required by [compute].
  static String _encodeToJson(List<Map<String, dynamic>> payload) {
    return json.encode(payload);
  }

  Future<void> deleteLocalSongsFile() async {
    try {
      final file = await _getLocalSongsFile();
      if (await file.exists()) {
        await file.delete();
        debugPrint('Local songs file deleted.');
      }
    } catch (e) {
      debugPrint('Failed to delete local songs file: $e');
    }
  }
}
