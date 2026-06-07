import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shown from the very first frame while Hive/Firebase init. Prevents "app stuck" feeling.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 56,
                color: AppColors.primary.withOpacity(0.9),
              ),
              const SizedBox(height: 20),
              Text(
                'Gilgal Worship',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading…',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
