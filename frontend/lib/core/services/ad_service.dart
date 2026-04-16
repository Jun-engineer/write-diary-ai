import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// Ad configuration (iOS only)
class AdConfig {
  // Use test ads in debug mode, real ads in release
  static bool get useTestAds => kDebugMode;
  
  // iOS Ad Unit IDs
  static const String _iosInterstitialReal = 'ca-app-pub-5434162081070782/4213547836';
  static const String _iosRewardedReal = 'ca-app-pub-5434162081070782/5376448084';
  static const String _iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';
  static const String _iosRewardedTest = 'ca-app-pub-3940256099942544/1712485313';
  
  static String get interstitialAdUnitId {
    return useTestAds ? _iosInterstitialTest : _iosInterstitialReal;
  }
  
  static String get rewardedAdUnitId {
    return useTestAds ? _iosRewardedTest : _iosRewardedReal;
  }
}

/// Ad Service Provider
final adServiceProvider = Provider<AdService>((ref) => AdService());

/// Ad Service - Manages interstitial and rewarded ads
class AdService {
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;
  
  /// Initialize the Mobile Ads SDK
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Request ATT permission - must be called after first frame is rendered
  static Future<void> requestTrackingPermission() async {
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
  }
  
  /// Load an interstitial ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          if (kDebugMode) debugPrint('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }
  
  /// Load a rewarded ad
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          if (kDebugMode) debugPrint('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) debugPrint('Rewarded ad failed to load: $error');
          _isRewardedAdReady = false;
        },
      ),
    );
  }
  
  /// Show interstitial ad
  /// Returns true if ad was shown, false if not available
  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      if (kDebugMode) debugPrint('Interstitial ad not ready');
      return false;
    }
    
    // Use Completer to wait for ad dismissal
    final completer = Completer<void>();
    
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        if (kDebugMode) debugPrint('Interstitial ad dismissed');
        ad.dispose();
        _isInterstitialAdReady = false;
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) debugPrint('Interstitial ad failed to show: $error');
        ad.dispose();
        _isInterstitialAdReady = false;
        if (!completer.isCompleted) completer.complete();
      },
    );
    
    await _interstitialAd!.show();
    await completer.future; // Wait for ad to be dismissed
    _interstitialAd = null;
    _isInterstitialAdReady = false;
    return true;
  }
  
  /// Show rewarded ad
  /// Returns true if user earned reward, false otherwise
  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      if (kDebugMode) debugPrint('Rewarded ad not ready');
      return false;
    }
    
    bool rewardEarned = false;
    final completer = Completer<void>();
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        if (kDebugMode) debugPrint('Rewarded ad dismissed, rewardEarned: $rewardEarned');
        ad.dispose();
        _isRewardedAdReady = false;
        // Preload the next ad
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        _isRewardedAdReady = false;
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete();
      },
    );
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        if (kDebugMode) debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        rewardEarned = true;
      },
    );
    
    // Wait for ad to be dismissed
    await completer.future;
    
    _rewardedAd = null;
    _isRewardedAdReady = false;
    
    if (kDebugMode) debugPrint('showRewardedAd returning: $rewardEarned');
    return rewardEarned;
  }
  
  /// Check if interstitial ad is ready
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  
  /// Check if rewarded ad is ready
  bool get isRewardedAdReady => _isRewardedAdReady;
  
  /// Dispose all ads
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
