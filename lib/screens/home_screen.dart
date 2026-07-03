import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../services/user_preferences_service.dart';
import '../providers/song_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/song.dart';
import '../utils/access_control.dart';
import 'upload_pdf_screen.dart';
import '../widgets/gilgal_style1_logo.dart';
import '../theme/app_colors.dart';
import 'selected_songs_screen.dart';
import 'song_detail_screen.dart';
import 'admin_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Drives both the clear button and content-area switch without setState
  final ValueNotifier<bool> _isSearchingNotifier = ValueNotifier(false);

  // Search history (last 5 queries)
  List<String> _searchHistory = [];

  late SongProvider _songProvider;
  final UserPreferencesService _prefsService = UserPreferencesService();
  bool _isGuest = false;
  bool _hasCleanedStaleFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadGuestMode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _songProvider = context.read<SongProvider>();
    // One-time: remove favorite IDs that no longer exist in the song list
    if (!_hasCleanedStaleFavorites && _songProvider.allSongs.isNotEmpty) {
      _hasCleanedStaleFavorites = true;
      final fp = context.read<FavoritesProvider>();
      final validIds = _songProvider.allSongs.map((s) => s.id).toSet();
      unawaited(fp.removeStaleIds(validIds));
    }
  }

  Future<void> _loadSearchHistory() async {
    final history = await _prefsService.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _loadGuestMode() async {
    final isGuest = await _prefsService.isGuestMode();
    if (!mounted) return;
    setState(() => _isGuest = isGuest);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _isSearchingNotifier.dispose();
    super.dispose();
  }

  AccessControl _accessFor(User? firebaseUser, [String? firestoreRole]) {
    return AccessControl.from(
      isGuestMode: firebaseUser == null && _isGuest,
      firestoreRole: firestoreRole,
    );
  }

  Future<void> _logoutGuest() async {
    await _prefsService.setGuestMode(false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _addToRecentSearches(String query) async {
    if (query.trim().isEmpty) return;
    await _prefsService.addSearchQuery(query);
    await _loadSearchHistory();
  }

  Future<void> _clearSearchHistory() async {
    await _prefsService.clearSearchHistory();
    setState(() {
      _searchHistory = [];
    });
  }

  void _handleSearch(String value) {
    _isSearchingNotifier.value = value.isNotEmpty;
    _songProvider.searchSongs(value);
  }

  List<TextSpan> _highlightMatches(String text, String query, ThemeData theme) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int lastIndex = 0;

    int index = lowerText.indexOf(lowerQuery);
    while (index != -1) {
      if (index > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      lastIndex = index + query.length;
      index = lowerText.indexOf(lowerQuery, lastIndex);
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  Widget _buildSuggestionTile(
    Song song,
    String searchQuery,
    AccessControl access,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongDetailScreen(
              song: song,
              access: access,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.description_outlined,
              color: theme.hintColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      children: _highlightMatches(
                          song.displayTitle, searchQuery, theme),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hymn #${song.pageNumber != null && song.pageNumber! > 0 ? song.pageNumber : "—"} • PDF available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearchChip(String query) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        _searchController.text = query;
        _isSearchingNotifier.value = true;
        _songProvider.searchSongs(query);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 12, right: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 20,
              color: theme.hintColor,
            ),
            const SizedBox(width: 8),
            Text(
              query,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
    bool showFavoritesCount = false,
    bool showSelectedCount = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (showFavoritesCount)
              Positioned(
                top: 8,
                right: 8,
                child: Selector2<SongProvider, FavoritesProvider, int>(
                  selector: (_, songProvider, fp) {
                    final songIds =
                        songProvider.allSongs.map((s) => s.id).toSet();
                    return fp.favoriteIds.intersection(songIds).length;
                  },
                  builder: (_, count, __) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (showSelectedCount)
              Positioned(
                top: 8,
                right: 8,
                child: Selector<SongProvider, int>(
                  selector: (_, provider) => provider.selectedSongs.length,
                  builder: (_, count, __) {
                    if (count <= 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use Selector to only rebuild when specific values change
    return Selector<SongProvider, ({bool isLoading, bool hasSongs})>(
      selector: (_, provider) => (
        isLoading: provider.isLoading,
        hasSongs: provider.allSongs.isNotEmpty,
      ),
      builder: (context, songData, _) {
        return Selector<AuthProvider, ({User? user, String? role})>(
          selector: (_, auth) => (
            user: auth.firebaseUser,
            role: auth.appUser?.role,
          ),
          builder: (context, authData, _) {
            return _buildMainContent(
              context,
              theme,
              isDark,
              songData,
              authData.user,
              authData.role,
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    ({bool isLoading, bool hasSongs}) songData,
    User? firebaseUser,
    String? firestoreRole,
  ) {
    final songsLoading = songData.isLoading;
    final hasSongs = songData.hasSongs;
    final auth = context.read<AuthProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final access = _accessFor(firebaseUser, firestoreRole);
    const primaryColor = AppColors.primary;
    const lightBackground = AppColors.lightBackground;
    const darkBackground = AppColors.darkBackground;

    // When app is first opened and songs are still loading,
    // show a clear full-screen loading state so it doesn't feel "stuck".
    if (songsLoading && !hasSongs) {
      return Scaffold(
        backgroundColor: isDark ? darkBackground : lightBackground,
        appBar: AppBar(
          backgroundColor:
              (isDark ? darkBackground : Colors.white).withOpacity(0.85),
          elevation: 0,
          title: const Text('Gilgal Worship App'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading songs…',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit ?? false) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? darkBackground : lightBackground,
        appBar: AppBar(
          backgroundColor:
              (isDark ? darkBackground : Colors.white).withOpacity(0.85),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 16,
          title: Row(
            children: [
              const GilgalStyle1Logo(size: 40, radius: 20),
              const SizedBox(width: 12),
              Text(
                'Gilgal Worship',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<int>(
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              icon: Icon(
                Icons.settings,
                color: isDark ? Colors.white70 : AppColors.lightText,
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(themeProvider.isDarkMode
                          ? 'Light mode'
                          : 'Dark mode'),
                    ],
                  ),
                ),
                if (auth.firebaseUser != null || _isGuest) ...[
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ],
              onSelected: (value) async {
                if (value == 0) {
                  themeProvider.toggleTheme();
                } else if (value == 1) {
                  if (auth.firebaseUser != null) {
                    unawaited(auth.signOut());
                  } else if (_isGuest) {
                    await _logoutGuest();
                  }
                }
              },
            ),
            if (auth.firebaseUser != null)
              PopupMenuButton<int>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.firebaseUser?.displayName ??
                              auth.firebaseUser?.email ??
                              'User',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          'Role: ${access.roleLabel}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    (() {
                      final raw = (auth.firebaseUser?.displayName ??
                              auth.firebaseUser?.email ??
                              'U')
                          .trim();
                      if (raw.isEmpty) return 'U';
                      return raw.substring(0, 1).toUpperCase();
                    })(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned(
                bottom: 48,
                right: 24,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: isDark ? 0.05 : 0.03,
                    child: Icon(
                      Icons.church,
                      size: 260,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? darkBackground : Colors.white,
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        // Search Bar (+ chord filter for musicians/admins)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFF0F2F5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 56,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1F2937)
                                              : const Color(0xFFF3F4F6),
                                          borderRadius:
                                              const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.search,
                                          color: primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: _handleSearch,
                                          onSubmitted: (value) {
                                            if (value.trim().isNotEmpty) {
                                              _addToRecentSearches(
                                                value.trim(),
                                              );
                                            }
                                          },
                                          style: theme.textTheme.bodyLarge,
                                          decoration: InputDecoration(
                                            hintText: access.canViewChords
                                                ? 'Search songs or filter chords…'
                                                : 'Search in Telugu or English...',
                                            hintStyle: theme
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.hintColor,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isSearchingNotifier,
                                        builder: (_, isSearching, __) {
                                          if (!isSearching) {
                                            return const SizedBox(width: 48);
                                          }
                                          return IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: theme.hintColor,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              _isSearchingNotifier.value =
                                                  false;
                                              _songProvider.searchSongs('');
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                if (access.canViewChords)
                                  Selector<SongProvider,
                                      ({bool on, int count})>(
                                    selector: (_, provider) => (
                                      on: provider.chordsOnlyFilter,
                                      count: provider.chordSongCount,
                                    ),
                                    builder: (context, data, _) {
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          10,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: FilterChip(
                                            avatar: Icon(
                                              Icons.music_note,
                                              size: 18,
                                              color: data.on
                                                  ? Colors.white
                                                  : primaryColor,
                                            ),
                                            label: Text(
                                              'Chords only (${data.count})',
                                              style: TextStyle(
                                                color: data.on
                                                    ? Colors.white
                                                    : theme.textTheme
                                                        .bodyMedium?.color,
                                              ),
                                            ),
                                            selected: data.on,
                                            selectedColor: primaryColor,
                                            checkmarkColor: Colors.white,
                                            side: BorderSide(
                                              color: data.on
                                                  ? primaryColor
                                                  : primaryColor
                                                      .withOpacity(0.35),
                                            ),
                                            onSelected: (selected) {
                                              _songProvider
                                                  .setChordsOnlyFilter(
                                                selected,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (auth.firebaseUser != null) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Signed in as ${auth.firebaseUser?.email ?? 'user'} '
                                      '• role: ${access.roleLabel}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Content: ValueListenableBuilder switches view instantly;
                        // inner Selector only rebuilds when results actually change.
                        Expanded(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _isSearchingNotifier,
                            builder: (context, isSearching, _) {
                              return Selector<SongProvider, bool>(
                                selector: (_, p) => p.chordsOnlyFilter,
                                builder: (context, chordsOnly, __) {
                                  final showSongList = isSearching ||
                                      (access.canViewChords && chordsOnly);
                                  if (showSongList) {
                                    return Selector<SongProvider, List<Song>>(
                                      selector: (_, p) => p.searchResults,
                                      builder: (context, results, _) =>
                                          _buildSearchResults(
                                        results,
                                        access,
                                        chordsOnly: chordsOnly,
                                      ),
                                    );
                                  }
                                  return _buildHomeContent();
                                },
                              );
                            },
                          ),
                        ),

                        // Bottom indicator
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            width: 128,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (songsLoading && hasSongs)
                Positioned.fill(
                  child: IgnorePointer(
                    // Keep the sync hint visible without blocking taps/scroll.
                    ignoring: true,
                    child: SafeArea(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF111827) : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Syncing latest songs…',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: Selector<SongProvider, List<Song>>(
          selector: (_, provider) => provider.selectedSongs,
          builder: (context, selectedSongs, _) {
            final access = _accessFor(firebaseUser, firestoreRole);
            if (!access.canUsePlaylist) return const SizedBox.shrink();
            if (selectedSongs.isEmpty) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectedSongsScreen(),
                  ),
                );
              },
              backgroundColor: theme.colorScheme.primary,
              icon: const Icon(Icons.playlist_play, size: 24),
              label: Text(
                '${selectedSongs.length} Selected',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    List<Song> results,
    AccessControl access, {
    bool chordsOnly = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = _searchController.text.trim();

    if (results.isEmpty) {
      final emptyMessage = query.isNotEmpty
          ? 'No songs found for "$query"'
          : chordsOnly
              ? 'No songs with chords found'
              : 'No songs found';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _isSearchingNotifier.value = false;
                if (chordsOnly) {
                  _songProvider.setChordsOnlyFilter(false);
                }
                _songProvider.searchSongs('');
              },
              child: Text(chordsOnly ? 'Clear filter' : 'Clear search'),
            ),
          ],
        ),
      );
    }

    final headerLabel = query.isNotEmpty
        ? 'SUGGESTIONS'
        : chordsOnly
            ? 'SONGS WITH CHORDS (${results.length})'
            : 'SUGGESTIONS';

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suggestions Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1a1f2e) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Text(
                    headerLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 11,
                    ),
                  ),
                ),
                ...results.map((song) =>
                    _buildSuggestionTile(song, _searchController.text, access)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Selector<AuthProvider, ({User? user, String? role})>(
      selector: (_, auth) => (
        user: auth.firebaseUser,
        role: auth.appUser?.role,
      ),
      builder: (context, authData, _) {
        return _buildHomeContentInner(
          context,
          theme,
          isDark,
          authData.user,
          authData.role,
        );
      },
    );
  }

  Widget _buildHomeContentInner(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    User? firebaseUser,
    String? firestoreRole,
  ) {
    final access = _accessFor(firebaseUser, firestoreRole);
    const primaryColor = AppColors.primary;

    // ── Sliver-based layout ─────────────────────────────────────────────────
    //
    // Previously we used SingleChildScrollView + Column + ListView(shrinkWrap:true).
    // shrinkWrap forces Flutter to BUILD AND LAY OUT ALL 700 songs at once to
    // compute the list height — completely defeating virtualisation and causing
    // Android ANR dialogs.
    //
    // CustomScrollView + SliverList only builds the ~20 items currently visible
    // on screen, reducing layout work by ~97 % and eliminating the ANR.
    return Selector<SongProvider, List<Song>>(
      selector: (_, p) => p.allSongs,
      // Guard: only rebuild when song length changes or when list boundaries
      // differ. Selection updates are handled by per-row selectors to avoid
      // rebuilding the whole list when one "add to playlist" icon is tapped.
      shouldRebuild: (prev, next) {
        if (prev.length != next.length) return true;
        if (identical(prev, next)) return false;
        final pa = prev;
        final na = next;
        if (pa.isNotEmpty &&
            (pa.first.id != na.first.id || pa.last.id != na.last.id)) {
          return true;
        }
        return false;
      },
      builder: (context, songs, _) {
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Recent Searches ──────────────────────────────────────────
            if (_searchHistory.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Searches',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _clearSearchHistory,
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _searchHistory
                        .take(5)
                        .map(_buildRecentSearchChip)
                        .toList(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],

            // ── Browse Categories ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  'Browse Categories',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (access.canUpload) ...[
                      Expanded(
                        child: _buildCategoryCard(
                          title: 'Add PDFs',
                          icon: Icons.file_upload,
                          iconColor: primaryColor,
                          bgColor: primaryColor.withOpacity(0.1),
                          onTap: () async {
                            await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadPDFScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _buildCategoryCard(
                        title: 'Favorites',
                        icon: Icons.favorite,
                        iconColor: Colors.orange,
                        bgColor: isDark
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.orange[50]!,
                        showFavoritesCount: true,
                        onTap: _showFavoritesBottomSheet,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (access.canManageRoles) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildCategoryCard(
                      title: 'Admin',
                      icon: Icons.admin_panel_settings,
                      iconColor: Colors.purple,
                      bgColor: isDark
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.purple[50]!,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            if (access.canUsePlaylist) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildCategoryCard(
                      title: 'My List (Playlist)',
                      icon: Icons.playlist_play,
                      iconColor: Colors.green,
                      bgColor: isDark
                          ? Colors.green.withOpacity(0.2)
                          : Colors.green[50]!,
                      showSelectedCount: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SelectedSongsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── All Songs ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'All Songs',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (songs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No songs yet',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ),
                ),
              )
            else
              // SliverList: only visible items (~20) are built at any time.
              // This replaces the old shrinkWrap ListView which built all 700.
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];

                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongDetailScreen(
                            song: song,
                            access: access,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: theme.dividerColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.music_note,
                                  color: theme.hintColor, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.displayTitle,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hymn #${song.pageNumber != null && song.pageNumber! > 0 ? song.pageNumber : "—"}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ),
                              _SongFavoriteButton(songId: song.id),
                              _SongSelectButton(
                                song: song,
                                access: access,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: songs.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  void _showFavoritesBottomSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.read<AuthProvider>();
    final access = _accessFor(auth.firebaseUser, auth.appUser?.role);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101622) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Favorite Songs',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Selector2<SongProvider, FavoritesProvider, List<Song>>(
                selector: (_, songProvider, favProvider) {
                  final favoriteIds = favProvider.favoriteIds;
                  if (favoriteIds.isEmpty) {
                    return const <Song>[];
                  }

                  final favoriteSongs = <Song>[];
                  for (final song in songProvider.allSongs) {
                    if (favoriteIds.contains(song.id)) {
                      favoriteSongs.add(song);
                    }
                  }
                  return favoriteSongs;
                },
                builder: (context, favoriteSongs, _) {
                  if (favoriteSongs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: theme.hintColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorite songs yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: favoriteSongs.length,
                    itemBuilder: (context, index) {
                      final song = favoriteSongs[index];

                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SongDetailScreen(
                                song: song,
                                access: access,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: theme.dividerColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.displayTitle,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hymn #${song.pageNumber != null && song.pageNumber! > 0 ? song.pageNumber : "—"}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _SongFavoriteButton(songId: song.id),
                              _SongSelectButton(
                                song: song,
                                access: access,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongSelectButton extends StatelessWidget {
  final Song song;
  final AccessControl access;

  const _SongSelectButton({
    required this.song,
    required this.access,
  });

  @override
  Widget build(BuildContext context) {
    if (!access.canUsePlaylist) return const SizedBox.shrink();

    return Selector<SongProvider, bool>(
      selector: (_, provider) => provider.isSelected(song.id),
      builder: (context, isSelected, _) {
        final hintColor = Theme.of(context).hintColor;
        return IconButton(
          icon: Icon(
            isSelected ? Icons.check_circle : Icons.add_circle_outline,
            color:
                isSelected ? Theme.of(context).colorScheme.primary : hintColor,
            size: 20,
          ),
          onPressed: () {
            final provider = context.read<SongProvider>();
            if (isSelected) {
              provider.removeFromSelected(song);
            } else {
              provider.addToSelected(song);
            }
          },
        );
      },
    );
  }
}

/// Self-contained favourite button that manages its own pop animation via
/// local [setState]. This means toggling a heart NEVER causes the 700-song
/// list to rebuild — only this tiny 48×48 icon repaints.
class _SongFavoriteButton extends StatefulWidget {
  final String songId;

  const _SongFavoriteButton({required this.songId});

  @override
  State<_SongFavoriteButton> createState() => _SongFavoriteButtonState();
}

class _SongFavoriteButtonState extends State<_SongFavoriteButton> {
  bool _isPopping = false;

  void _toggle() {
    final fp = context.read<FavoritesProvider>();
    final wasFavorite = fp.isFavorite(widget.songId);
    fp.toggle(widget.songId);
    if (!wasFavorite) {
      setState(() => _isPopping = true);
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _isPopping = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<FavoritesProvider, bool>(
      selector: (_, fp) => fp.isFavorite(widget.songId),
      builder: (context, isFavorite, _) {
        final hintColor = Theme.of(context).hintColor;
        return IconButton(
          onPressed: _toggle,
          icon: AnimatedScale(
            scale: _isPopping ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                key: ValueKey<bool>(isFavorite),
                color: isFavorite ? Colors.red : hintColor,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}
