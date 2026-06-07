import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_snackbar.dart';
import 'song_edit_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;
  final bool isGuest;

  const SongDetailScreen({
    super.key,
    required this.song,
    this.isGuest = false,
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late Song _currentSong;

  @override
  void initState() {
    super.initState();
    // Start with the passed song immediately (no null flash).
    // Then try to find a fresher version from the in-memory provider list.
    _currentSong = widget.song;
    _loadSong();
  }

  void _loadSong() {
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final fresh = songProvider.allSongs.firstWhere(
      (s) => s.id == widget.song.id,
      orElse: () => widget.song,
    );
    if (fresh != _currentSong && mounted) {
      setState(() => _currentSong = fresh);
    }
  }

  Future<void> _editSong() async {
    final updatedSong = await Navigator.push<Song>(
      context,
      MaterialPageRoute(
        builder: (context) => SongEditScreen(
          song: _currentSong,
          saveInProvider: false,
        ),
      ),
    );

    if (!mounted || updatedSong == null) return;

    setState(() => _currentSong = updatedSong);
    AppSnackBar.info(
      context,
      'Saved locally, syncing to cloud...',
      duration: const Duration(seconds: 2),
    );

    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final songTitle = updatedSong.displayTitle;
    unawaited(
      songProvider.updateSong(updatedSong).then((_) {
        if (!mounted) return;
        AppSnackBar.success(
          context,
          '"$songTitle" saved to cloud',
          duration: const Duration(seconds: 2),
        );
      }).catchError((e) {
        debugPrint('[SongDetailScreen] Update failed: $e');
        if (!mounted) return;
        AppSnackBar.warning(
          context,
          'Cloud sync failed. Changes are kept locally.',
          duration: const Duration(seconds: 4),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = _currentSong;
    final isGuest = widget.isGuest;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          song.displayTitle,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isGuest)
            IconButton(
              icon: Icon(Icons.edit, color: theme.iconTheme.color),
              tooltip: 'Edit Song',
              onPressed: _editSong,
            ),
          IconButton(
            icon: Icon(Icons.share, color: theme.iconTheme.color),
            tooltip: 'Share',
            onPressed: () async {
              final shareText = [
                'Song: ${song.displayTitle}',
                song.lyrics ?? '',
                if (song.lyricsEnglish?.trim().isNotEmpty == true)
                  song.lyricsEnglish!,
              ].where((text) => text.trim().isNotEmpty).join('\n\n');
              await Share.share(shareText);
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3, // Always show 3 tabs: Telugu, English, Chords
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Song Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Hymn #${song.pageNumber != null && song.pageNumber! > 0 ? song.pageNumber : "—"}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (song.category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  song.category!,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          song.displayTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.hintColor,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Telugu'),
                      Tab(text: 'English'),
                      Tab(text: 'Chords'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Telugu Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: song.lyrics?.trim().isNotEmpty == true
                        ? SelectableText(
                            song.lyrics!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              height: 1.8,
                              fontFamily: 'Noto Sans Telugu',
                              letterSpacing: 0.3,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            textAlign: TextAlign.left,
                          )
                        : Center(
                            child: Text(
                              'No Telugu lyrics available\nYou can add them later',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                  ),
                  // English Tab (show lyrics as fallback when lyricsEnglish is empty, e.g. PDF-extracted songs)
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: song.lyricsEnglish?.trim().isNotEmpty == true
                        ? SelectableText(
                            song.lyricsEnglish!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              height: 1.8,
                              letterSpacing: 0.3,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            textAlign: TextAlign.left,
                          )
                        : song.lyrics?.trim().isNotEmpty == true
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Lyrics / transliteration',
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ),
                                  SelectableText(
                                    song.lyrics!,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 18,
                                      height: 1.8,
                                      letterSpacing: 0.3,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              )
                            : Center(
                                child: Text(
                                  'No English lyrics available\nYou can add them later',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ),
                  ),
                  // Chords Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: song.chords?.trim().isNotEmpty == true
                        ? SelectableText(
                            song.chords!,
                            style: TextStyle(
                              fontSize: 18,
                              height: 1.7,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.left,
                            enableInteractiveSelection: true,
                          )
                        : Center(
                            child: Text(
                              'No chords available\nYou can add them later',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isGuest
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final songProvider = context.read<SongProvider>();
                final songToAdd = _currentSong;
                if (songProvider.selectedSongs
                    .any((s) => s.id == songToAdd.id)) {
                  AppSnackBar.info(context, 'Already in playlist');
                  return;
                }
                songProvider.addToSelected(songToAdd);
                if (mounted) {
                  AppSnackBar.success(context, 'Added to playlist');
                }
              },
              backgroundColor: theme.colorScheme.primary,
              icon: const Icon(Icons.add),
              label: const Text('Add to Playlist'),
            ),
    );
  }
}
