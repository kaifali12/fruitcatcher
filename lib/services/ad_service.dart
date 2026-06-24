import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Singleton service to manage interstitial ads.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isLoaded = false;

  // ============================================
  // REPLACE WITH YOUR ACTUAL AD UNIT ID
  // Test IDs (remove in production):
  // Android: ca-app-pub-3940256099942544/1033173712
  // iOS: ca-app-pub-3940256099942544/4411468910
  // ============================================
  final String adUnitId = 'ca-app-pub-1784838922970769/8904270412';

  /// Load an interstitial ad. Call this early (e.g., when game starts).
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('✅ Interstitial ad loaded');
          _interstitialAd = ad;
          _isLoaded = true;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('ℹ️ Interstitial ad dismissed');
              _isLoaded = false;
              ad.dispose();
              _interstitialAd = null;
              // Preload next ad for future use
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ Interstitial ad failed to show: $error');
              _isLoaded = false;
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdImpression: (ad) {
              print('📊 Interstitial ad impression');
            },
            onAdClicked: (ad) {
              print('👆 Interstitial ad clicked');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('❌ Interstitial ad failed to load: $error');
          _isLoaded = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Show the interstitial ad if available. Returns true if ad was shown.
  Future<bool> showInterstitialAd() async {
    if (_isLoaded && _interstitialAd != null) {
      print('📢 Showing interstitial ad');
      await _interstitialAd!.show();
      _interstitialAd = null;
      _isLoaded = false;
      return true;
    } else {
      print('⚠️ Interstitial ad not ready');
      return false;
    }
  }

  /// Check if an ad is ready to show.
  bool get isAdReady => _isLoaded && _interstitialAd != null;

  /// Dispose of any loaded ad.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
  }
}