# Gilgal Telugu Worship Songs App

A Flutter application for managing Telugu worship songs with PDF parsing and export capabilities.

## Features

- 📄 **PDF Upload**: Upload PDF files containing song lists
- 🔍 **Smart Search**: Fast search functionality with text hints
- ✅ **Song Selection**: Add songs to a custom list
- 📱 **Reorderable List**: Drag and drop to reorder selected songs
- 📥 **PDF Export**: Download selected songs as a single PDF
- 💾 **Local Storage**: Uses Hive for optimized local data storage
- ⚡ **High Performance**: Optimized for fast operations

## Tech Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Local Database**: Hive
- **PDF Handling**: Syncfusion Flutter PDF, pdf, printing
- **File Picking**: file_picker

## Setup Instructions

### Prerequisites

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)

### Installation

1. Clone the repository or navigate to the project directory

2. Install dependencies:
```bash
flutter pub get
```

3. Generate Hive adapters:
```bash
flutter pub run build_runner build
```

4. Run the app:
```bash
flutter run
```

## Usage

### Uploading Songs

1. Click the **Upload** icon in the app bar
2. Select a PDF file containing your song list
3. The app will parse and extract songs automatically

### Searching Songs

1. Use the search bar to find songs by title or lyrics
2. Search results update in real-time as you type

### Managing Selected Songs

1. Click on any song from the search results to add it to your selection
2. Selected songs appear in the right panel
3. Drag and drop songs to reorder them
4. Click the remove icon to delete a song from the selection

### Exporting to PDF

1. Select the songs you want to export
2. Click the **PDF** icon in the app bar
3. The app will generate and share a PDF with your selected songs

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── song.dart            # Song model
│   └── song.g.dart          # Generated Hive adapter
├── providers/
│   └── song_provider.dart   # State management
├── screens/
│   └── home_screen.dart     # Main screen
├── services/
│   └── pdf_service.dart     # PDF parsing and generation
└── widgets/
    ├── search_bar_widget.dart
    ├── song_list_widget.dart
    └── selected_songs_widget.dart
```

## Performance Optimizations

- Hive for fast local storage
- Efficient search with filtered lists
- Minimal widget rebuilds with Provider
- Lazy loading of song data
- Optimized PDF parsing

## License

This project is licensed for personal and church use.
