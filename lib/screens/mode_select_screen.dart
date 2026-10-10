/// Mode select: the 7 game modes.
library;

import 'package:flutter/material.dart';
import '../game/game_config.dart';
import '../services/audio_service.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
    return QgmScaffold(
      title: 'Choose a Mode',
      theme: theme,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final mode in GameModeId.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QgmCard(
                theme: theme,
                onTap: () {
                  AudioService.instance.playSfx('button');
                  Navigator.pushNamed(context, '/levels',
                      arguments: mode);
                },
                child: Row(
                  children: [
                    Text(mode.icon,
                        style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mode.title,
                              style: TextStyle(
                                  color: theme.onBackground,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold)),
                          Text(mode.subtitle,
                              style: TextStyle(
                                  color: theme.onBackground
                                      .withValues(alpha: 0.65),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: theme.onBackground
                            .withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
