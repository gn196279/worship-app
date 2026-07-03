import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';
import '../theme/app_colors.dart';
import '../utils/access_control.dart';
import '../utils/lyrics_display_helper.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/chord_chart_widget.dart';
import '../widgets/login_required_dialog.dart';
import 'song_edit_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;
  final AccessControl access;

  const SongDetailScreen({
    super.key,
    required this.song,
    this.access = const AccessControl(isGuest: false, role: 'singer'),
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late Song _currentSong;

  AccessControl get access => widget.access;

  @override
  void initState() {
    super.initState();
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

  Future<void> _shareSong() async {
    if (!access.canShare) {
      await showLoginRequiredDialog(context, feature: 'share songs');
      return;
    }
    final song = _currentSong;
    final shareText = [
      'Song: ${song.displayTitle}',
      if (song.displayLyrics != LyricsDisplayHelper.bookletLyricsFallback)
        song.displayLyrics,
      if (song.lyricsEnglish?.trim().isNotEmpty == true) song.lyricsEnglish!,
    ].where((text) => text.trim().isNotEmpty).join('\n\n');
    await Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final song = _currentSong;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabs = <Tab>[
      const Tab(text: 'Telugu'),
      const Tab(text: 'English'),
      if (access.canViewChords) const Tab(text: 'Chart'),
    ];

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
          if (access.canEditSongs)
            IconButton(
              icon: Icon(Icons.edit, color: theme.iconTheme.color),
              tooltip: 'Edit Song',
              onPressed: _editSong,
            ),
          IconButton(
            icon: Icon(Icons.share, color: theme.iconTheme.color),
            tooltip: 'Share',
            onPressed: () => unawaited(_shareSong()),
          ),
        ],
      ),
      body: DefaultTabController(
        length: tabs.length,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    tabs: tabs,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: song.displayLyrics.trim().isNotEmpty
                        ? SelectableText(
                            song.displayLyrics,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              height: 1.8,
                              fontFamily: 'Noto Sans Telugu',
                              letterSpacing: 0.3,
                              color: song.usesBookletLyricsFallback
                                  ? theme.hintColor
                                  : theme.textTheme.bodyLarge?.color,
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
                        : song.displayLyrics.trim().isNotEmpty &&
                                !song.usesBookletLyricsFallback
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
                                    song.displayLyrics,
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
                  if (access.canViewChords)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                      child: ChordChartWidget(
                        chordProText: song.effectiveChordProText,
                        onChordTap: (chord) {
                          AppSnackBar.info(context, 'Chord: $chord');
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: access.canUsePlaylist
          ? FloatingActionButton.extended(
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
            )
          : null,
    );
  }
}
