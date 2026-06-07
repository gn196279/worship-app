# App Screen State Management & Performance Findings

## 1. HomeScreen
- Uses Provider for Song, Theme, Auth.
- Uses setState for search, favorites, filters.
- Heavy use of Consumer for song list, selected songs, favorites.
- Potential lag: search debounce, large song lists, frequent setState.

## 2. WelcomeScreen
- Uses Provider for Auth.
- Uses setState for sign-in loading.
- Simple UI, minimal lag.

## 3. SelectedSongsScreen
- Uses Consumer for SongProvider.
- All song selection, reorder, export handled by Provider.
- No setState, good separation.

## 4. UploadPDFScreen
- Uses Provider for SongProvider.
- Uses setState for upload progress.
- PDF/image parsing and saving handled by Provider.
- Potential lag: parsing large files, upload progress.

## 5. SongImportPreviewScreen
- Uses setState for editing song preview list.
- Song editing handled via navigation.
- Minimal lag unless editing many songs.

## 6. SongEditScreen
- Uses setState for form fields.
- Song update handled via navigation pop.
- Minimal lag.

## 7. SongDetailScreen
- Uses setState for toggling chords view.
- Share handled via package.
- Minimal lag.

## 8. SignUpScreen
- Uses Provider for Auth.
- Uses setState for form fields.
- Minimal lag.

## 9. SignInScreen
- Uses Provider for Auth.
- Uses setState for loading, OTP, email mode.
- Minimal lag.

## 10. AuthGate
- Uses Consumer for AuthProvider.
- Handles loading, auth state.
- Minimal lag.

## 11. UnderConstructionScreen
- Stateless, no lag.

---

**Summary:**
- Provider is used for global state (songs, auth, theme).
- setState is used for local UI state (loading, toggles, form fields).
- Most screens are well-separated, but HomeScreen and UploadPDFScreen may lag with large data or frequent updates.

**Recommendation:**
- For best performance, consider using more granular Consumers or selectors, avoid setState for large lists, and use async operations efficiently.
- If lag persists, consider advanced state management (e.g., Riverpod, Bloc) for heavy screens.

---

_Last reviewed: Feb 7, 2026_
