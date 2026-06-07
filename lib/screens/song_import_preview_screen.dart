import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';
import 'song_edit_screen.dart';

class SongImportPreviewScreen extends StatefulWidget {
  final String title;
  final List<Song> songs;

  const SongImportPreviewScreen({
    super.key,
    required this.title,
    required this.songs,
  });

  @override
  State<SongImportPreviewScreen> createState() =>
      _SongImportPreviewScreenState();
}

class _SongImportPreviewScreenState extends State<SongImportPreviewScreen> {
  late List<Song> _songs;

  @override
  void initState() {
    super.initState();
    _songs = widget.songs.map((s) => s).toList();
  }

  Future<void> _editSong(int index) async {
    final updated = await Navigator.push<Song>(
      context,
      MaterialPageRoute(
        builder: (context) => SongEditScreen(
          song: _songs[index],
          saveInProvider: false,
        ),
      ),
    );
    if (updated != null) {
      setState(() => _songs[index] = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed:
                _songs.isEmpty ? null : () => Navigator.pop(context, _songs),
            child: const Text('Save All'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Preview and edit songs before saving',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _songs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final song = _songs[index];
                final subtitle = (song.lyrics ?? '').split('\n').take(2).join(
                      '\n',
                    );
                return ListTile(
                  title: Text(
                    song.title.isNotEmpty ? song.title : 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: subtitle.isEmpty
                      ? const Text('No lyrics yet')
                      : Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editSong(index),
                  ),
                  onTap: () => _editSong(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
