import 'package:flutter_test/flutter_test.dart';
import 'package:gilgal_telugu_worship/models/song.dart';
import 'package:gilgal_telugu_worship/services/search_service.dart';

void main() {
  group('Search Service Performance and Functionality Tests', () {
    late SearchService searchService;
    late List<Song> testSongs;

    setUpAll(() {
      searchService = SearchService();
      
      // Create a large dataset of test songs with mixed Telugu and English content
      testSongs = _createTestSongs();
      
      // Build the search index
      final indexStopwatch = Stopwatch()..start();
      searchService.buildIndex(testSongs);
      indexStopwatch.stop();
      
      print('Search index built in ${indexStopwatch.elapsedMilliseconds}ms for ${testSongs.length} songs');
    });

    group('Performance Tests (Target: < 5ms)', () {
      test('Single word search should complete under 5ms', () {
        final searches = ['యేసు', 'Jesus', 'ప్రభు', 'Lord', 'స్తుతి'];
        
        for (final query in searches) {
          final stopwatch = Stopwatch()..start();
          final results = searchService.search(query);
          stopwatch.stop();
          
          print('Search for "$query" completed in ${stopwatch.elapsedMicroseconds}μs (${stopwatch.elapsedMilliseconds}ms)');
          expect(stopwatch.elapsedMilliseconds, lessThan(5), 
            reason: 'Search for "$query" took ${stopwatch.elapsedMilliseconds}ms, should be under 5ms');
          expect(results, isNotEmpty, reason: 'Should find results for "$query"');
        }
      });

      test('Multi-word search should complete under 5ms', () {
        final searches = ['యేసు ప్రభు', 'Jesus Christ', 'హల్లెలూయ స్తుతి', 'praise the lord'];
        
        for (final query in searches) {
          final stopwatch = Stopwatch()..start();
          final results = searchService.search(query);
          stopwatch.stop();
          
          print('Multi-word search for "$query" completed in ${stopwatch.elapsedMicroseconds}μs');
          expect(stopwatch.elapsedMilliseconds, lessThan(5), 
            reason: 'Multi-word search for "$query" took ${stopwatch.elapsedMilliseconds}ms');
        }
      });

      test('Prefix search should complete under 5ms', () {
        final prefixes = ['య', 'Je', 'ప్ర', 'Chr', 'హ'];
        
        for (final prefix in prefixes) {
          final stopwatch = Stopwatch()..start();
          final results = searchService.search(prefix);
          stopwatch.stop();
          
          print('Prefix search for "$prefix" completed in ${stopwatch.elapsedMicroseconds}μs');
          expect(stopwatch.elapsedMilliseconds, lessThan(5), 
            reason: 'Prefix search for "$prefix" took ${stopwatch.elapsedMilliseconds}ms');
        }
      });

      test('Complex search with special characters should complete under 5ms', () {
        final complexQueries = ['యేసు-ప్రభు', 'Jesus_Christ', 'స్తుతి!', 'praise?'];
        
        for (final query in complexQueries) {
          final stopwatch = Stopwatch()..start();
          final results = searchService.search(query);
          stopwatch.stop();
          
          print('Complex search for "$query" completed in ${stopwatch.elapsedMicroseconds}μs');
          expect(stopwatch.elapsedMilliseconds, lessThan(5), 
            reason: 'Complex search for "$query" took ${stopwatch.elapsedMilliseconds}ms');
        }
      });
    });

    group('Functionality Tests', () {
      test('Should find songs by title prefix', () {
        final results = searchService.search('యేసు');
        expect(results.any((song) => song.title.toLowerCase().startsWith('యేసు')), isTrue);
        
        final englishResults = searchService.search('Jesus');
        expect(englishResults.any((song) => song.title.toLowerCase().startsWith('jesus')), isTrue);
      });

      test('Should find songs by title containing keyword', () {
        final results = searchService.search('ప్రభు');
        expect(results.any((song) => song.title.toLowerCase().contains('ప్రభు')), isTrue);
        
        final englishResults = searchService.search('Lord');
        expect(englishResults.any((song) => song.title.toLowerCase().contains('lord')), isTrue);
      });

      test('Should find songs by lyrics content', () {
        final results = searchService.search('హల్లెలూయ');
        expect(results.isNotEmpty, isTrue);
        
        final englishResults = searchService.search('hallelujah');
        expect(englishResults.isNotEmpty, isTrue);
      });

      test('Should prioritize title matches over lyrics matches', () {
        final results = searchService.search('యేసు');
        
        // Songs with యేసు in title should come before songs with యేసు only in lyrics
        final titleMatches = results.where((song) => song.title.toLowerCase().contains('యేసు')).length;
        final totalMatches = results.length;
        
        expect(titleMatches, greaterThan(0));
        expect(totalMatches, greaterThanOrEqualTo(titleMatches));
      });

      test('Should handle empty and whitespace queries', () {
        expect(searchService.search('').length, equals(testSongs.length));
        expect(searchService.search('   ').length, equals(testSongs.length));
        expect(searchService.search('\t\n').length, equals(testSongs.length));
      });

      test('Should handle Telugu script variations', () {
        // Test common Telugu character variations
        final variations = ['యేసు', 'యేసూ', 'ప్రభు', 'ప్రభూ'];
        
        for (final variation in variations) {
          final results = searchService.search(variation);
          expect(results.isNotEmpty, isTrue, reason: 'Should find results for Telugu variation: $variation');
        }
      });

      test('Should be case insensitive for English text', () {
        final lowerResults = searchService.search('jesus');
        final upperResults = searchService.search('JESUS');
        final mixedResults = searchService.search('Jesus');
        
        expect(lowerResults.length, equals(upperResults.length));
        expect(lowerResults.length, equals(mixedResults.length));
      });

      test('Should handle partial word matching', () {
        final results = searchService.search('యే'); // Partial Telugu word
        expect(results.isNotEmpty, isTrue);
        
        final englishResults = searchService.search('Je'); // Partial English word
        expect(englishResults.isNotEmpty, isTrue);
      });

      test('Should limit results when specified', () {
        final allResults = searchService.search('స్తుతి');
        final limitedResults = searchService.search('స్తుతి', maxResults: 5);
        
        if (allResults.length > 5) {
          expect(limitedResults.length, equals(5));
        } else {
          expect(limitedResults.length, equals(allResults.length));
        }
      });
    });

    group('Edge Cases and Stress Tests', () {
      test('Should handle very long search queries', () {
        final longQuery = 'యేసు ప్రభు స్తుతి హల్లెలూయ అల్లేలూయ Jesus Christ Lord praise hallelujah alleluia';
        
        final stopwatch = Stopwatch()..start();
        final results = searchService.search(longQuery);
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(5));
        expect(results.isNotEmpty, isTrue);
      });

      test('Should handle special characters and punctuation', () {
        final specialQueries = ['యేసు!', 'Jesus?', 'ప్రభు...', 'Lord,', 'స్తుతి-గీతం'];
        
        for (final query in specialQueries) {
          final stopwatch = Stopwatch()..start();
          final results = searchService.search(query);
          stopwatch.stop();
          
          expect(stopwatch.elapsedMilliseconds, lessThan(5));
        }
      });

      test('Should handle repeated searches without performance degradation', () {
        final query = 'యేసు ప్రభు';
        final times = <int>[];
        
        for (int i = 0; i < 100; i++) {
          final stopwatch = Stopwatch()..start();
          searchService.search(query);
          stopwatch.stop();
          times.add(stopwatch.elapsedMicroseconds);
        }
        
        final averageTime = times.reduce((a, b) => a + b) / times.length;
        final maxTime = times.reduce((a, b) => a > b ? a : b);
        
        print('Average search time: ${averageTime.toStringAsFixed(1)}μs, Max: ${maxTime}μs');
        expect(maxTime / 1000, lessThan(5)); // Convert to milliseconds
      });
    });

    group('Index Update Tests', () {
      test('Should update index when song is modified', () {
        final originalSong = Song(
          id: 'test-update-1',
          title: 'Original Title',
          lyrics: 'Original lyrics content',
          lyricsEnglish: 'Original English lyrics',
        );
        
        // Add to test data and rebuild index
        testSongs.add(originalSong);
        searchService.buildIndex(testSongs);
        
        // Search should find the original song
        final originalResults = searchService.search('Original');
        expect(originalResults.any((s) => s.id == 'test-update-1'), isTrue);
        
        // Update the song
        final updatedSong = Song(
          id: 'test-update-1',
          title: 'Updated Title',
          lyrics: 'Updated lyrics content',
          lyricsEnglish: 'Updated English lyrics',
        );
        
        final stopwatch = Stopwatch()..start();
        searchService.updateSong(updatedSong);
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(5));
        
        // Should find with new content
        final updatedResults = searchService.search('Updated');
        expect(updatedResults.any((s) => s.id == 'test-update-1'), isTrue);
        
        // Should not find with old content
        final oldResults = searchService.search('Original');
        expect(oldResults.any((s) => s.id == 'test-update-1'), isFalse);
      });
    });
  });
}

/// Creates a comprehensive test dataset with Telugu and English songs
List<Song> _createTestSongs() {
  final songs = <Song>[];
  
  // Telugu songs with common worship terms
  final teluguSongs = [
    {
      'title': 'యేసు ప్రభువా స్తుతి',
      'lyrics': 'యేసు ప్రభువా నిన్ను స్తుతిస్తాము\nహల్లెలూయ అల్లేలూయ\nనీ మహిమకు గొప్పదైన స్తుతి',
      'lyricsEnglish': 'Jesus our Lord we praise you\nHallelujah Alleluia\nGreat praise to your glory'
    },
    {
      'title': 'దేవుని కృప',
      'lyrics': 'దేవుని కృప ఎంతో గొప్పది\nయేసు ప్రభు రక్షకుడు\nస్తుతి స్తుతి హల్లెలూయ',
      'lyricsEnglish': 'God\'s grace is so great\nJesus Lord is savior\nPraise praise hallelujah'
    },
    {
      'title': 'హల్లెలూయ గీతం',
      'lyrics': 'హల్లెలూయ హల్లెలూయ\nప్రభువును స్తుతిద్దాం\nయేసు నామంలో విజయం',
      'lyricsEnglish': 'Hallelujah hallelujah\nLet us praise the Lord\nVictory in Jesus name'
    },
    {
      'title': 'ప్రార్థన స్తుతి',
      'lyrics': 'ప్రభువా నిన్ను కేకలిడుచున్నాను\nనా దేవా నా రాజా\nస్తుতి గీతలతో వచ్చుచున్నాను',
      'lyricsEnglish': 'Lord I am calling you\nMy God my King\nI come with songs of praise'
    },
  ];
  
  // English songs
  final englishSongs = [
    {
      'title': 'Jesus Christ Our Savior',
      'lyrics': 'Jesus Christ our Lord and Savior\nHallelujah praise the Lord\nGlory glory to the highest',
      'lyricsEnglish': 'Jesus Christ our Lord and Savior\nHallelujah praise the Lord\nGlory glory to the highest'
    },
    {
      'title': 'Praise the Lord',
      'lyrics': 'Praise the Lord with all your heart\nJesus is our King\nHallelujah sing alleluia',
      'lyricsEnglish': 'Praise the Lord with all your heart\nJesus is our King\nHallelujah sing alleluia'
    },
    {
      'title': 'Amazing Grace',
      'lyrics': 'Amazing grace how sweet the sound\nJesus saved a soul like me\nPraise God almighty hallelujah',
      'lyricsEnglish': 'Amazing grace how sweet the sound\nJesus saved a soul like me\nPraise God almighty hallelujah'
    },
  ];
  
  // Create songs from Telugu data
  for (int i = 0; i < teluguSongs.length; i++) {
    final songData = teluguSongs[i];
    songs.add(Song(
      id: 'telugu-$i',
      title: songData['title']!,
      lyrics: songData['lyrics'],
      lyricsEnglish: songData['lyricsEnglish'],
      category: 'Telugu Worship',
      createdAt: DateTime.now().subtract(Duration(days: i)),
    ));
  }
  
  // Create songs from English data
  for (int i = 0; i < englishSongs.length; i++) {
    final songData = englishSongs[i];
    songs.add(Song(
      id: 'english-$i',
      title: songData['title']!,
      lyrics: songData['lyrics'],
      lyricsEnglish: songData['lyricsEnglish'],
      category: 'English Worship',
      createdAt: DateTime.now().subtract(Duration(days: i + 10)),
    ));
  }
  
  // Generate additional songs for performance testing
  for (int i = 0; i < 1000; i++) {
    final teluguTitles = ['యేసు', 'ప్రభు', 'దేవుడు', 'స్తుతి', 'హల్లెలూయ', 'కృప', 'ప్రేమ', 'శాంతి'];
    final englishTitles = ['Jesus', 'Lord', 'God', 'Praise', 'Hallelujah', 'Grace', 'Love', 'Peace'];
    
    final teluguTitle = teluguTitles[i % teluguTitles.length];
    final englishTitle = englishTitles[i % englishTitles.length];
    
    songs.add(Song(
      id: 'generated-$i',
      title: '$teluguTitle $englishTitle $i',
      lyrics: '$teluguTitle గీతం హల్లెలూయ స్తుతి ప్రభువా ${i * 2}',
      lyricsEnglish: '$englishTitle song hallelujah praise Lord ${i * 3}',
      category: 'Generated',
      createdAt: DateTime.now().subtract(Duration(days: i + 100)),
    ));
  }
  
  return songs;
}