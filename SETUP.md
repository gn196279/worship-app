# Setup Guide for Gilgal Telugu Worship App

## ✅ Setup Complete!

Your Flutter project has been successfully set up with all required files and dependencies.

## 📁 Project Structure Created

```
Gilgal_telugu_worship/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── song.dart
│   │   └── song.g.dart (generated)
│   ├── providers/
│   │   └── song_provider.dart
│   ├── screens/
│   │   └── home_screen.dart
│   ├── services/
│   │   └── pdf_service.dart
│   └── widgets/
│       ├── search_bar_widget.dart
│       ├── song_list_widget.dart
│       └── selected_songs_widget.dart
├── pubspec.yaml
├── analysis_options.yaml
├── .gitignore
└── README.md
```

## 🚀 Next Steps

### 1. Run the App

```bash
flutter run
```

Or press `F5` in VS Code to start debugging.

### 2. Choose Your Device

- For **Windows Desktop**: Run on Windows
- For **Android**: Connect an Android device or start an emulator
- For **Web**: Run in Chrome

### 3. Test the Features

1. **Upload PDF**: Click the upload icon (top right) to select a PDF file
2. **Search Songs**: Use the search bar to find songs
3. **Select Songs**: Click on songs to add them to the selected list
4. **Reorder**: Drag songs in the selected list to reorder
5. **Export PDF**: Click the PDF icon to export selected songs

## 📦 Installed Packages

- **provider**: State management
- **hive & hive_flutter**: Fast local storage
- **file_picker**: Pick PDF files
- **pdf**: Create PDFs
- **printing**: Share/print PDFs
- **syncfusion_flutter_pdf**: Parse PDF files
- **path_provider**: File system paths
- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication
- **cloud_firestore**: Firestore database
- **firebase_storage**: File storage
- **google_sign_in**: Google auth helper
- **flutter_facebook_auth**: Facebook login

## 🔧 Build Commands

### Generate Hive Adapters (after model changes)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Update Dependencies
```bash
flutter pub upgrade
```

### Clean Build
```bash
flutter clean
flutter pub get
```

## 📝 Important Notes

### PDF Parsing
The PDF parser in `pdf_service.dart` uses basic text extraction. You may need to customize the parsing logic based on your actual PDF structure:

- Modify the `parsePDFToSongs()` method
- Adjust title extraction logic
- Update song separation logic

### Firebase Setup (Required for Auth/Cloud features)
1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```
2. Configure Firebase for this app:
```bash
flutterfire configure
```
3. This generates the native config files (Android/iOS/Web) and links them
   to the Firebase project. After that, run:
```bash
flutter pub get
```

### Firestore Rules Deployment
If you want to enforce the rules in `firestore.rules`:
```bash
firebase deploy --only firestore:rules
```

### Facebook Login Setup
1. Create a Facebook App in Meta for Developers.
2. Enable Facebook Login for Android/iOS/Web.
3. Replace the placeholders in:
   - `android/app/src/main/res/values/strings.xml`
   - `ios/Runner/Info.plist`
4. Add your Android package name and iOS bundle ID in Facebook settings.

### Chords Import (CSV)
If you have chord sheets in CSV format:
```bash
python tools/import_chords_from_csv.py chords.csv
```
CSV columns: `id` or `title`, plus `chords`.

### Telugu Font Support
For better Telugu text rendering in exported PDFs:

1. Download a Telugu font (e.g., Noto Sans Telugu)
2. Add it to `assets/fonts/` directory
3. Update `pubspec.yaml` to include font assets
4. The app already uses `PdfGoogleFonts.notoSansTeluguRegular()` for Telugu support

### Performance Tips
- Hive is already optimized for fast read/write
- Search uses in-memory filtering for instant results
- PDF generation happens asynchronously

## 🐛 Troubleshooting

### If build fails:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### If Hive errors occur:
Make sure adapters are generated and registered in `main.dart`

### If PDF upload doesn't work:
Check file permissions on your device/platform

## 📱 Platform-Specific Setup

### Android
No additional setup required.

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Need to access photo library to pick PDFs</string>
```

### Windows
Works out of the box!

## 🎯 Features Implemented

✅ PDF upload and parsing  
✅ Local JSON storage (Hive)  
✅ Fast search with hints  
✅ Add/remove songs from list  
✅ Reorderable song list  
✅ Export selected songs as PDF  
✅ Optimized performance  
✅ Material Design UI  

## 💡 Tips

- Use keyboard shortcuts in search
- Long-press song cards for quick actions
- Reorder songs by dragging
- Clear all selected songs with one click

---

**Ready to run!** Press F5 or run `flutter run` in terminal.
