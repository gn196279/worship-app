import 'dart:async';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/song_provider.dart';
import '../widgets/app_snackbar.dart';

class SongEditScreen extends StatefulWidget {
  final Song song;
  final bool saveInProvider;

  const SongEditScreen({
    super.key,
    required this.song,
    this.saveInProvider = true,
  });

  @override
  State<SongEditScreen> createState() => _SongEditScreenState();
}

class _SongEditScreenState extends State<SongEditScreen> {
  bool _saved = false; // guard against double-taps
  late final TextEditingController _titleController;
  late final TextEditingController _lyricsController;
  late final TextEditingController _lyricsEnglishController;
  late final TextEditingController _chordsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _lyricsController = TextEditingController(text: widget.song.lyrics ?? '');
    _lyricsEnglishController =
        TextEditingController(text: widget.song.lyricsEnglish ?? '');
    _chordsController = TextEditingController(text: widget.song.chords ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    _lyricsEnglishController.dispose();
    _chordsController.dispose();
    super.dispose();
  }

  void _save() {
    if (_saved) return;

    final titleText = _titleController.text.trim();
    if (titleText.isEmpty) {
      AppSnackBar.warning(context, 'Please enter a song title');
      return;
    }

    _saved = true;

    final songProvider = Provider.of<SongProvider>(context, listen: false);
    // New manual songs (manual_*) get next available hymn number so they don't show as Hymn #0
    int? pageNumber = widget.song.pageNumber;
    if (pageNumber == null && widget.song.id.startsWith('manual_')) {
      final maxPage = songProvider.allSongs.fold<int>(0, (m, s) {
        final p = s.pageNumber ?? 0;
        return p > m ? p : m;
      });
      pageNumber = maxPage + 1;
    }

    final updated = Song(
      id: widget.song.id,
      title: titleText,
      lyrics: _lyricsController.text.trim(),
      lyricsEnglish: _lyricsEnglishController.text.trim(),
      chords: _chordsController.text.trim(),
      pageNumber: pageNumber,
      category: widget.song.category,
      createdAt: widget.song.createdAt,
    );

    if (widget.saveInProvider) {
      // Sync in background so save feels instant.
      unawaited(
        songProvider.updateSong(updated).catchError(
              (e) => debugPrint('[SongEditScreen] Background sync error: $e'),
            ),
      );
    }

    // Pop immediately — local state is already updated inside updateSong()
    if (mounted) Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Edit Song'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Song Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.music_note),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _lyricsController,
              decoration: const InputDecoration(
                labelText: 'Telugu Lyrics',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                helperText: 'Enter Telugu lyrics here',
              ),
              maxLines: null,
              minLines: 10,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _lyricsEnglishController,
              decoration: const InputDecoration(
                labelText: 'English Lyrics',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                helperText: 'Enter English transliteration here',
              ),
              maxLines: null,
              minLines: 10,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _chordsController,
              decoration: const InputDecoration(
                labelText: 'Chords',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                helperText: 'Enter chords (e.g., Am, G, D)',
              ),
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
