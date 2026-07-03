import 'package:custom_flutter_chord/custom_flutter_chord.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Renders ChordPro / inline-chord text with optional transpose and hide chords.
class ChordChartWidget extends StatefulWidget {
  final String chordProText;
  final bool allowTranspose;
  final bool allowToggleChords;
  final void Function(String chord)? onChordTap;

  const ChordChartWidget({
    super.key,
    required this.chordProText,
    this.allowTranspose = true,
    this.allowToggleChords = true,
    this.onChordTap,
  });

  @override
  State<ChordChartWidget> createState() => _ChordChartWidgetState();
}

class _ChordChartWidgetState extends State<ChordChartWidget> {
  int _transpose = 0;
  bool _showChords = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = widget.chordProText.trim();

    if (text.isEmpty) {
      return Center(
        child: Text(
          'No chord chart yet.\nEdit the song to add ChordPro text.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
      );
    }

    final lyricStyle = theme.textTheme.bodyLarge?.copyWith(
          fontSize: 18,
          height: 1.8,
          fontFamily: 'NotoSansTelugu',
          letterSpacing: 0.2,
          color: theme.textTheme.bodyLarge?.color,
        ) ??
        const TextStyle(fontSize: 18, height: 1.8);

    final chordStyle = TextStyle(
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.primary : theme.colorScheme.primary,
      fontFamily: 'Courier',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.allowTranspose || widget.allowToggleChords)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.allowToggleChords)
                  FilterChip(
                    label: Text(_showChords ? 'Hide chords' : 'Show chords'),
                    selected: _showChords,
                    onSelected: (v) => setState(() => _showChords = v),
                  ),
                if (widget.allowTranspose) ...[
                  IconButton(
                    tooltip: 'Transpose down',
                    onPressed: () => setState(() => _transpose--),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    _transpose == 0
                        ? 'Original key'
                        : 'Transpose: ${_transpose > 0 ? '+' : ''}$_transpose',
                    style: theme.textTheme.labelMedium,
                  ),
                  IconButton(
                    tooltip: 'Transpose up',
                    onPressed: () => setState(() => _transpose++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: LyricsRenderer(
              lyrics: text,
              textStyle: lyricStyle,
              chordStyle: chordStyle,
              showChord: _showChords,
              showText: true,
              transposeIncrement: _transpose,
              underlineChordSyllables: true,
              widgetPadding: 32,
              onTapChord: (chord) {
                widget.onChordTap?.call(chord.toString());
              },
            ),
          ),
        ),
      ],
    );
  }
}
