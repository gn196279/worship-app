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
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

import '../config/google_vision_config.dart';
import '../models/import_parse_result.dart';
import '../models/song.dart';
import '../services/ml_kit_ocr_service.dart';
import '../services/song_import_parser.dart';
import '../utils/chord_pro_helper.dart';

class PDFService {
  // ============================================================
  // GOOGLE CLOUD VISION API CONFIGURATION
  // ============================================================

  // Provide via --dart-define=GCV_API_KEY=...
  static String get _googleCloudApiKey => GoogleVisionConfig.apiKey;
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

  /// Uniform render size for PDF → image OCR (keeps aspect ratio, high DPI).
  (double width, double height) _ocrRenderSize(double pageWidth, double pageHeight) {
    const minLongEdge = 1800.0;
    const maxLongEdge = 3200.0;
    const scaleFactor = 3.5;

    var w = pageWidth * scaleFactor;
    var h = pageHeight * scaleFactor;

    final longEdge = w > h ? w : h;
    final shortEdge = w > h ? h : w;

    if (longEdge > maxLongEdge) {
      final factor = maxLongEdge / longEdge;
      w *= factor;
      h *= factor;
    } else if (longEdge < minLongEdge) {
      final factor = minLongEdge / longEdge;
      w *= factor;
      h *= factor;
    }

    // Never upscale the short edge past the long-edge cap (avoids skew).
    if (shortEdge > 0 && (w > maxLongEdge || h > maxLongEdge)) {
      final factor = maxLongEdge / (w > h ? w : h);
      w *= factor;
      h *= factor;
    }

    return (w, h);
  }

  static final RegExp _teluguScript = RegExp(r'[\u0C00-\u0C7F]');

  /// True only when a page has no usable embedded text (then try Vision OCR).
  bool _embeddedTextNeedsOcr(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed.length < 12) return true;
    return false;
  }

  double _ocrTextQualityScore(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;

    var telugu = 0;
    var usefulLatin = 0;
    var junk = 0;
    for (final rune in trimmed.runes) {
      if (rune >= 0x0C00 && rune <= 0x0C7F) {
        telugu++;
      } else if (rune == 0x0A || rune == 0x0D || rune == 0x20) {
        continue;
      } else if ((rune >= 0x41 && rune <= 0x5A) ||
          (rune >= 0x61 && rune <= 0x7A) ||
          (rune >= 0x30 && rune <= 0x39) ||
          rune == 0x23 ||
          rune == 0x2F ||
          rune == 0x2D ||
          rune == 0x28 ||
          rune == 0x29) {
        usefulLatin++;
      } else {
        junk++;
      }
    }

    final total = trimmed.runes.length;
    if (total == 0) return 0;
    return (telugu + usefulLatin * 0.25) / total - (junk / total) * 2;
  }

  img.Image _preprocessForOcr(img.Image source, {bool photoCapture = false}) {
    var processed = source.clone();

    if (photoCapture) {
      processed = img.grayscale(processed);
      final avg = _averageLuminance(processed);
      if (avg < 120) {
        processed = img.invert(processed);
      }
    }

    // Cloud Vision works better when the long edge is at least ~1800px.
    final longEdge =
        processed.width > processed.height ? processed.width : processed.height;
    if (longEdge < 1800) {
      final scale = 1800 / longEdge;
      processed = img.copyResize(
        processed,
        width: (processed.width * scale).toInt(),
        height: (processed.height * scale).toInt(),
        interpolation: img.Interpolation.cubic,
      );
    }

    if (photoCapture) {
      processed = img.adjustColor(processed, contrast: 1.2, brightness: 1.05);
    }

    return processed;
  }


  String _parseGoogleErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        final err = json['error'];
        if (err is Map && err['message'] is String) {
          return err['message'] as String;
        }
      }
    } catch (_) {}
    return body.length > 200 ? '${body.substring(0, 200)}...' : body;
  }

  String _friendlyVisionHttpError(int statusCode, String body) {
    final googleMsg = _parseGoogleErrorMessage(body);
    final lower = '$googleMsg ${body.toLowerCase()}';

    if (lower.contains('billing') || lower.contains('enable billing')) {
      return 'Vision API needs billing enabled on your Google Cloud project.\n\n'
          'Console → Billing → link a billing account to my-worship-app-2cf1e '
          '(free \$300 trial credit is fine).\n\n'
          'Google says: $googleMsg';
    }

    if (lower.contains('has not been used') ||
        lower.contains('is disabled') ||
        lower.contains('access not configured') ||
        lower.contains('service disabled')) {
      return 'Cloud Vision API is not enabled yet.\n\n'
          'Open API Library and click ENABLE for Cloud Vision API on project '
          'my-worship-app-2cf1e.\n\n'
          'Google says: $googleMsg';
    }

    if (statusCode == 400 &&
        (lower.contains('api key not valid') || lower.contains('invalid api key'))) {
      return 'Invalid API key in this APK.\n\n'
          'Make sure secrets.json has the same key as "Gilgal OCR" in Google Cloud, '
          'then rebuild: tools/build_android_release.ps1\n\n'
          'Google says: $googleMsg';
    }

    if (statusCode == 403 && lower.contains('android') && lower.contains('blocked')) {
      return 'API key Android restriction is blocking this app.\n\n'
          'Set Application restrictions to None (keep API restriction: Cloud Vision only).\n\n'
          'Google says: $googleMsg';
    }

    return 'Vision API error (HTTP $statusCode).\n\nGoogle says: $googleMsg';
  }

  String _friendlyVisionException(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection')) {
      return 'No internet connection. Vision OCR needs network access.';
    }
    return 'Vision OCR failed: $error';
  }

  String? _extractVisionText(Map<String, dynamic> response) {
    final fullText = response['fullTextAnnotation'];
    if (fullText is Map && fullText['text'] is String) {
      final text = (fullText['text'] as String).trim();
      if (text.isNotEmpty) return text;
    }

    final textAnnotations = response['textAnnotations'];
    if (textAnnotations is List && textAnnotations.isNotEmpty) {
      final first = textAnnotations.first;
      if (first is Map && first['description'] is String) {
        final text = (first['description'] as String).trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  Future<({String text, String? error})> _performCloudVisionOcrBytes(
    Uint8List imageBytes,
  ) async {
    if (!GoogleVisionConfig.isConfigured) {
      return (
        text: '',
        error: 'Vision API key missing in this build.\n\n'
            'Rebuild with secrets.json (tools/build_android_release.ps1).',
      );
    }

    final base64Image = base64Encode(imageBytes);
    try {
      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1},
            ],
            'imageContext': {
              'languageHints': ['te', 'en'],
            },
          },
        ],
      };

      final response = await http.post(
        Uri.parse('$_visionApiUrl?key=$_googleCloudApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ Cloud Vision API Error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return (
          text: '',
          error: _friendlyVisionHttpError(response.statusCode, response.body),
        );
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final responses = jsonResponse['responses'];
      if (responses is! List || responses.isEmpty) {
        return (text: '', error: 'Vision API returned an empty response.');
      }

      final first = responses.first;
      if (first is! Map<String, dynamic>) {
        return (text: '', error: 'Vision API returned unexpected data.');
      }

      final error = first['error'];
      if (error is Map && error['message'] is String) {
        debugPrint('❌ Cloud Vision error: ${error['message']}');
        return (
          text: '',
          error: _friendlyVisionHttpError(
            error['code'] is int ? error['code'] as int : 403,
            jsonEncode({'error': error}),
          ),
        );
      }

      final text = _extractVisionText(first) ?? '';
      if (text.isEmpty) {
        return (
          text: '',
          error: 'No text detected in the image. Use a clear, full-page screenshot.',
        );
      }
      return (text: text, error: null);
    } catch (e) {
      debugPrint('❌ Cloud Vision OCR error: $e');
      return (text: '', error: _friendlyVisionException(e));
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
  // IMAGE PICKER (OCR) - ON-DEVICE ML KIT
  // ============================================================

  Future<ImportParseResult> parseImagesToSongs() async {
    final mlKit = MlKitOcrService();
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();

      if (images.isEmpty) {
        return const ImportParseResult(songs: []);
      }

      final songs = <Song>[];
      String? lastError;

      for (int i = 0; i < images.length; i++) {
        debugPrint('🔍 ML Kit OCR image ${i + 1}/${images.length}...');

        final bytes = await images[i].readAsBytes();
        final tempPaths = await writeOcrCandidateFiles(
          bytes,
          (source) => _preprocessForOcr(source, photoCapture: true),
        );

        var bestText = '';
        var bestScore = 0.0;

        try {
          for (final path in tempPaths) {
            final raw = await mlKit.recognizeFromFile(path);
            final cleaned = _cleanupOcrText(raw);
            final score = _ocrTextQualityScore(cleaned);
            debugPrint(
              '📊 ML Kit score ${score.toStringAsFixed(2)} '
              '(${cleaned.length} chars) — $path',
            );
            if (score > bestScore) {
              bestScore = score;
              bestText = cleaned;
            }
          }
        } finally {
          await deleteTempFiles(tempPaths);
        }

        debugPrint(
          '📄 Extracted ${bestText.length} characters from image ${i + 1}',
        );

        if (bestText.isEmpty) {
          lastError =
              'No text detected in image ${i + 1}. '
              'Use a clear full-page screenshot with lyrics and chords.';
          continue;
        }

        songs.add(
          SongImportParser.fromExtractedText(
            rawText: bestText,
            id: 'song_img_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: SongImportParser.inferTitleFromText(bestText),
            pageNumber: i + 1,
            category: 'Worship',
          ),
        );
      }

      debugPrint('✅ ML Kit parsed ${songs.length} images');
      return ImportParseResult(
        songs: songs,
        errorMessage: songs.isEmpty ? lastError : null,
      );
    } catch (e) {
      debugPrint('❌ Image parsing error: $e');
      return ImportParseResult(
        songs: [],
        errorMessage: 'Image OCR failed: $e',
      );
    } finally {
      await mlKit.dispose();
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
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final picked = result.files.single;
      Uint8List bytes;
      String? filePath = picked.path;

      if (picked.bytes != null && picked.bytes!.isNotEmpty) {
        bytes = picked.bytes!;
      } else if (filePath != null) {
        bytes = await File(filePath).readAsBytes();
      } else {
        debugPrint('❌ PDF picker returned no bytes or path');
        return [];
      }

      final document = syncfusion.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      final importId = DateTime.now().millisecondsSinceEpoch;

      debugPrint('📖 PDF has $pageCount pages');

      final songs = <Song>[];

      pdfx.PdfDocument? visionDoc;
      if (GoogleVisionConfig.isConfigured && filePath != null) {
        try {
          visionDoc = await pdfx.PdfDocument.openFile(filePath);
        } catch (e) {
          debugPrint('⚠️ Could not open PDF for Vision rendering: $e');
        }
      }

      try {
        for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
          final extractor = syncfusion.PdfTextExtractor(document);
          var pageText = extractor
              .extractText(
                startPageIndex: pageIndex,
                endPageIndex: pageIndex,
              )
              .trim();

          // Only OCR when embedded text is missing — never discard good PDF text.
          if (_embeddedTextNeedsOcr(pageText) && visionDoc != null) {
            debugPrint(
              '⚠️ Page ${pageIndex + 1}: no embedded text — trying Vision OCR...',
            );
            final ocrText = await _ocrPdfPageFromDoc(visionDoc, pageIndex);
            if (ocrText.isNotEmpty) {
              pageText = ocrText;
            }
          } else if (_embeddedTextNeedsOcr(pageText)) {
            debugPrint(
              '⚠️ Page ${pageIndex + 1}: no embedded text (Vision unavailable)',
            );
          }

          if (pageText.isEmpty) {
            debugPrint('⚠️ Page ${pageIndex + 1}: no text after OCR, skipping');
            continue;
          }

          debugPrint(
            '📄 Page ${pageIndex + 1}: ${pageText.length} characters extracted',
          );

          songs.add(
            SongImportParser.fromExtractedText(
              rawText: pageText,
              id: 'import_${importId}_p${pageIndex + 1}',
              title: _inferPdfPageTitle(pageText),
              pageNumber: pageIndex + 1,
              category: 'Worship',
            ),
          );
        }
      } finally {
        await visionDoc?.close();
      }

      document.dispose();

      debugPrint('✅ Extracted ${songs.length} songs from PDF');
      return songs;
    } catch (e) {
      debugPrint('❌ PDF parsing error: $e');
      return [];
    }
  }

  /// Render a PDF page to a high-res image and run Google Cloud Vision OCR.
  Future<String> _ocrPdfPageFromDoc(
    pdfx.PdfDocument doc,
    int pageIndex,
  ) async {
    if (!GoogleVisionConfig.isConfigured) {
      debugPrint('Vision API key not configured for PDF OCR');
      return '';
    }

    pdfx.PdfPage? page;
    try {
      page = await doc.getPage(pageIndex + 1);
      final (renderWidth, renderHeight) =
          _ocrRenderSize(page.width, page.height);

      debugPrint(
        '🖼️ Page ${pageIndex + 1} render: '
        '${renderWidth.toInt()}×${renderHeight.toInt()} px',
      );

      final pageImage = await page.render(
        width: renderWidth,
        height: renderHeight,
        format: pdfx.PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
        forPrint: true,
      );
      if (pageImage == null) {
        debugPrint('❌ Page ${pageIndex + 1}: render returned null');
        return '';
      }

      final rawBytes = pageImage.bytes;
      final rawOcr = await _performCloudVisionOcrBytes(rawBytes);
      var cleanedText = _cleanupOcrText(rawOcr.text);

      // Upscale-only pass for small renders; skip heavy photo filters on PDFs.
      final decoded = img.decodeImage(rawBytes);
      if (decoded != null) {
        final upscaled = _preprocessForOcr(decoded, photoCapture: false);
        final upscaledBytes = Uint8List.fromList(img.encodePng(upscaled));
        final upscaledOcr = await _performCloudVisionOcrBytes(upscaledBytes);
        final upscaledText = _cleanupOcrText(upscaledOcr.text);

        if (_ocrTextQualityScore(upscaledText) >
            _ocrTextQualityScore(cleanedText) + 0.05) {
          cleanedText = upscaledText;
        }
      }

      return cleanedText;
    } catch (e) {
      debugPrint('❌ PDF page OCR error (page ${pageIndex + 1}): $e');
      return '';
    } finally {
      await page?.close();
    }
  }

  String _inferPdfPageTitle(String pageText) {
    final chordLine = RegExp(
      r'^(?:N\.?C\.?|[A-Ga-g][#b]?(?:m|maj|min|sus|add|dim|aug)?(?:[0-9]+)?(?:/[A-Ga-g][#b]?)?)(?:\s+(?:N\.?C\.?|[A-Ga-g][#b]?(?:m|maj|min|sus|add|dim|aug)?(?:[0-9]+)?(?:/[A-Ga-g][#b]?)?))+$',
    );

    for (final line in pageText.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (RegExp(r'^\[?(Chorus|Verse|Pallavi|Intro|Bridge)\s*\d*\]?$',
              caseSensitive: false)
          .hasMatch(trimmed)) {
        continue;
      }
      if (chordLine.hasMatch(trimmed.replaceAll(RegExp(r'\s+'), ' '))) {
        continue;
      }

      var title = trimmed.replaceAll(RegExp(r'^\d+[\.\)]\s*'), '').trim();
      title = title.replaceAll(RegExp(r'\s*-\s*Capo\s+\d+.*$'), '').trim();
      title = title.replaceAll(
        RegExp(r'\s*-\s*[A-Ga-g][#b]?(?:m|maj|min)?(?:\s*\([^)]*\))?\s*$'),
        '',
      ).trim();
      if (title.isNotEmpty) {
        return title.length > 80 ? '${title.substring(0, 80)}...' : title;
      }
    }
    return 'Untitled';
  }

  // ============================================================
  // EXPORT SELECTED SONGS TO PDF (Telugu-friendly format)
  // Uses bundled Noto Sans Telugu for correct rendering.
  // ============================================================

  /// Telugu lyrics for PDF — matches the in-app lyrics tab, not raw DB text.
  String _teluguLyricsForExport(Song song) {
    final display = song.displayLyrics.trim();
    if (display.isNotEmpty && !song.usesBookletLyricsFallback) {
      return display;
    }
    final stripped =
        ChordProHelper.stripChords(song.effectiveChordProText).trim();
    if (stripped.length >= 24) return stripped;
    if (display.isNotEmpty) return display;
    return 'No Telugu lyrics available';
  }

  Map<String, dynamic> _songExportPayload(Song song) {
    return {
      'title': song.displayTitle,
      'lyrics': _teluguLyricsForExport(song),
      'lyricsEnglish': song.lyricsEnglish?.trim() ?? '',
      'pageNumber': song.pageNumber,
      'category': song.category ?? '',
    };
  }

  Future<String?> createPDFFromSongs(List<Song> songs) async {
    if (songs.isEmpty) return null;
    final path = await _createPDFFromSongsInBackground(songs);
    if (path != null) return path;
    return _createFastPDFFromSongsInBackground(songs);
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
        for (final song in songs) _songExportPayload(song),
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
        for (final song in songs) _songExportPayload(song),
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
        fallback: 'No Telugu lyrics available',
      );
      final lyricsEnglish = _workerText(song['lyricsEnglish']);
      final pageNumber = _workerPageNumber(song['pageNumber']);
      final category = _workerText(song['category']);

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
            lyricsEnglish: lyricsEnglish,
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
              fallback: 'No Telugu lyrics available',
            );
            final lyricsEnglish = _workerText(song['lyricsEnglish']);
            final pageNumber = _workerPageNumber(song['pageNumber']);
            final category = _workerText(song['category']);

            final hymnLine =
                'Hymn #${pageNumber ?? "—"}${category.isNotEmpty ? '  -  $category' : ''}';
            widgets.addAll(
              _workerSongWidgets(
                hymnLine: hymnLine,
                title: title,
                lyrics: lyrics,
                lyricsEnglish: lyricsEnglish,
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

/// PDF layout mirrors [SongDetailScreen]: hymn line, title, Telugu lyrics,
/// optional English lyrics — using Noto Sans Telugu (no letterSpacing).
List<pw.Widget> _workerSongWidgets({
  required String hymnLine,
  required String title,
  required String lyrics,
  required String lyricsEnglish,
  required pw.Font headingFont,
  required pw.Font bodyFont,
}) {
  const lyricsFontSize = 18.0;
  const gapAfterSong = 24.0;
  const lyricsHeight = 1.8;
  final lyricLineSpacing = (lyricsFontSize * lyricsHeight) - lyricsFontSize;

  final normalizedLyrics =
      lyrics.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  const leftAlign = pw.TextAlign.left;

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

  widgets.add(
    pw.Text(
      hymnLine,
      textAlign: leftAlign,
      style: pw.TextStyle(
        font: bodyFont,
        fontSize: 12,
        color: PdfColors.grey700,
      ),
    ),
  );
  widgets.add(pw.SizedBox(height: 6));

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
  widgets.add(pw.SizedBox(height: 10));

  for (final block in blocks) {
    if (block.trim().isEmpty) continue;
    widgets.add(
      pw.Text(
        block,
        textAlign: leftAlign,
        style: pw.TextStyle(
          font: bodyFont,
          fontSize: lyricsFontSize,
          lineSpacing: lyricLineSpacing,
        ),
      ),
    );
  }

  if (lyricsEnglish.trim().isNotEmpty) {
    widgets.add(pw.SizedBox(height: 14));
    widgets.add(
      pw.Text(
        'English',
        textAlign: leftAlign,
        style: pw.TextStyle(
          font: headingFont,
          fontSize: 14,
          color: PdfColors.grey800,
        ),
      ),
    );
    widgets.add(pw.SizedBox(height: 6));
    widgets.add(
      pw.Text(
        lyricsEnglish.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
        textAlign: leftAlign,
        style: pw.TextStyle(
          font: bodyFont,
          fontSize: lyricsFontSize,
          lineSpacing: lyricLineSpacing,
        ),
      ),
    );
  }

  widgets.add(pw.SizedBox(height: gapAfterSong));

  return widgets;
}
