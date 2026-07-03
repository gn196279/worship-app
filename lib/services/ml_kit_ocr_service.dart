import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// On-device OCR for screenshot uploads (free, offline). Uses ML Kit Latin script.
class MlKitOcrService {
  TextRecognizer? _recognizer;

  TextRecognizer get _textRecognizer {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  Future<String> recognizeFromFile(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    final result = await _textRecognizer.processImage(inputImage);
    return result.text;
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}

/// Writes original + preprocessed PNGs for OCR; returns temp file paths.
Future<List<String>> writeOcrCandidateFiles(
  Uint8List bytes,
  img.Image Function(img.Image) preprocess,
) async {
  final tempDir = Directory.systemTemp;
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final paths = <String>[];

  final rawPath = '${tempDir.path}${Platform.pathSeparator}mlkit_raw_$stamp.png';
  await File(rawPath).writeAsBytes(bytes, flush: true);
  paths.add(rawPath);

  final decoded = img.decodeImage(bytes);
  if (decoded != null) {
    final processed = preprocess(decoded);
    final processedPath =
        '${tempDir.path}${Platform.pathSeparator}mlkit_proc_$stamp.png';
    await File(processedPath)
        .writeAsBytes(img.encodePng(processed), flush: true);
    paths.add(processedPath);
  }

  return paths;
}

Future<void> deleteTempFiles(Iterable<String> paths) async {
  for (final path in paths) {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
