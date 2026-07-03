import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/chord_pro_helper.dart';

/// ChordPro textarea with quick-insert chord chips and section snippets.
class ChordProEditor extends StatefulWidget {
  final TextEditingController controller;

  const ChordProEditor({
    super.key,
    required this.controller,
  });

  @override
  State<ChordProEditor> createState() => _ChordProEditorState();
}

class _ChordProEditorState extends State<ChordProEditor> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _insertAtCursor(String snippet) {
    final controller = widget.controller;
    final value = controller.value;
    final start = value.selection.start.clamp(0, value.text.length);
    final end = value.selection.end.clamp(0, value.text.length);
    final newText = value.text.replaceRange(start, end, snippet);
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + snippet.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chord chart (ChordPro)',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap a chord to insert at the cursor. Example: [G]దేవా [C]నీ',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ChordProHelper.commonChords.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final chord = ChordProHelper.commonChords[index];
              return ActionChip(
                label: Text(chord),
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                onPressed: () => _insertAtCursor('[$chord]'),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ChordProHelper.sectionSnippets.map((snippet) {
            return ActionChip(
              label: Text(
                snippet.replaceAll('{', '').replaceAll('}', ''),
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: () => _insertAtCursor('\n$snippet\n'),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
            hintText:
                '{title: Song name}\n{start_of_chorus: Chorus}\n[G]Lyrics with [C]chords inline',
            helperText:
                'Musicians see chords above lyrics. Singers can hide chords in the chart view.',
          ),
          maxLines: null,
          minLines: 12,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}
