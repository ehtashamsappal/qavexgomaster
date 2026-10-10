/// Shared UI helpers for consistent styling across screens.
library;

import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

/// Returns the effective theme, applying the high-contrast override.
GoTheme effectiveTheme(GoTheme t, {required bool highContrast}) {
  if (!highContrast) return t;
  return GoTheme(
    id: t.id,
    name: t.name,
    tagline: t.tagline,
    priceCoins: t.priceCoins,
    board: const Color(0xFFFFFFFF),
    line: const Color(0xFF000000),
    blackStone: const Color(0xFF000000),
    whiteStone: const Color(0xFFFFFFFF),
    accent: const Color(0xFFFFD600),
    background: const Color(0xFF000000),
  );
}

class QgmScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final GoTheme theme;
  final Widget? floatingActionButton;

  const QgmScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.theme,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        foregroundColor: theme.onBackground,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class QgmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final GoTheme theme;
  final bool secondary;

  const QgmButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.theme,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = secondary ? theme.surface : theme.accent;
    final fg = secondary
        ? theme.onBackground
        : (theme.accent.computeLuminance() > 0.4
            ? GoTheme.ink
            : Colors.white);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        child: Text(label),
      ),
    );
  }
}

class QgmCard extends StatelessWidget {
  final Widget child;
  final GoTheme theme;
  final VoidCallback? onTap;

  const QgmCard({
    super.key,
    required this.child,
    required this.theme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final GoTheme theme;

  const SectionTitle(this.text, this.theme, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          color: theme.onBackground,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CoinPill extends StatelessWidget {
  final int coins;
  final GoTheme theme;

  const CoinPill({super.key, required this.coins, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(
              color: theme.onBackground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context,
  GoTheme theme,
  String title,
  String message, {
  String okLabel = 'Confirm',
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: theme.background,
      title: Text(title, style: TextStyle(color: theme.onBackground)),
      content: Text(message,
          style: TextStyle(
              color: theme.onBackground.withValues(alpha: 0.8))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text('Cancel',
              style: TextStyle(color: theme.onBackground)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(c, true),
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return res ?? false;
}

void showQgmSnack(BuildContext context, GoTheme theme, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: theme.accent,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
