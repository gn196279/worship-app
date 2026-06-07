import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

import '../models/song.dart';

class PDFService {
  // ============================================================
  // GOOGLE CLOUD VISION API CONFIGURATION
  // ============================================================

  // Provide via --dart-define=GCV_API_KEY=...
  static const String _googleCloudApiKey =
      String.fromEnvironment('GCV_API_KEY');
  static const String _visionApiUrl =
      'https://vision.googleapis.com/v1/images:annotate';

  // ============================================================
  // IMPROVED IMAGE PREPROCESSING
  // ============================================================

  int _averageLuminance(img.Image image) {
    const step = 10;
    int total = 0;
    int count = 0;
    for (int y = 0; y < image.height; y += step) {
      for (int x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        total += ((0.299 * r) + (0.587 * g) + (0.114 * b)).round();
        count++;
      }
    }
    if (count == 0) return 128;
    return total ~/ count;
  }

  img.Image _preprocessForOcr(img.Image source) {
    var processed = source.clone();

    // Convert to grayscale
    processed = img.grayscale(processed);

    // Check if image needs inverting (dark background)
    final avg = _averageLuminance(processed);
    if (avg < 120) {
      processed = img.invert(processed);
    }

    // Upscale if too small (Cloud Vision works better with larger images)
    if (processed.width < 1600) {
      final scale = 1600 / processed.width;
      processed = img.copyResize(
        processed,
        width: (processed.width * scale).toInt(),
        interpolation: img.Interpolation.cubic,
      );
    }

    // Enhance contrast
    processed = img.adjustColor(processed, contrast: 1.3, brightness: 1.1);

    return processed;
  }

  // ============================================================
  // GOOGLE CLOUD VISION API - TELUGU OCR
  // ============================================================

  Future<String> _performCloudVisionOcr(String imagePath) async {
    try {
      // Read and encode image
      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Prepare API request
      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'TEXT_DETECTION'}
            ],
            'imageContext': {
              'languageHints': ['te', 'en'] // Telugu and English
            }
          }
        ]
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$_visionApiUrl?key=$_googleCloudApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final textAnnotations = jsonResponse['responses'][0]['textAnnotations'];

        if (textAnnotations != null && textAnnotations.isNotEmpty) {
          // First annotation contains full text
          return textAnnotations[0]['description'] ?? '';
        }
      } else {
        debugPrint('❌ Cloud Vision API Error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }

      return '';
    } catch (e) {
      debugPrint('❌ Cloud Vision OCR error: $e');
      return '';
    }
  }

  String _cleanupOcrText(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  // ============================================================
  // IMAGE PICKER (OCR) - WITH CLOUD VISION API
  // ============================================================

  Future<List<Song>> parseImagesToSongs() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();

      if (images.isEmpty) return [];

      if (_googleCloudApiKey.isEmpty) {
        debugPrint('❌ ERROR: Google Cloud API key not configured!');
        return [
          Song(
            id: 'error',
            title: 'API Key Required',
            lyrics:
                'Please add your Google Cloud Vision API key to PDFService.\n\n'
                'Get one from: https://console.cloud.google.com/apis/credentials',
            pageNumber: 1,
            createdAt: DateTime.now(),
          )
        ];
      }

      List<Song> songs = [];

      for (int i = 0; i < images.length; i++) {
        debugPrint('🔍 Processing image ${i + 1}/${images.length}...');

        // Preprocess image for better OCR
        final bytes = await images[i].readAsBytes();
        final decoded = img.decodeImage(bytes);

        String processedPath = images[i].path;

        if (decoded != null) {
          final processed = _preprocessForOcr(decoded);
          final tempDir = await getTemporaryDirectory();
          processedPath =
              '${tempDir.path}${Platform.pathSeparator}ocr_${DateTime.now().millisecondsSinceEpoch}_$i.png';
          await File(processedPath)
              .writeAsBytes(img.encodePng(processed), flush: true);
        }

        // Perform Cloud Vision OCR
        final text = await _performCloudVisionOcr(processedPath);
        final cleanedText = _cleanupOcrText(text);

        debugPrint(
            '📄 Extracted ${cleanedText.length} characters from image ${i + 1}');

        songs.add(
          Song(
            id: 'song_img_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: 'Song from Image ${i + 1}',
            lyrics: cleanedText.isNotEmpty
                ? cleanedText
                : 'Image: ${images[i].name}\n\n(No text detected - try better lighting/resolution)',
            pageNumber: i + 1,
            createdAt: DateTime.now(),
          ),
        );
      }

      debugPrint('✅ Successfully parsed ${songs.length} images');
      return songs;
    } catch (e) {
      debugPrint('❌ Image parsing error: $e');
      return [];
    }
  }

  // ============================================================
  // PDF → MULTIPLE SONGS PARSER
  // ============================================================

  Future<List<Song>> parsePDFToSongs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) {
        return [];
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      final document = syncfusion.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;

      debugPrint('📖 PDF has $pageCount pages');

      List<Song> songs = [];

      // Extract text page by page
      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final extractor = syncfusion.PdfTextExtractor(document);
        final pageText = extractor.extractText(
          startPageIndex: pageIndex,
          endPageIndex: pageIndex,
        );

        if (pageText.trim().isEmpty) {
          debugPrint(
              '⚠️ Page ${pageIndex + 1} is empty or scanned - attempting OCR...');

          // Try OCR on scanned PDF pages
          final pageSongs = await _ocrPdfPage(bytes, pageIndex, songs.length);
          if (pageSongs.isNotEmpty) {
            songs.addAll(pageSongs);
          }
          continue;
        }

        final lines = pageText
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

        if (lines.isEmpty) continue;

        // Extract songs from text
        final pageSongs =
            _extractSongsFromLines(lines, pageIndex + 1, songs.length);
        songs.addAll(pageSongs);
      }

      document.dispose();

      debugPrint('✅ Extracted ${songs.length} songs from PDF');
      return songs;
    } catch (e) {
      debugPrint('❌ PDF parsing error: $e');
      return [];
    }
  }

  // OCR for scanned PDF pages
  // PDF OCR functionality disabled due to missing printing plugin
  Future<List<Song>> _ocrPdfPage(
    Uint8List pdfBytes,
    int pageIndex,
    int startingSongCount,
  ) async {
    // Disabled: printing plugin removed for build
    return [];
  }

  List<Song> _extractSongsFromLines(
    List<String> lines,
    int pageNumber,
    int startingSongCount,
  ) {
    List<Song> songs = [];
    String? currentTitle;
    StringBuffer lyricsBuffer = StringBuffer();
    int songNumberOnPage = 1;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final hasTelugu = RegExp(r'[\u0C00-\u0C7F]').hasMatch(line);

      // Detect song title
      final isLikelyTitle = (currentTitle == null ||
              lyricsBuffer.toString().split('\n').length > 8) &&
          hasTelugu &&
          line.length < 80 &&
          (line.length < 40 || RegExp(r'^\d+[\.\)]\s*').hasMatch(line));

      if (isLikelyTitle) {
        // Save previous song
        if (currentTitle != null && lyricsBuffer.toString().trim().isNotEmpty) {
          songs.add(
            Song(
              id: 'song_${startingSongCount + songNumberOnPage}',
              title: currentTitle,
              lyrics: lyricsBuffer.toString().trim(),
              pageNumber: pageNumber,
              createdAt: DateTime.now(),
            ),
          );
          songNumberOnPage++;
        }

        // Start new song
        currentTitle = line.replaceAll(RegExp(r'^\d+[\.\)]\s*'), '').trim();
        lyricsBuffer.clear();
      } else if (hasTelugu && currentTitle != null) {
        // Add lyric line
        lyricsBuffer.writeln(line);
      } else if (!hasTelugu && line.length < 50 && currentTitle == null) {
        // Possible English title
        currentTitle = line;
      }
    }

    // Save last song
    if (currentTitle != null && lyricsBuffer.toString().trim().isNotEmpty) {
      songs.add(
        Song(
          id: 'song_${startingSongCount + songNumberOnPage}',
          title: currentTitle,
          lyrics: lyricsBuffer.toString().trim(),
          pageNumber: pageNumber,
          createdAt: DateTime.now(),
        ),
      );
    }

    return songs;
  }

  // ============================================================
  // EXPORT SELECTED SONGS TO PDF (Telugu-friendly format)
  // Uses bundled Noto Sans Telugu for correct rendering.
  // ============================================================

  Future<String?> createPDFFromSongs(List<Song> songs) async {
    if (songs.isEmpty) return null;

    // New simple, Telugu-safe generator that matches the user's snippet:
    // - Embeds NotoSansTelugu (offline, from assets)
    // - No letterSpacing or mixed fonts
    // - Cleaned text to remove control characters
    try {
      // Load Telugu fonts from assets
      final regularFontData =
          await rootBundle.load('assets/fonts/NotoSansTelugu-Regular.ttf');
      final boldFontData =
          await rootBundle.load('assets/fonts/NotoSansTelugu-Bold.ttf');

      final regularFont = pw.Font.ttf(regularFontData.buffer.asByteData());
      final boldFont = pw.Font.ttf(boldFontData.buffer.asByteData());

      // Global Telugu theme
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
      );

      for (final song in songs) {
        final rawTitle =
            song.displayTitle.isNotEmpty ? song.displayTitle : 'Untitled';
        final title = _cleanTeluguText(rawTitle);
        final lyrics = _cleanTeluguText(
          song.lyrics ?? 'No Telugu lyrics available',
        );

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (context) => [
              pw.Text(
                title,
                style: const pw.TextStyle(
                  fontSize: 20,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                lyrics,
                style: const pw.TextStyle(
                  fontSize: 18,
                  // Use lineSpacing instead of letterSpacing — safer for Telugu.
                  lineSpacing: 8,
                ),
              ),
              pw.SizedBox(height: 30),
            ],
          ),
        );
      }

      final bytes = await pdf.save();
      return _savePdfToStorage(bytes);
    } catch (e) {
      debugPrint('❌ Simple Telugu PDF export error: $e');
      // As a last resort, fall back to the previous background pipeline.
      debugPrint('⚠️ Falling back to background PDF export pipeline...');
      final backgroundPath = await _createPDFFromSongsInBackground(songs);
      if (backgroundPath != null) return backgroundPath;
      debugPrint('⚠️ Full PDF export failed, retrying with fast format...');
      return _createFastPDFFromSongsInBackground(songs);
    }
  }

  String _cleanTeluguText(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      // Keep newlines (10) and carriage returns (13), drop other control chars.
      if (rune < 32 && rune != 10 && rune != 13) continue;
      buffer.writeCharCode(rune);
    }
    return buffer.toString();
  }

  Future<String?> _createPDFFromSongsInBackground(List<Song> songs) async {
    try {
      Uint8List? regularFontBytes;
      Uint8List? boldFontBytes;

      try {
        final regular = await rootBundle.load(
          'assets/fonts/NotoSansTelugu-Regular.ttf',
        );
        final bold = await rootBundle.load(
          'assets/fonts/NotoSansTelugu-Bold.ttf',
        );
        regularFontBytes = regular.buffer.asUint8List(
          regular.offsetInBytes,
          regular.lengthInBytes,
        );
        boldFontBytes = bold.buffer.asUint8List(
          bold.offsetInBytes,
          bold.lengthInBytes,
        );
      } catch (_) {
        // Fonts are optional for worker export; fallback fonts are used.
      }

      final payloadSongs = <Map<String, dynamic>>[
        for (final song in songs)
          {
            'title': song.displayTitle,
            'lyrics': song.lyrics ?? '',
            'pageNumber': song.pageNumber,
            'category': song.category ?? '',
          },
      ];

      final bytes = await compute<Map<String, dynamic>, Uint8List?>(
        _buildPdfBytesOnWorker,
        {
          'songs': payloadSongs,
          'regularFont': regularFontBytes,
          'boldFont': boldFontBytes,
        },
      );

      if (bytes == null || bytes.isEmpty) return null;
      return _savePdfToStorage(bytes);
    } catch (e) {
      debugPrint('❌ Background PDF export error: $e');
      return null;
    }
  }

  Future<String?> _createFastPDFFromSongsInBackground(List<Song> songs) async {
    try {
      Uint8List? regularFontBytes;
      Uint8List? boldFontBytes;

      try {
        final regular = await rootBundle.load(
          'assets/fonts/NotoSansTelugu-Regular.ttf',
        );
        final bold = await rootBundle.load(
          'assets/fonts/NotoSansTelugu-Bold.ttf',
        );
        regularFontBytes = regular.buffer.asUint8List(
          regular.offsetInBytes,
          regular.lengthInBytes,
        );
        boldFontBytes = bold.buffer.asUint8List(
          bold.offsetInBytes,
          bold.lengthInBytes,
        );
      } catch (_) {
        // Worker will attempt Google Fonts fallback if bundled files are missing.
      }

      final payloadSongs = <Map<String, dynamic>>[
        for (final song in songs)
          {
            'title': song.displayTitle,
            'lyrics': song.lyrics ?? '',
            'pageNumber': song.pageNumber,
            'category': song.category ?? '',
          },
      ];

      final bytes = await compute<Map<String, dynamic>, Uint8List?>(
        _buildFastPdfBytesOnWorker,
        {
          'songs': payloadSongs,
          'regularFont': regularFontBytes,
          'boldFont': boldFontBytes,
        },
      );
      if (bytes == null || bytes.isEmpty) return null;
      return _savePdfToStorage(bytes);
    } catch (e) {
      debugPrint('❌ Fast PDF export error: $e');
      return null;
    }
  }

  Future<String?> _savePdfToStorage(Uint8List bytes) async {
    try {
      Directory baseDir;
      // Prefer Downloads when available so users can find the file quickly.
      Directory? downloadsDir;
      if (!kIsWeb) {
        try {
          downloadsDir = await getDownloadsDirectory();
        } catch (_) {
          downloadsDir = null;
        }
      }

      if (downloadsDir != null) {
        baseDir = downloadsDir;
      } else if (!kIsWeb && Platform.isAndroid) {
        baseDir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      final exportDir =
          Directory('${baseDir.path}${Platform.pathSeparator}Gilgal_PDFs');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final fileName =
          'gilgal_songs_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${exportDir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('✅ PDF saved at: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ Failed to save PDF to storage: $e');
      return null;
    }
  }

  Future<bool> sharePdfFromPath(String filePath) async {
    try {
      if (kIsWeb) {
        await Share.shareXFiles([XFile(filePath)], text: 'Gilgal Worship Songs');
      } else {
        final file = File(filePath);
        if (!await file.exists()) return false;
        await Share.shareXFiles([XFile(filePath)], text: 'Gilgal Worship Songs');
      }
      return true;
    } catch (e) {
      debugPrint('❌ PDF share error: $e');
      return false;
    }
  }
}

Future<Uint8List?> _buildPdfBytesOnWorker(Map<String, dynamic> payload) async {
  try {
    final rawSongs = (payload['songs'] as List<dynamic>? ?? const <dynamic>[])
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList(growable: false);
    if (rawSongs.isEmpty) return null;

    final regularFontBytes = payload['regularFont'] as Uint8List?;
    final boldFontBytes = payload['boldFont'] as Uint8List?;

    pw.Font regularFont;
    pw.Font boldFont;

    if (regularFontBytes != null && boldFontBytes != null) {
      regularFont = pw.Font.ttf(ByteData.sublistView(regularFontBytes));
      boldFont = pw.Font.ttf(ByteData.sublistView(boldFontBytes));
    } else {
      // Disabled: PdfGoogleFonts unavailable
      return null;
    }
    final pdf = pw.Document();

    for (int i = 0; i < rawSongs.length; i++) {
      final song = rawSongs[i];
      final title = _workerText(song['title'], fallback: 'Untitled');
      final lyrics = _workerText(
        song['lyrics'],
        fallback: 'No Telugu lyrics available\nYou can add them later',
      );
      final pageNumber = _workerPageNumber(song['pageNumber']);
      final category = _workerText(song['category']);

      // Match song_detail_screen: "Hymn #X" and optional category, then title
      final hymnLine =
          'Hymn #${pageNumber ?? "—"}${category.isNotEmpty ? '  -  $category' : ''}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          maxPages: 600,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          build: (_) => _workerSongWidgets(
            hymnLine: hymnLine,
            title: title,
            lyrics: lyrics,
            headingFont: boldFont,
            bodyFont: regularFont,
          ),
        ),
      );
    }

    return Uint8List.fromList(await pdf.save());
  } catch (e) {
    // Returning null lets caller switch to fast fallback without crashing.
    debugPrint('❌ Worker full PDF build failed: $e');
    return null;
  }
}

Future<Uint8List?> _buildFastPdfBytesOnWorker(
    Map<String, dynamic> payload) async {
  try {
    final rawSongs = (payload['songs'] as List<dynamic>? ?? const <dynamic>[])
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList(growable: false);
    if (rawSongs.isEmpty) return null;

    final pdf = pw.Document();
    final regularFontBytes = payload['regularFont'] as Uint8List?;
    final boldFontBytes = payload['boldFont'] as Uint8List?;

    pw.Font headingFont;
    pw.Font bodyFont;
    if (regularFontBytes != null && boldFontBytes != null) {
      bodyFont = pw.Font.ttf(ByteData.sublistView(regularFontBytes));
      headingFont = pw.Font.ttf(ByteData.sublistView(boldFontBytes));
    } else {
      // Disabled: PdfGoogleFonts unavailable
      return null;
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 600,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        build: (_) {
          final widgets = <pw.Widget>[];
          for (int i = 0; i < rawSongs.length; i++) {
            final song = rawSongs[i];
            final title = _workerText(song['title'], fallback: 'Untitled');
            final lyrics = _workerText(
              song['lyrics'],
              fallback: 'No Telugu lyrics available\nYou can add them later',
            );
            final pageNumber = _workerPageNumber(song['pageNumber']);
            final category = _workerText(song['category']);

            final hymnLine =
                'Hymn #${pageNumber ?? "—"}${category.isNotEmpty ? '  -  $category' : ''}';
            widgets.addAll(
              _workerSongWidgets(
                hymnLine: hymnLine,
                title: title,
                lyrics: lyrics,
                headingFont: headingFont,
                bodyFont: bodyFont,
              ),
            );
            widgets.add(pw.SizedBox(height: 12));
          }
          return widgets;
        },
      ),
    );

    return Uint8List.fromList(await pdf.save());
  } catch (e) {
    debugPrint('❌ Worker fast PDF build failed: $e');
    return null;
  }
}

String _workerText(dynamic value, {String fallback = ''}) {
  final text = value is String ? value : '';
  if (text.trim().isEmpty) return fallback;

  final out = StringBuffer();
  for (final rune in text.runes) {
    final isControl =
        rune < 0x20 && rune != 0x0A && rune != 0x0D && rune != 0x09;
    if (isControl) continue;
    if (rune == 0x09) {
      out.write('    ');
      continue;
    }
    if (rune == 0x2028 || rune == 0x2029) {
      out.write('\n');
      continue;
    }
    if (rune == 0xFEFF || rune == 0x200B) continue;
    out.writeCharCode(rune);
  }

  final normalized = out.toString();
  return normalized.isEmpty ? fallback : normalized;
}

int? _workerPageNumber(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

/// PDF layout now mirrors the simple preview shown from My List
/// (the eye icon dialog in `_SelectedSongItem`):
/// - Dialog title: `song.displayTitle` (bold)
/// - Body: `SelectableText(song.lyrics ?? 'No lyrics available', style: TextStyle(fontSize: 16))`
List<pw.Widget> _workerSongWidgets({
  required String hymnLine,
  required String title,
  required String lyrics,
  required pw.Font headingFont,
  required pw.Font bodyFont,
}) {
  // Match the SongDetailScreen Telugu tab text style as closely as possible:
  // - Title line
  // - Then the raw lyrics text, fontSize 18, height ~1.8, letterSpacing 0.3, left-aligned.
  const lyricsFontSize = 18.0;
  const lyricsLetterSpacing = 0.3;
  const gapAfterSong = 24.0;

  // Approximate Flutter's height: 1.8 for 18sp text:
  // line height = fontSize * 1.8 => extra spacing = 18*1.8 - 18 = 14.4
  const lyricsHeight = 1.8;
  final lyricLineSpacing = (lyricsFontSize * lyricsHeight) - lyricsFontSize;

  final normalizedLyrics =
      lyrics.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  const leftAlign = pw.TextAlign.left;

  // Split lyrics into smaller blocks so no single Text widget is taller
  // than a page (with 18sp, height 1.8). 18 lines per block keeps us well
  // under an A4 page height including title and margins.
  const maxLinesPerBlock = 18;
  final lines = normalizedLyrics.split('\n');
  final blocks = <String>[];
  var current = StringBuffer();
  var lineCount = 0;

  for (final line in lines) {
    if (lineCount >= maxLinesPerBlock) {
      blocks.add(current.toString().trimRight());
      current = StringBuffer();
      lineCount = 0;
    }
    current.writeln(line);
    lineCount++;
  }
  if (current.isNotEmpty) {
    blocks.add(current.toString().trimRight());
  }

  final widgets = <pw.Widget>[];

  // Title line, slightly larger than body
  widgets.add(
    pw.Text(
      title,
      textAlign: leftAlign,
      style: pw.TextStyle(
        font: headingFont,
        fontSize: 20,
      ),
    ),
  );
  widgets.add(pw.SizedBox(height: 8));

  // Lyrics blocks – rendered back-to-back so formatting matches in-app feel
  for (final block in blocks) {
    if (block.trim().isEmpty) continue;
    widgets.add(
      pw.Text(
        block,
        textAlign: leftAlign,
        style: pw.TextStyle(
          font: bodyFont,
          fontSize: lyricsFontSize,
          letterSpacing: lyricsLetterSpacing,
          lineSpacing: lyricLineSpacing,
        ),
      ),
    );
  }
  widgets.add(pw.SizedBox(height: gapAfterSong));

  return widgets;
}
