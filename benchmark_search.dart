#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:math';

// Simple Song model for benchmarking
class Song {
  final String id;
  final String title;
  final String? lyrics;
  final String? lyricsEnglish;

  Song({
    required this.id,
    required this.title,
    this.lyrics,
    this.lyricsEnglish,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      lyrics: json['lyrics'],
      lyricsEnglish: json['lyricsEnglish'],
    );
  }
}

// Simplified search service for benchmarking
class SimpleSearchService {
  List<Song> songs = [];

  void loadSongs(List<Song> songList) {
    songs = songList;
  }

  List<Song> searchOld(String query) {
    final normalizedQuery = query.toLowerCase();
    return songs.where((song) {
      return song.title.toLowerCase().contains(normalizedQuery) ||
          (song.lyrics?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (song.lyricsEnglish?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();
  }

  List<Song> searchOptimized(String query) {
    if (query.trim().isEmpty) return songs;
    
    final normalizedQuery = query.toLowerCase().trim();
    final queryWords = normalizedQuery.split(' ');
    
    final results = <Song>[];
    
    for (final song in songs) {
      bool matches = false;
      int relevanceScore = 0;
      
      final title = song.title.toLowerCase();
      final lyrics = song.lyrics?.toLowerCase() ?? '';
      final lyricsEnglish = song.lyricsEnglish?.toLowerCase() ?? '';
      
      // Check title matches (highest relevance)
      if (title.startsWith(normalizedQuery)) {
        matches = true;
        relevanceScore += 100;
      } else if (title.contains(normalizedQuery)) {
        matches = true;
        relevanceScore += 50;
      }
      
      // Check word matches in title
      for (final word in queryWords) {
        if (title.contains(word)) {
          matches = true;
          relevanceScore += 25;
        }
        if (lyrics.contains(word)) {
          matches = true;
          relevanceScore += 10;
        }
        if (lyricsEnglish.contains(word)) {
          matches = true;
          relevanceScore += 10;
        }
      }
      
      if (matches) {
        results.add(song);
      }
    }
    
    return results;
  }
}

void main() async {
  print('🔍 Search Performance Benchmark Tool');
  print('=====================================\n');

  final searchService = SimpleSearchService();
  
  // Try to load songs from the app's JSON file
  List<Song> songs = [];
  
  try {
    final file = File('assets/songs.json');
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      songs = jsonList.map((e) => Song.fromJson(e)).toList();
      print('✅ Loaded ${songs.length} songs from assets/songs.json');
    } else {
      print('⚠️  assets/songs.json not found, generating test data...');
      songs = generateTestSongs(1000);
      print('✅ Generated ${songs.length} test songs');
    }
  } catch (e) {
    print('⚠️  Could not load songs.json: $e');
    print('📝 Generating test data...');
    songs = generateTestSongs(1000);
    print('✅ Generated ${songs.length} test songs');
  }
  
  searchService.loadSongs(songs);
  
  // Test queries in Telugu and English
  final testQueries = [
    'యేసు',    // Telugu - Jesus
    'Jesus',   // English
    'ప్రభు',    // Telugu - Lord  
    'Lord',    // English
    'స్తుతి',   // Telugu - Praise
    'praise',  // English
    'హల్లెలూయ', // Telugu - Hallelujah
    'hallelujah', // English
    'య',       // Single Telugu character
    'J',       // Single English character
    'యేసు ప్రభు', // Multi-word Telugu
    'Jesus Christ', // Multi-word English
    '', // Empty query
  ];

  print('\n🚀 Running Performance Tests...\n');

  // Test old search method
  print('📊 OLD SEARCH METHOD:');
  print('Method\t\tQuery\t\tTime(ms)\tResults');
  print('─' * 60);
  
  for (final query in testQueries) {
    final stopwatch = Stopwatch()..start();
    final results = searchService.searchOld(query);
    stopwatch.stop();
    
    final queryDisplay = query.isEmpty ? '(empty)' : query;
    final time = stopwatch.elapsedMilliseconds;
    
    print('OLD\t\t$queryDisplay\t\t${time}ms\t\t${results.length}');
  }

  print('\n📊 OPTIMIZED SEARCH METHOD:');
  print('Method\t\tQuery\t\tTime(ms)\tResults');
  print('─' * 60);
  
  for (final query in testQueries) {
    final stopwatch = Stopwatch()..start();
    final results = searchService.searchOptimized(query);
    stopwatch.stop();
    
    final queryDisplay = query.isEmpty ? '(empty)' : query;
    final time = stopwatch.elapsedMilliseconds;
    
    print('OPTIMIZED\t$queryDisplay\t\t${time}ms\t\t${results.length}');
  }

  // Stress test
  print('\n🔥 STRESS TEST (1000 rapid searches):');
  final stressTimes = <int>[];
  final random = Random();
  
  final stressStopwatch = Stopwatch()..start();
  for (int i = 0; i < 1000; i++) {
    final query = testQueries[random.nextInt(testQueries.length)];
    final stopwatch = Stopwatch()..start();
    searchService.searchOptimized(query);
    stopwatch.stop();
    stressTimes.add(stopwatch.elapsedMicroseconds);
  }
  stressStopwatch.stop();
  
  final avgTimeUs = stressTimes.reduce((a, b) => a + b) / stressTimes.length;
  final maxTimeUs = stressTimes.reduce((a, b) => a > b ? a : b);
  final minTimeUs = stressTimes.reduce((a, b) => a < b ? a : b);
  
  print('📈 Stress Test Results:');
  print('   Total Time: ${stressStopwatch.elapsedMilliseconds}ms');
  print('   Average: ${(avgTimeUs / 1000).toStringAsFixed(2)}ms');
  print('   Min: ${(minTimeUs / 1000).toStringAsFixed(2)}ms');
  print('   Max: ${(maxTimeUs / 1000).toStringAsFixed(2)}ms');
  print('   Searches/sec: ${(1000 / (stressStopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(0)}');
  
  // Performance verdict
  print('\n🏆 PERFORMANCE VERDICT:');
  if (maxTimeUs / 1000 < 5) {
    print('✅ PASS: Maximum search time ${(maxTimeUs / 1000).toStringAsFixed(2)}ms < 5ms target');
  } else {
    print('❌ FAIL: Maximum search time ${(maxTimeUs / 1000).toStringAsFixed(2)}ms exceeds 5ms target');
  }
  
  if (avgTimeUs / 1000 < 2) {
    print('✅ PASS: Average search time ${(avgTimeUs / 1000).toStringAsFixed(2)}ms < 2ms (excellent)');
  } else if (avgTimeUs / 1000 < 5) {
    print('⚠️  OK: Average search time ${(avgTimeUs / 1000).toStringAsFixed(2)}ms < 5ms (acceptable)');
  } else {
    print('❌ FAIL: Average search time ${(avgTimeUs / 1000).toStringAsFixed(2)}ms exceeds 5ms target');
  }

  print('\n📝 To run this benchmark:');
  print('   dart run benchmark_search.dart');
}

List<Song> generateTestSongs(int count) {
  final teluguWords = ['యేసు', 'ప్రభు', 'దేవుడు', 'స్తుతి', 'హల్లెలూయ', 'కృప', 'ప్రేమ', 'శాంతి', 'రక్షణ', 'మహిమ'];
  final englishWords = ['Jesus', 'Lord', 'God', 'praise', 'hallelujah', 'grace', 'love', 'peace', 'salvation', 'glory'];
  final random = Random();
  final songs = <Song>[];

  for (int i = 0; i < count; i++) {
    final teluguWord1 = teluguWords[random.nextInt(teluguWords.length)];
    final teluguWord2 = teluguWords[random.nextInt(teluguWords.length)];
    final englishWord1 = englishWords[random.nextInt(englishWords.length)];
    final englishWord2 = englishWords[random.nextInt(englishWords.length)];

    songs.add(Song(
      id: 'test-$i',
      title: '$teluguWord1 $englishWord1 ${i + 1}',
      lyrics: '$teluguWord1 $teluguWord2 గీతం స్తుతి హల్లెలూయ ప్రభువా అల్లేలూయ',
      lyricsEnglish: '$englishWord1 $englishWord2 song praise hallelujah Lord alleluia',
    ));
  }

  return songs;
}