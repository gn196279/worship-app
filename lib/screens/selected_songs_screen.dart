import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/song_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/song_detail_dialog.dart';

class SelectedSongsScreen extends StatefulWidget {
  const SelectedSongsScreen({super.key});

  @override
  State<SelectedSongsScreen> createState() => _SelectedSongsScreenState();
}

class _SelectedSongsScreenState extends State<SelectedSongsScreen> {
  bool _isExporting = false;

  String _fileNameFromPath(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final parts = normalized.split('/');
    if (parts.isEmpty) return 'downloaded_file.pdf';
    final fileName = parts.last.trim();
    return fileName.isEmpty ? 'downloaded_file.pdf' : fileName;
  }

  Future<void> _openDownloadedPdf(String filePath) async {
    try {
      final exists = await File(filePath).exists();
      if (!mounted) return;
      if (!exists) {
        AppSnackBar.error(context, 'File not found on device storage.');
        return;
      }

      final result = await OpenFilex.open(
        filePath,
        type: 'application/pdf',
      );
      if (!mounted) return;
      if (result.type != ResultType.done) {
        final message = result.message.trim();
        AppSnackBar.error(
          context,
          message.isEmpty
              ? 'Could not open the downloaded PDF.'
              : 'Could not open file: $message',
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Failed to open PDF: $e');
    }
  }

  Future<void> _shareDownloadedPdf(String filePath) async {
    final shared = await context.read<SongProvider>().shareExportedPdf(filePath);
    if (!mounted || shared) return;
    AppSnackBar.error(context, 'Unable to share PDF right now');
  }

  Future<void> _showDownloadSuccessSheet(String filePath) async {
    if (!mounted) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fileName = _fileNameFromPath(filePath);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            0,
            14,
            12 + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PDF Downloaded',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            unawaited(_openDownloadedPdf(filePath));
                          },
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            unawaited(_shareDownloadedPdf(filePath));
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadSelectedPdf() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    AppSnackBar.info(context, 'Preparing your PDF...');

    try {
      final filePath = await context.read<SongProvider>().exportSelectedAsPDF();
      if (!mounted) return;

      if (filePath == null) {
        AppSnackBar.info(
          context,
          'This feature will be added in the next release.',
        );
        return;
      }

      if (mounted) {
        setState(() => _isExporting = false);
      }
      await _showDownloadSuccessSheet(filePath);
      return;
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Failed to create PDF: $e');
    } finally {
      if (mounted && _isExporting) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Selector<SongProvider, List<Song>>(
          selector: (_, p) => p.selectedSongs,
          builder: (context, selectedSongs, _) {
            final provider = context.read<SongProvider>();
            return Column(
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground)
                        .withOpacity(0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My List',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${selectedSongs.length} Songs Selected',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey[400]
                                    : const Color(0xFF4C669A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: selectedSongs.isEmpty
                            ? null
                            : () {
                                provider.clearSelected();
                              },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Song List
                Expanded(
                  child: selectedSongs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_note_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No songs selected',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Search and add songs to your list',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: selectedSongs.length,
                          onReorder: (oldIndex, newIndex) {
                            provider.reorderSelected(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final song = selectedSongs[index];
                            return Container(
                              key: ValueKey(song.id),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color:
                                    isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[100]!,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Drag handle
                                    Icon(
                                      Icons.drag_indicator,
                                      color: Colors.grey[500],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),

                                    // Music icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.music_note,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Song details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            song.displayTitle,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              height: 1.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Original Page: ${song.pageNumber != null && song.pageNumber! > 0 ? song.pageNumber : "—"}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : const Color(
                                                            0xFF4C669A),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6),
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? Colors.grey[600]
                                                      : Colors.grey[300],
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  song.category ?? 'Worship',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2B6CEE),
                                                    letterSpacing: 0.5,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // View button
                                    IconButton(
                                      icon:
                                          const Icon(Icons.visibility_outlined),
                                      color: const Color(0xFF2B6CEE),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              SongDetailDialog(song: song),
                                        );
                                      },
                                    ),

                                    // Delete button
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: Colors.grey[400],
                                      onPressed: () {
                                        provider.removeFromSelected(song);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // iOS Home Indicator
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 128,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[700]!.withOpacity(0.3)
                          : Colors.grey[300]!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            );
          },
        ),
      ),

      // Fixed Action Button
      floatingActionButton: Selector<SongProvider, bool>(
        selector: (_, p) => p.selectedSongs.isNotEmpty,
        builder: (context, hasSelected, _) {
          if (!hasSelected) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: FloatingActionButton.extended(
              onPressed:
                  _isExporting ? null : () => unawaited(_downloadSelectedPdf()),
              backgroundColor: const Color(0xFF2B6CEE),
              elevation: 8,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text(
                _isExporting ? 'Preparing PDF...' : 'Download Selected as PDF',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
