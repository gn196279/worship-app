import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';

/// Parse and load all songs from all_songs.txt asset file
Future<void> loadAllSongsFromFile() async {
  try {
    debugPrint('Loading songs from assets...');
    final content = await rootBundle.loadString('all_songs.txt');
    final songs = _parseAllSongs(content);
    
    debugPrint('Parsed ${songs.length} songs from file');
    
    // Save to Hive
    final box = Hive.box<Song>('songs');
    await box.clear();
    
    for (var song in songs) {
      await box.put(song.id, song);
    }
    
    debugPrint('Successfully loaded ${songs.length} songs into database');
  } catch (e) {
    debugPrint('Error loading songs from file: $e');
  }
}

List<Song> _parseAllSongs(String content) {
  List<Song> songs = [];
  
  debugPrint('Content length: ${content.length} characters');
  
  // Split by song separator
  final songBlocks = content.split(RegExp(r'#{80,}'));
  
  debugPrint('Found ${songBlocks.length} blocks');
  
  int songNumber = 1;
  
  for (var block in songBlocks) {
    final trimmedBlock = block.trim();
    if (trimmedBlock.isEmpty || !trimmedBlock.contains('SONG #')) continue;
    
    try {
      // Extract title
      final titleMatch = RegExp(r'SONG\s+#\d+:\s*(.+)', multiLine: true).firstMatch(trimmedBlock);
      if (titleMatch == null) continue;
      
      final title = titleMatch.group(1)?.trim() ?? 'Untitled';
      
      // Extract lyricist
      String lyricist = '';
      final lyricistMatch = RegExp(r'Lyricist:\s*(.+)', multiLine: true).firstMatch(trimmedBlock);
      if (lyricistMatch != null) {
        final temp = lyricistMatch.group(1)?.trim() ?? '';
        if (temp.isNotEmpty && !temp.contains('Date:') && !temp.contains('URL:')) {
          lyricist = temp;
        }
      }
      
      // Extract Telugu lyrics - everything after "Audio" until English transliteration starts
      String lyrics = '';
      
      final audioIndex = trimmedBlock.indexOf('Audio');
      if (audioIndex != -1) {
        String afterAudio = trimmedBlock.substring(audioIndex + 5);
        
        // Find where English transliteration starts (usually starts with capital letter Latin text)
        // Or where Download/Share markers appear
        final lines = afterAudio.split('\n');
        List<String> lyricLines = [];
        
        bool foundTeluguStart = false;
        
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          
          // Skip markers
          if (trimmed.contains('Download') || trimmed.contains('Share') || 
              trimmed.contains('WhatsApp') || trimmed.contains('Tweet') ||
              trimmed.contains('PPT') || trimmed.contains('Click to')) {
            break;
          }
          
          // Check if this is Telugu text (has Telugu Unicode characters)
          final hasTeluguChars = RegExp(r'[\u0C00-\u0C7F]').hasMatch(trimmed);
          
          if (hasTeluguChars) {
            foundTeluguStart = true;
            lyricLines.add(trimmed);
          } else if (foundTeluguStart && trimmed.length > 5) {
            // Once we found Telugu and now hit non-Telugu text (English transliteration), stop
            break;
          }
        }
        
        lyrics = lyricLines.join('\n');
      }
      
      // Accept songs with at least some content
      if (lyrics.isEmpty || lyrics.length < 15) {
        continue;
      }
      
      songs.add(Song(
        id: 'song_$songNumber',
        title: title,
        lyrics: lyrics,
        pageNumber: songNumber,
        category: lyricist.isNotEmpty ? 'Lyricist: $lyricist' : 'Worship',
        createdAt: DateTime.now(),
      ));
      
      if (songNumber <= 5) {
        debugPrint('Song $songNumber: $title (${lyrics.length} chars)');
      }
      
      songNumber++;
    } catch (e) {
      debugPrint('Error parsing song: $e');
    }
  }
  
  debugPrint('Successfully parsed ${songs.length} songs');
  return songs;
}
