import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../models/song.dart';
import 'app_snackbar.dart';
import 'song_detail_dialog.dart';

class SongListWidget extends StatelessWidget {
  const SongListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, provider, _) {
        if (provider.allSongs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No songs loaded',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                // const SizedBox(height: 8),
                // Text(
                //   'Upload a PDF to get started',
                //   style: TextStyle(
                //     color: Colors.grey[500],
                //   ),
                // ),
              ],
            ),
          );
        }

        if (provider.searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No songs found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Group songs alphabetically
        final groupedSongs = _groupSongsByFirstLetter(provider.searchResults);
        final sortedKeys = groupedSongs.keys.toList()..sort();

        return ListView.builder(
          itemCount: sortedKeys.fold<int>(
            0,
            (sum, key) => sum + groupedSongs[key]!.length + 1, // +1 for header
          ),
          itemBuilder: (context, index) {
            int currentIndex = 0;
            
            for (final letter in sortedKeys) {
              final songs = groupedSongs[letter]!;
              
              // Header index
              if (index == currentIndex) {
                return _AlphabetHeader(letter: letter);
              }
              currentIndex++;
              
              // Song items
              if (index < currentIndex + songs.length) {
                final songIndex = index - currentIndex;
                final song = songs[songIndex];
                final isSelected = provider.selectedSongs.any((s) => s.id == song.id);
                
                return _SongListItem(
                  song: song,
                  isSelected: isSelected,
                  onTap: () {
                    if (!isSelected) {
                      provider.addToSelected(song);
                      AppSnackBar.success(
                        context,
                        'Added: ${song.displayTitle}',
                        duration: const Duration(seconds: 1),
                      );
                    }
                  },
                );
              }
              currentIndex += songs.length;
            }
            
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Map<String, List<Song>> _groupSongsByFirstLetter(List<Song> songs) {
    final Map<String, List<Song>> grouped = {};
    
    for (final song in songs) {
      final firstChar = song.displayTitle.isNotEmpty 
          ? song.displayTitle[0].toUpperCase() 
          : '#';
      
      // Get English letter or use '#' for non-English
      String letter;
      if (RegExp(r'[A-Z]').hasMatch(firstChar)) {
        letter = firstChar;
      } else {
        letter = '#'; // For Telugu, numbers, or special characters
      }
      
      if (!grouped.containsKey(letter)) {
        grouped[letter] = [];
      }
      grouped[letter]!.add(song);
    }
    
    return grouped;
  }
}

// Alphabet Section Header
class _AlphabetHeader extends StatelessWidget {
  final String letter;

  const _AlphabetHeader({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2B6CEE).withOpacity(0.1),
        border: Border(
          left: BorderSide(
            color: const Color(0xFF2B6CEE),
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2B6CEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            letter == '#' ? 'Other Songs' : 'Songs starting with "$letter"',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _SongListItem extends StatelessWidget {
  final Song song;
  final bool isSelected;
  final VoidCallback onTap;

  const _SongListItem({
    required this.song,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: isSelected ? 0 : 1,
      color: isSelected ? Colors.grey[200] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.green : Colors.blue,
          child: Icon(
            isSelected ? Icons.check : Icons.music_note,
            color: Colors.white,
          ),
        ),
        title: Text(
          song.displayTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.grey[600] : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: song.lyrics != null
            ? Text(
                song.lyrics!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onTap,
                color: Colors.blue,
              ),
        onTap: onTap,
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => SongDetailDialog(song: song),
          );
        },
      ),
    );
  }
}
