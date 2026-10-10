/// Shop: buy board themes with Stone Coins + the single IAP
/// ("Buy Me a Coffee", $0.99, product qavexgomastercoffee).
library;

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../theme/app_themes.dart';
import '../widgets/profile_scope.dart';
import '../widgets/ui_kit.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final IapService _iap;

  @override
  void initState() {
    super.initState();
    _iap = IapService();
    _iap.onCoffeePurchased = _onCoffee;
    _iap.addListener(_refresh);
    _iap.init();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _onCoffee() async {
    final profile = ProfileScope.of(context);
    await profile.markCoffeeSupporter();
    AudioService.instance.playSfx('achievement');
    if (!mounted) return;
    final theme = _themeOf(context);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: theme.background,
        title: Text('Thank you! ☕',
            style: TextStyle(color: theme.onBackground)),
        content: Text(
          'You are officially a QAVEX supporter. +100 Stone Coins are yours!',
          style: TextStyle(
              color: theme.onBackground.withValues(alpha: 0.8)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: theme.accent,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(c),
            child: const Text('Cheers!'),
          ),
        ],
      ),
    );
  }

  GoTheme _themeOf(BuildContext context) {
    final profile = ProfileScope.of(context);
    return effectiveTheme(themeById(profile.activeThemeId),
        highContrast: profile.highContrast);
  }

  @override
  void dispose() {
    _iap.removeListener(_refresh);
    _iap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = _themeOf(context);
    final text = theme.onBackground;

    return QgmScaffold(
      title: 'Shop',
      theme: theme,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
              child: CoinPill(coins: profile.coins, theme: theme)),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Coffee IAP ---
          SectionTitle('Support QAVEX', theme),
          QgmCard(
            theme: theme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('☕',
                        style: TextStyle(fontSize: 40)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(IapService.coffeeTitle,
                              style: TextStyle(
                                  color: text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            'Product: ${IapService.coffeeProductId}',
                            style: TextStyle(
                                color: text.withValues(
                                    alpha: 0.55),
                                fontSize: 11,
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    Text(IapService.coffeePriceLabel,
                        style: TextStyle(
                            color: theme.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Qavex Go Master is free, offline and ad-free. '
                  'This one-time tip keeps the stones rolling — and earns you the Supporter badge + 100 Stone Coins.',
                  style: TextStyle(
                      color: text.withValues(alpha: 0.75),
                      fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_iap.loading)
                  const Center(
                      child: CircularProgressIndicator())
                else if (profile.stats.coffeeSupporter)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: GoTheme.bamboo
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✅ You are a supporter. Thank you!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  )
                else ...[
                  QgmButton(
                    label: _iap.pendingPurchase
                        ? 'Processing…'
                        : 'Buy Me a Coffee — \$0.99',
                    theme: theme,
                    onPressed: _iap.storeAvailable &&
                            _iap.coffeeProduct != null &&
                            !_iap.pendingPurchase
                        ? () {
                            AudioService.instance
                                .playSfx('button');
                            _iap.buyCoffee();
                          }
                        : null,
                  ),
                  if (_iap.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_iap.error!,
                          style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                  TextButton(
                    onPressed: _iap.storeAvailable
                        ? () => _iap.restore()
                        : null,
                    child: Text('Restore purchases',
                        style: TextStyle(
                            color: text.withValues(
                                alpha: 0.7))),
                  ),
                ],
              ],
            ),
          ),
          // --- Themes for coins ---
          SectionTitle('Themes for Stone Coins', theme),
          for (final t in goThemes.where((t) => t.priceCoins > 0))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QgmCard(
                theme: theme,
                child: Row(
                  children: [
                    _miniBoard(t),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(t.tagline,
                              style: TextStyle(
                                  color: text.withValues(
                                      alpha: 0.6),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    _themeAction(theme, profile, t),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Text(
              'Earn Stone Coins by playing games and solving puzzles. No ads, ever.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: text.withValues(alpha: 0.55),
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBoard(GoTheme t) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: t.board,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.line, width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
              left: 14,
              top: 14,
              child: _dot(t.blackStone)),
          Positioned(
              right: 14,
              bottom: 14,
              child: _dot(t.whiteStone)),
          Positioned(
              right: 12,
              top: 12,
              child: _dot(t.accent)),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c,
            border: Border.all(color: Colors.black26)),
      );

  Widget _themeAction(
      GoTheme theme, ProfileService profile, GoTheme t) {
    if (profile.ownedThemes.contains(t.id)) {
      return Text('Owned ✅',
          style: TextStyle(
              color: GoTheme.bamboo,
              fontWeight: FontWeight.bold,
              fontSize: 13));
    }
    final afford = profile.coins >= t.priceCoins;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            afford ? theme.accent : theme.surface,
        foregroundColor: afford
            ? Colors.white
            : theme.onBackground.withValues(alpha: 0.5),
      ),
      onPressed: afford
          ? () {
              final ok =
                  profile.unlockTheme(t.id, t.priceCoins);
              AudioService.instance
                  .playSfx(ok ? 'coin' : 'error');
              if (ok && mounted) {
                showQgmSnack(
                    context, theme, '${t.name} unlocked!');
              }
            }
          : null,
      child: Text('🪙 ${t.priceCoins}'),
    );
  }
}
