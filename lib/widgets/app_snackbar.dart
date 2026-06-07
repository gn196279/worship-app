import 'package:flutter/material.dart';

enum AppSnackBarType { success, error, warning, info }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    bool replaceCurrent = true,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final visuals = _visualsFor(type, theme.colorScheme);

    if (replaceCurrent) {
      messenger.hideCurrentSnackBar();
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          decoration: BoxDecoration(
            color: visuals.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: visuals.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  theme.brightness == Brightness.dark ? 0.30 : 0.10,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: visuals.iconBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  visuals.icon,
                  size: 18,
                  color: visuals.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: visuals.textColor,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: visuals.actionColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool replaceCurrent = true,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackBarType.success,
      duration: duration,
      replaceCurrent: replaceCurrent,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool replaceCurrent = true,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackBarType.error,
      duration: duration,
      replaceCurrent: replaceCurrent,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool replaceCurrent = true,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackBarType.warning,
      duration: duration,
      replaceCurrent: replaceCurrent,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool replaceCurrent = true,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: AppSnackBarType.info,
      duration: duration,
      replaceCurrent: replaceCurrent,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static _SnackVisuals _visualsFor(AppSnackBarType type, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    Color accent;
    IconData icon;
    switch (type) {
      case AppSnackBarType.success:
        accent = Colors.green;
        icon = Icons.check_circle_rounded;
        break;
      case AppSnackBarType.error:
        accent = Colors.red;
        icon = Icons.error_rounded;
        break;
      case AppSnackBarType.warning:
        accent = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case AppSnackBarType.info:
        accent = scheme.primary;
        icon = Icons.info_rounded;
        break;
    }

    return _SnackVisuals(
      background: Color.alphaBlend(
        accent.withOpacity(isDark ? 0.28 : 0.12),
        scheme.surface,
      ),
      border: accent.withOpacity(isDark ? 0.56 : 0.34),
      iconBackground: accent.withOpacity(isDark ? 0.32 : 0.16),
      iconColor: accent,
      textColor: scheme.onSurface,
      actionColor: accent,
      icon: icon,
    );
  }
}

class _SnackVisuals {
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
  final Color textColor;
  final Color actionColor;
  final IconData icon;

  const _SnackVisuals({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
    required this.textColor,
    required this.actionColor,
    required this.icon,
  });
}
