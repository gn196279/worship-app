import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../models/song.dart';

class SelectedSongsWidget extends StatelessWidget {
  const SelectedSongsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SongProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(
                  bottom: BorderSide(color: Colors.blue[100]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Selected Songs (${provider.selectedSongs.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (provider.selectedSongs.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear All'),
                            content: const Text(
                              'Are you sure you want to remove all selected songs?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.clearSelected();
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.clear_all, size: 20),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),

            // List
            Expanded(
              child: provider.selectedSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.playlist_add,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No songs selected',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap songs to add them here',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: provider.selectedSongs.length,
                      onReorder: (oldIndex, newIndex) {
                        provider.reorderSelected(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final song = provider.selectedSongs[index];
                        return _SelectedSongItem(
                          key: ValueKey(song.id),
                          song: song,
                          index: index,
                          onRemove: () => provider.removeFromSelected(song),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SelectedSongItem extends StatelessWidget {
  final Song song;
  final int index;
  final VoidCallback onRemove;

  const _SelectedSongItem({
    required super.key,
    required this.song,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          song.displayTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle, color: Colors.grey),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(song.displayTitle),
              content: SingleChildScrollView(
                child: SelectableText(
                  song.lyrics ?? 'No lyrics available',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
