/// About & Privacy: QAVEX info, contact and the privacy policy.
library;

import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _privacy = '''
PRIVACY POLICY — QAVEX GO MASTER

Developer: muhammad ehtasham (QAVEX)
Website: https://www.qavex.company/
Contact: games@qavex.company | +923375621550
Category: Board

1. NO DATA COLLECTION
Qavex Go Master does not collect, transmit, or share any personal data. There is no account, no login, and no analytics.

2. ON-DEVICE ONLY
Your player name, statistics, achievements, Stone Coins, themes and settings are stored only on your device (local app storage). Deleting the app deletes this data.

3. NO ADS, NO TRACKERS
The app shows no advertisements and embeds no third-party tracking SDKs.

4. IN-APP PURCHASE
The single optional purchase ("Buy Me a Coffee", \$0.99) is processed entirely by the Google Play Store / Apple App Store. QAVEX never sees your payment details.

5. CHILDREN
The app is suitable for all ages and includes a Kids Mode. Since no data is collected, there is nothing to protect beyond what stays on the device.

6. CONTACT
Questions about privacy: games@qavex.company.

Last updated: October 2026.
''';

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
    final text = theme.onBackground;

    return QgmScaffold(
      title: 'About & Privacy',
      theme: theme,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Image.asset('assets/icon/icon.png',
                    width: 96, height: 96),
                const SizedBox(height: 12),
                Text('QAVEX GO MASTER',
                    style: TextStyle(
                        color: text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
                Text('Version 1.0.0+1',
                    style: TextStyle(
                        color: text.withValues(alpha: 0.6),
                        fontSize: 13)),
              ],
            ),
          ),
          SectionTitle('Developer', theme),
          QgmCard(
            theme: theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(text, 'Developer', 'muhammad ehtasham'),
                _row(text, 'Company', 'QAVEX'),
                _row(text, 'Website', 'https://www.qavex.company/'),
                _row(text, 'Email', 'games@qavex.company'),
                _row(text, 'Phone', '+923375621550'),
                _row(text, 'Category', 'Board'),
              ],
            ),
          ),
          SectionTitle('The Game', theme),
          QgmCard(
            theme: theme,
            child: Text(
              'Qavex Go Master brings the 4,000-year-old game of Go to your phone: '
              '9x9, 13x13 and 19x19 boards, Chinese area scoring, four AI opponents '
              'from Easy to Expert, tsumego puzzles, blitz and timed modes, pass-and-play, '
              '8 hand-crafted board themes, 56 achievements and play-earned Stone Coins. '
              'Fully offline. No ads. No accounts.',
              style: TextStyle(
                  color: text.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.5),
            ),
          ),
          SectionTitle('Privacy Policy', theme),
          QgmCard(
            theme: theme,
            child: Text(
              _privacy,
              style: TextStyle(
                  color: text.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(Color text, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(k,
                style: TextStyle(
                    color: text.withValues(alpha: 0.6),
                    fontSize: 13)),
          ),
          Expanded(
            child: Text(v,
                style: TextStyle(
                    color: text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
