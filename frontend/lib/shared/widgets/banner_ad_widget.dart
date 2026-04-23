import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/providers/user_provider.dart';
import '../../core/services/ad_service.dart';

/// Adaptive banner ad shown above the bottom navigation bar.
///
/// - Hidden for premium users.
/// - Hidden in debug mode (same contract as the rest of AdService — avoids
///   simulator crashes with the real ad SDK).
/// - Re-loads when the widget is mounted; disposes the native ad on unmount.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  void _maybeLoad() {
    if (kDebugMode) return;
    if (_bannerAd != null) return;
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) return;

    final ad = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) debugPrint('Banner ad failed to load: $error');
        },
      ),
    );
    ad.load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide completely for premium users / debug / not-yet-loaded.
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium || kDebugMode || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
