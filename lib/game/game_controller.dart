import 'dart:async';
import 'dart:math';
import 'dart:ui' show Color, Size;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/basket.dart';
import '../models/fruit.dart';
import 'game_constants.dart';
import 'sound_manager.dart';

/// Main game state + simulation loop.
class GameController extends ChangeNotifier {
  GameController({required this.playfieldSize}) {
    basket = Basket(x: playfieldSize.width / 2);
    _currentLevel = kLevels.first;
    _loadPrefs();
  }

  // ── External state ──
  Size playfieldSize;
  late Basket basket;

  // ── Game state ──
  final List<FallingItem> items = <FallingItem>[];
  int score = 0;
  int highScore = 0;
  int lives = GameConstants.startingLives;
  bool isRunning = false;
  bool isPaused = false;
  bool isGameOver = false;

  /// Brief red flash when the player loses a life.
  bool flashRed = false;

  /// Brief banner shown when the player levels up.
  bool _levelUpBannerVisible = false;
  bool get levelUpBannerVisible => _levelUpBannerVisible;
  String _levelUpText = '';
  String get levelUpText => _levelUpText;

  LevelDef _currentLevel = kLevels.first;
  LevelDef get currentLevel => _currentLevel;
  int highestLevelReached = 1;

  final List<_PopFx> _popQueue = <_PopFx>[];
  List<_PopFx> consumePopFx() {
    if (_popQueue.isEmpty) return const <_PopFx>[];
    final List<_PopFx> out = List<_PopFx>.from(_popQueue);
    _popQueue.clear();
    return out;
  }

  // ── Internals ──
  Timer? _ticker;
  double _spawnAccumulator = 0;
  int _nextItemId = 0;
  final Random _rng = Random();
  DateTime _lastTick = DateTime.now();
  double _flashTtl = 0;
  double _levelBannerTtl = 0;

  // ─────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────
  void start() {
    if (isRunning && !isPaused) return;
    if (isGameOver) _reset();
    isRunning = true;
    isPaused = false;
    _lastTick = DateTime.now();
    _ticker ??= Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    SoundManager.instance.startMusic();
    notifyListeners();
  }

  void pause() {
    if (!isRunning || isGameOver) return;
    isPaused = true;
    SoundManager.instance.pauseMusic();
    notifyListeners();
  }

  void resume() {
    if (!isRunning || isGameOver) return;
    isPaused = false;
    _lastTick = DateTime.now();
    SoundManager.instance.resumeMusic();
    notifyListeners();
  }

  void togglePause() => isPaused ? resume() : pause();

  void restart() {
    _reset();
    start();
  }

  void _reset() {
    items.clear();
    _popQueue.clear();
    score = 0;
    lives = GameConstants.startingLives;
    isGameOver = false;
    isPaused = false;
    flashRed = false;
    _spawnAccumulator = 0;
    _currentLevel = kLevels.first;
    _levelUpBannerVisible = false;
    basket = Basket(x: playfieldSize.width / 2);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    SoundManager.instance.stopMusic();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Input
  // ─────────────────────────────────────────────────────────────────────
  void moveBasketTo(double x) {
    final double halfW = basket.width / 2;
    basket.x = x.clamp(halfW, playfieldSize.width - halfW);
    notifyListeners();
  }

  void nudgeBasket(double dx) => moveBasketTo(basket.x + dx);

  void updatePlayfield(Size size) {
    if (size == playfieldSize) return;
    final double ratio = size.width / playfieldSize.width;
    basket.x = (basket.x * ratio).clamp(
      basket.width / 2,
      size.width - basket.width / 2,
    );
    playfieldSize = size;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Simulation
  // ─────────────────────────────────────────────────────────────────────
  void _tick() {
    if (!isRunning || isPaused || isGameOver) return;
    final DateTime now = DateTime.now();
    final double dt = now.difference(_lastTick).inMicroseconds / 1e6;
    _lastTick = now;

    _spawnAccumulator += dt;
    final double interval = _currentLevel.spawnInterval
        .clamp(GameConstants.minSpawnInterval, GameConstants.initialSpawnInterval);
    while (_spawnAccumulator >= interval) {
      _spawnItem();
      _spawnAccumulator -= interval;
    }

    final double basketY = playfieldSize.height -
        GameConstants.basketBottomPadding -
        GameConstants.basketHeight / 2;

    for (int i = items.length - 1; i >= 0; i--) {
      final FallingItem it = items[i];
      it.y += it.speed * dt;
      it.rotation += it.rotationSpeed * dt;

      if (it.y >= basketY - GameConstants.itemSize / 2 &&
          basket.catches(it.x, it.y)) {
        items.removeAt(i);
        if (it.kind.isBomb) {
          SoundManager.instance.playBomb();
          _loseLife();
        } else {
          score += it.kind.points;
          SoundManager.instance.playCatch();
          _popQueue.add(_PopFx(
            id: it.id,
            x: it.x,
            y: it.y,
            label: '+${it.kind.points}',
            color: it.kind.color,
          ));
          _maybeAdvanceLevel();
        }
        continue;
      }

      if (it.y > playfieldSize.height + GameConstants.itemSize) {
        items.removeAt(i);
      }
    }

    if (flashRed) {
      _flashTtl -= dt;
      if (_flashTtl <= 0) flashRed = false;
    }
    if (_levelUpBannerVisible) {
      _levelBannerTtl -= dt;
      if (_levelBannerTtl <= 0) _levelUpBannerVisible = false;
    }

    notifyListeners();
  }

  void _maybeAdvanceLevel() {
    final LevelDef next = levelForScore(score);
    if (next.index > _currentLevel.index) {
      _currentLevel = next;
      _levelUpBannerVisible = true;
      _levelBannerTtl = 2.2;
      _levelUpText = 'Level ${next.index}: ${next.name}';
      if (next.index > highestLevelReached) {
        highestLevelReached = next.index;
        _saveHighLevel();
      }
      SoundManager.instance.playLevelUp();
    }
  }

  void _spawnItem() {
    final bool spawnBomb = _rng.nextDouble() < _currentLevel.bombChance;
    final FruitKind kind = spawnBomb
        ? FruitKind.bomb
        : _pickAllowedKind();
    final double speed = GameConstants.minFallSpeed +
        _currentLevel.speedBonus +
        _rng.nextDouble() *
            (GameConstants.maxFallSpeed - GameConstants.minFallSpeed);
    final double margin = GameConstants.itemSize;
    final double x = margin + _rng.nextDouble() * (playfieldSize.width - margin * 2);
    items.add(FallingItem(
      id: _nextItemId++,
      kind: kind,
      x: x,
      y: -GameConstants.itemSize,
      speed: speed,
      rotation: _rng.nextDouble() * pi,
      rotationSpeed: (_rng.nextDouble() - .5) * 2.4,
    ));
  }

  FruitKind _pickAllowedKind() {
    final List<FruitKind> pool = FruitKind.values
        .where((FruitKind k) =>
            !k.isBomb && _currentLevel.allowed.contains(k.category))
        .toList(growable: false);
    return pool[_rng.nextInt(pool.length)];
  }

  void _loseLife() {
    lives = (lives - 1).clamp(0, GameConstants.maxLives);
    flashRed = true;
    _flashTtl = 0.35;
    if (lives <= 0) _onGameOver();
    notifyListeners();
  }

  void _onGameOver() {
    isGameOver = true;
    isRunning = false;
    SoundManager.instance.stopMusic();
    SoundManager.instance.playGameOver();
    if (score > highScore) {
      highScore = score;
      _saveHighScore();
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Persistence
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      highScore = prefs.getInt(GameConstants.prefsHighScoreKey) ?? 0;
      highestLevelReached =
          prefs.getInt(GameConstants.prefsHighLevelKey) ?? 1;
      notifyListeners();
    } catch (_) {/* first run */}
  }

  Future<void> _saveHighScore() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(GameConstants.prefsHighScoreKey, highScore);
    } catch (_) {}
  }

  Future<void> _saveHighLevel() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          GameConstants.prefsHighLevelKey, highestLevelReached);
    } catch (_) {}
  }
}

/// Floating "+pts" effect triggered by a successful catch.
class _PopFx {
  _PopFx({
    required this.id,
    required this.x,
    required this.y,
    required this.label,
    required this.color,
  });
  final int id;
  final double x;
  final double y;
  final String label;
  final Color color;
}

typedef PopFx = _PopFx;
