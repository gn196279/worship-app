import 'package:flutter/material.dart';

import '../screens/welcome_screen.dart';

/// Prompts guest users to sign in with Google for restricted features.
Future<void> showLoginRequiredDialog(
  BuildContext context, {
  required String feature,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Sign in required'),
        content: Text(
          'Please sign in with Google to $feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              );
            },
            child: const Text('Sign in with Google'),
          ),
        ],
      );
    },
  );
}
