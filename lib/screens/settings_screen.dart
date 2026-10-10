/// Settings: audio, kids mode, accessibility and data reset.
library;

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
    final text = theme.onBackground;

    Widget toggle(
        String key, String title, String subtitle, bool value, IconData icon) {
      return SwitchListTile(
        value: value,
        onChanged: (v) {
          AudioService.instance.playSfx('button');
          profile.updateSetting(key, v);
          if (key == 'sound' || key == 'music') {
            AudioService.instance.syncSettings(
                sound: profile.soundOn, music: profile.musicOn);
          }
        },
        title: Text(title, style: TextStyle(color: text)),
        subtitle: Text(subtitle,
            style:
                TextStyle(color: text.withValues(alpha: 0.6), fontSize: 12)),
        secondary: Icon(icon, color: theme.accent),
        activeThumbColor: theme.accent,
      );
    }

    return QgmScaffold(
      title: 'Settings',
      theme: theme,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle('Audio & Feel', theme),
          QgmCard(
            theme: theme,
            child: Column(
              children: [
                toggle('sound', 'Sound effects', 'Stone clicks and chimes',
                    profile.soundOn, Icons.volume_up),
                toggle('music', 'Background music', 'Calm generated loops',
                    profile.musicOn, Icons.music_note),
                toggle('haptics', 'Haptics', 'Vibrate on captures',
                    profile.hapticsOn, Icons.vibration),
              ],
            ),
          ),
          SectionTitle('Kids Mode', theme),
          QgmCard(
            theme: theme,
            child: toggle(
                'kids',
                'Kids Mode',
                'Bigger hints, friendly words, extra encouragement',
                profile.kidsMode,
                Icons.child_care),
          ),
          SectionTitle('Accessibility', theme),
          QgmCard(
            theme: theme,
            child: Column(
              children: [
                toggle('largeText', 'Larger text', 'Scales up all text',
                    profile.largeText, Icons.text_fields),
                toggle(
                    'highContrast',
                    'High contrast board',
                    'Maximum-contrast board colors',
                    profile.highContrast,
                    Icons.contrast),
                toggle(
                    'reduceMotion',
                    'Reduce motion',
                    'Minimizes animations',
                    profile.reduceMotion,
                    Icons.motion_photos_off),
              ],
            ),
          ),
          SectionTitle('Data', theme),
          QgmCard(
            theme: theme,
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: theme.accent),
              title: Text('Reset all progress',
                  style: TextStyle(color: text)),
              subtitle: Text(
                  'Coins, stats, achievements and themes',
                  style: TextStyle(
                      color: text.withValues(alpha: 0.6),
                      fontSize: 12)),
              onTap: () async {
                final ok = await confirmDialog(
                    context,
                    theme,
                    'Reset everything?',
                    'This erases coins, stats, achievements and purchased themes. This cannot be undone.',
                    okLabel: 'Reset');
                if (ok) {
                  await profile.resetProgress();
                  if (context.mounted) {
                    showQgmSnack(
                        context, theme, 'Fresh start! Good luck.');
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Qavex Go Master v1.0.0+1\nFully offline • No ads',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: text.withValues(alpha: 0.5), fontSize: 12)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
