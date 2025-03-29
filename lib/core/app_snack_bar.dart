import 'package:flutter/material.dart';

class AppSnackBar {
  static showErrorMessage(String message, BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onErrorContainer,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static showSuccessMessage(String message, BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        showCloseIcon: true,
        closeIconColor: Theme.of(context).colorScheme.onPrimaryContainer,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
