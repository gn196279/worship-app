import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

void main() async {
  print('Starting PDF parsing test...\n');
  
  try {
    // Read the PDF file
    final file = File(r'e:\list_of_songs\4th Jan 26_Sunday Songs.pdf');
    
    if (!await file.exists()) {
      print('Error: PDF file not found at ${file.path}');
      return;
    }
    
    print('Reading PDF file: ${file.path}');
    final bytes = await file.readAsBytes();
    print('File size: ${bytes.length} bytes\n');

    // Load PDF document using Syncfusion
    final syncfusion.PdfDocument document =
        syncfusion.PdfDocument(inputBytes: bytes);
    
    print('PDF loaded successfully!');
    print('Number of pages: ${document.pages.count}\n');

    // Extract text from all pages
    for (int i = 0; i < document.pages.count; i++) {
      print('=== PAGE ${i + 1} ===');
      final syncfusion.PdfTextExtractor extractor =
          syncfusion.PdfTextExtractor(document);
      String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      print(pageText);
      print('\n');
    }

    document.dispose();
    print('\n✓ PDF parsing completed successfully!');
    
  } catch (e, stackTrace) {
    print('Error parsing PDF: $e');
    print('Stack trace: $stackTrace');
  }
}
