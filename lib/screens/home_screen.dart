import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_constants.dart';
import 'game_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);
  int _high = 0;


  static const String _adUnitId = 'ca-app-pub-1784838922970769/8391346083';

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHigh();
    _loadBannerAd();
  }

  /// Load the banner ad
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner ad loaded');
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          _isAdLoaded = false;
        },
        onAdOpened: (ad) {
          debugPrint('📢 Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('ℹ️ Banner ad closed');
        },
      ),
    )..load();
  }

  Future<void> _loadHigh() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _high = prefs.getInt(GameConstants.prefsHighScoreKey) ?? 0;
    });
  }

  @override
  void dispose() {
    _bob.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[GameConstants.skyTop, GameConstants.skyBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // ========== BANNER AD ON TOP ==========
              _bannerAdWidget(),

              const Spacer(),
              _bouncingFruits(),
              const SizedBox(height: 24),
              const Text('Fruit Catcher',
                  style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1)),
              const SizedBox(height: 6),
              const Text('Catch the fruit. Dodge the bombs.',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 40),
              if (_high > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('🏆  Best:  $_high',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 24),
              _playButton(),
              const SizedBox(height: 16),
              _helpText(),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('v1.0.0',
                    style: TextStyle(color: Colors.white.withOpacity(0.3))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner ad widget with glassmorphism background
  Widget _bannerAdWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: _isAdLoaded && _bannerAd != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
          : SizedBox(
              height: 50, // Placeholder height when ad not loaded
              width: double.infinity,
              child: Center(
                child: Text(
                  'Ad',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _bouncingFruits() {
    const List<String> fruits = <String>['🍒', '🍎', '🍓', '🍇', '🍉'];
    return SizedBox(
      height: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < fruits.length; i++)
            AnimatedBuilder(
              animation: _bob,
              builder: (BuildContext c, Widget? child) {
                final double t = (_bob.value + i / fruits.length) % 1;
                final double y = -16 * (1 - (2 * t - 1) * (2 * t - 1));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Transform.translate(
                    offset: Offset(0, y),
                    child: Text(fruits[i], style: const TextStyle(fontSize: 44)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _playButton() {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const GameScreen()),
        );
        _loadHigh();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 8,
        shadowColor: const Color(0xFFFF6B6B).withOpacity(0.6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.play_arrow_rounded, size: 30),
          SizedBox(width: 6),
          Text('Play',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _helpText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'Drag the basket',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }
}