import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;

  // Google's official sample ad unit IDs — must NEVER be used in production.
  static const List<String> _googleTestAdUnitIds = [
    'ca-app-pub-3940256099942544/6300978111',  // Banner
    'ca-app-pub-3940256099942544/2934735716',  // Banner iOS
    'ca-app-pub-3940256099942544/1033173712', // Interstitial
    'ca-app-pub-3940256099942544/4411468910', // Interstitial iOS
    'ca-app-pub-3940256099942544/5224354917', // Rewarded
    'ca-app-pub-3940256099942544/1712485313', // Rewarded iOS
  ];

  static String? _readEnv(String key) {
    final v = _valueFor(key);
    if (v.isEmpty) return null;
    return v;
  }

  static String _valueFor(String key) {
    switch (key) {
      case 'APP_ADMOB_BANNER_ID':
        return AppConfig.admobBannerId;
      case 'APP_ADMOB_INTERSTITIAL_ID':
        return AppConfig.admobInterstitialId;
      case 'APP_ADMOB_REWARDED_ID':
        return AppConfig.admobRewardedId;
      default:
        return '';
    }
  }

  /// Returns the configured ad unit id, or empty string if not configured.
  /// In release builds, this throws if a Google test ad unit id is being used,
  /// because shipping test ads = zero revenue.
  static String _resolveAdUnit({
    required String envKey,
    required String androidTest,
    required String iosTest,
  }) {
    final configured = _readEnv(envKey);
    if (configured != null && configured.isNotEmpty) {
      if (kReleaseMode && _googleTestAdUnitIds.contains(configured)) {
        throw StateError(
          'Refusing to use Google test ad unit id in release. '
          'Set $envKey in your build env to a real AdMob unit id.',
        );
      }
      return configured;
    }
    if (kReleaseMode) {
      // In release we refuse to fall back to test ids.
      throw StateError(
        'Missing $envKey for release build. Configure it via --dart-define.',
      );
    }
    if (Platform.isAndroid) return androidTest;
    if (Platform.isIOS) return iosTest;
    return '';
  }

  // Initialize the Mobile Ads SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _resolveAdUnit(
        envKey: 'APP_ADMOB_BANNER_ID',
        androidTest: 'ca-app-pub-3940256099942544/6300978111',
        iosTest: 'ca-app-pub-3940256099942544/2934735716',
      );
    } else if (Platform.isIOS) {
      return _resolveAdUnit(
        envKey: 'APP_ADMOB_BANNER_ID',
        androidTest: 'ca-app-pub-3940256099942544/6300978111',
        iosTest: 'ca-app-pub-3940256099942544/2934735716',
      );
    }
    return '';
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _resolveAdUnit(
        envKey: 'APP_ADMOB_INTERSTITIAL_ID',
        androidTest: 'ca-app-pub-3940256099942544/1033173712',
        iosTest: 'ca-app-pub-3940256099942544/4411468910',
      );
    } else if (Platform.isIOS) {
      return _resolveAdUnit(
        envKey: 'APP_ADMOB_INTERSTITIAL_ID',
        androidTest: 'ca-app-pub-3940256099942544/1033173712',
        iosTest: 'ca-app-pub-3940256099942544/4411468910',
      );
    }
    return '';
  }

  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return _resolveAdUnit(
        envKey: 'APP_ADMOB_REWARDED_ID',
        androidTest: 'ca-app-pub-3940256099942544/5224354917',
        iosTest: 'ca-app-pub-3940256099942544/1712485313',
      );
    } else if (Platform.isIOS) {
      return _resolveAdUnit(
        envKey: 'APP_ADMOB_REWARDED_ID',
        androidTest: 'ca-app-pub-3940256099942544/5224354917',
        iosTest: 'ca-app-pub-3940256099942544/1712485313',
      );
    }
    return '';
  }

  // --- Interstitial Ads ---

  void _loadInterstitialAd() {
    if (_isInterstitialLoading) return;
    _isInterstitialLoading = true;

    String unitId;
    try {
      unitId = interstitialAdUnitId;
    } catch (e) {
      debugPrint('InterstitialAd unit id error: $e');
      _isInterstitialLoading = false;
      return;
    }
    if (unitId.isEmpty) {
      _isInterstitialLoading = false;
      return;
    }

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('$ad loaded');
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (_interstitialAd == null) {
      debugPrint('Warning: attempt to show interstitial before loaded.');
      _loadInterstitialAd(); // Try loading for next time
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd(); // Preload the next one
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }

  // --- Rewarded Ads ---

  void _loadRewardedAd() {
     if (_isRewardedLoading) return;
    _isRewardedLoading = true;

    String unitId;
    try {
      unitId = rewardedAdUnitId;
    } catch (e) {
      debugPrint('RewardedAd unit id error: $e');
      _isRewardedLoading = false;
      return;
    }
    if (unitId.isEmpty) {
      _isRewardedLoading = false;
      return;
    }

    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('$ad loaded.');
          _rewardedAd = ad;
           _isRewardedLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
           _isRewardedLoading = false;
        },
      ),
    );
  }

  void showRewardedAd({required Function(RewardItem) onUserEarnedReward, VoidCallback? onAdDismissed, VoidCallback? onAdFailed}) {
    if (_rewardedAd == null) {
      debugPrint('Warning: attempt to show rewarded before loaded.');
      _loadRewardedAd();
      onAdFailed?.call(); // Notify failure so UI can handle it (e.g., show error toast)
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        onAdFailed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward(reward);
      },
    );
  }
}
