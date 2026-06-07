import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../providers/song_provider.dart';
import 'song_import_preview_screen.dart';
import '../theme/app_colors.dart';
import 'under_construction_screen.dart';
import 'song_edit_screen.dart';
import '../widgets/app_snackbar.dart';

class UploadPDFScreen extends StatefulWidget {
  const UploadPDFScreen({super.key});

  @override
  State<UploadPDFScreen> createState() => _UploadPDFScreenState();
}

class _UploadPDFScreenState extends State<UploadPDFScreen> {
  static const bool _uploadsEnabled = true;
  bool _isUploading = false;

  // =======================
  // PICK PDF
  // =======================
  Future<void> _pickPdf() async {
    if (!_uploadsEnabled) {
      _showUnderConstruction();
      return;
    }
    if (_isUploading) return;

    try {
      setState(() => _isUploading = true);

      final provider = Provider.of<SongProvider>(context, listen: false);
      final songs = await provider.parsePdfForPreview();

      if (!mounted) return;

      if (songs.isNotEmpty) {
        final updatedSongs = await Navigator.push<List<Song>>(
          context,
          MaterialPageRoute(
            builder: (context) => SongImportPreviewScreen(
              title: 'Preview PDF Songs',
              songs: songs,
            ),
          ),
        );
        if (updatedSongs != null && updatedSongs.isNotEmpty) {
          await provider.saveImportedSongs(updatedSongs);
          if (mounted) {
            _showSuccessDialog(updatedSongs.length, updatedSongs);
          }
        }
      } else {
        AppSnackBar.warning(
          context,
          'No PDF selected or no text found.\n\nTip: Make sure the PDF contains clear Telugu text.',
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error processing PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // =======================
  // PICK IMAGES (OCR)
  // =======================
  Future<void> _pickImages() async {
    if (!_uploadsEnabled) {
      _showUnderConstruction();
      return;
    }
    if (_isUploading) return;

    try {
      setState(() => _isUploading = true);

      final provider = Provider.of<SongProvider>(context, listen: false);
      final songs = await provider.parseImagesForPreview();

      if (!mounted) return;

      if (songs.isNotEmpty) {
        final updatedSongs = await Navigator.push<List<Song>>(
          context,
          MaterialPageRoute(
            builder: (context) => SongImportPreviewScreen(
              title: 'Preview Image Songs',
              songs: songs,
            ),
          ),
        );
        if (updatedSongs != null && updatedSongs.isNotEmpty) {
          await provider.saveImportedSongs(updatedSongs);
          if (mounted) {
            _showSuccessDialog(updatedSongs.length, updatedSongs);
          }
        }
      } else {
        AppSnackBar.warning(
          context,
          'No images selected or no text found.\n\nTip: Make sure images contain clear Telugu text.',
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error processing images: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // =======================
  // SUCCESS DIALOG
  // =======================
  void _showSuccessDialog(int songCount, List<Song> songs) {
    final songTitles = songs.take(3).map((s) => s.title).join('\n');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('✓ Upload Successful'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Successfully parsed $songCount songs!'),
              const SizedBox(height: 16),
              const Text(
                'First few songs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(songTitles),
              if (songCount > 3) Text('\n... and ${songCount - 3} more'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('View Songs'),
          ),
        ],
      ),
    );
  }

  void _showUnderConstruction() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UnderConstructionScreen(),
      ),
    );
  }

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground(isDark),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white70 : AppColors.lightText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upload Song PDF',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Songs',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'మీ పాటల పుస్తకాలను డిజిటల్ లైబ్రరీగా మార్చుకోండి.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                color: AppColors.cardBackground(isDark),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.picture_as_pdf,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select Song Collection',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PDF files up to 50MB supported',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickPdf,
                      icon: const Icon(Icons.upload_file),
                      label:
                          Text(_isUploading ? 'Uploading...' : 'Browse Files'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Upload Images Instead'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Manual add section (always enabled)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                color: AppColors.cardBackground(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add song manually',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type Telugu, English and chords yourself. '
                              'The song will be saved to the cloud and synced here.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now().millisecondsSinceEpoch;
                        final newSong = Song(
                          id: 'manual_$now',
                          title: '',
                          lyrics: '',
                          lyricsEnglish: '',
                          chords: '',
                          pageNumber: null,
                          category: 'Worship',
                          createdAt: DateTime.now(),
                        );
                        final updated = await Navigator.push<Song>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SongEditScreen(
                              song: newSong,
                              saveInProvider: false,
                            ),
                          ),
                        );
                        if (updated != null && context.mounted) {
                          final songProvider =
                              Provider.of<SongProvider>(context, listen: false);
                          final songTitle = updated.displayTitle;

                          AppSnackBar.info(
                            context,
                            'Saved locally, syncing to cloud...',
                            duration: const Duration(seconds: 2),
                          );

                          unawaited(
                            songProvider.updateSong(updated).then((_) {
                              if (!mounted) return;
                              AppSnackBar.success(
                                context,
                                '"$songTitle" saved to cloud',
                                duration: const Duration(seconds: 2),
                              );
                            }).catchError((e) {
                              if (!mounted) return;
                              AppSnackBar.warning(
                                context,
                                'Cloud sync failed. Changes are kept locally.',
                                duration: const Duration(seconds: 4),
                              );
                            }),
                          );

                          Navigator.of(context).pop(true);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add song manually'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.info, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'How it works',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.hintColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: const Column(
                children: [
                  _StepRow(number: 1, text: 'Upload your Telugu songbook PDF.'),
                  SizedBox(height: 10),
                  _StepRow(
                      number: 2, text: 'We identify song titles and lyrics.'),
                  SizedBox(height: 10),
                  _StepRow(
                      number: 3,
                      text: 'Songs appear in your library instantly.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            number.toString(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
      ],
    );
  }
}
