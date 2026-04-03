import 'package:flutter/material.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';

class AppFeedback {
  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    SuccessSnackbar.show(context, message: message, duration: duration);
  }

  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    ErrorSnackbar.show(context, message: message, duration: duration);
  }

  static void info(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _BaseSnackbar.show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColorResolver: (theme) => theme.colorScheme.secondary,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _BaseSnackbar.show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColorResolver: (_) => ArcticTheme.arcticWarning,
      duration: duration,
    );
  }
}

class _BaseSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color Function(ThemeData theme) iconColorResolver,
    required Duration duration,
  }) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? ArcticTheme.arcticCard;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColorResolver(theme)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        duration: duration,
        backgroundColor: cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class SuccessSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _BaseSnackbar.show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColorResolver: (theme) => theme.colorScheme.primary,
      duration: duration,
    );
  }
}

class ErrorSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _BaseSnackbar.show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColorResolver: (theme) => theme.colorScheme.error,
      duration: duration,
    );
  }
}
