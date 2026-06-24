// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import '../game/game_constants.dart';
// import '../game/game_controller.dart';
// import '../services/ad_service.dart';
// import '../widgets/basket_widget.dart';
// import '../widgets/fruit_widget.dart';
// import '../widgets/score_panel.dart';
// import 'game_over_screen.dart';

// /// The live gameplay screen. Hosts the [GameController], wires up input and
// /// renders the basket + falling items on a [Stack].
// class GameScreen extends StatefulWidget {
//   const GameScreen({super.key});

//   @override
//   State<GameScreen> createState() => _GameScreenState();
// }

// class _GameScreenState extends State<GameScreen> {
//   GameController? _controller;
//   final FocusNode _focus = FocusNode();
//   bool _hasShownGameOver = false;
//   List<PopFx> _popQueue = const <PopFx>[];
//   final AdService _adService = AdService();

//   @override
//   void initState() {
//     super.initState();
//     // Grab focus so keyboard events route here.
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _focus.requestFocus();
//       // Load interstitial ad when game screen opens
//       _adService.loadInterstitialAd();
//     });
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _focus.dispose();
//     _adService.dispose();
//     super.dispose();
//   }

//   void _ensureController(Size playfield) {
//     if (_controller == null) {
//       _controller = GameController(playfieldSize: playfield)
//         ..addListener(_onControllerTick);
//       // Start automatically.
//       WidgetsBinding.instance.addPostFrameCallback((_) => _controller!.start());
//     } else {
//       _controller!.updatePlayfield(playfield);
//     }
//   }

//   void _onControllerTick() {
//     final List<PopFx> fx = _controller!.consumePopFx();
//     if (fx.isNotEmpty) _popQueue = fx;
//     if (_controller!.isGameOver && !_hasShownGameOver) {
//       _hasShownGameOver = true;
//       WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOverWithAd());
//     }
//     setState(() {});
//   }

//   /// Show interstitial ad first, then game over screen.
//   Future<void> _showGameOverWithAd() async {
//     // Show interstitial ad before game over screen
//     await _adService.showInterstitialAd();
    
//     // Small delay after ad dismisses for smoother transition
//     if (mounted) {
//       await Future<void>.delayed(const Duration(milliseconds: 300));
//     }
    
//     // Now show game over screen
//     _showGameOver();
//   }

//   Future<void> _showGameOver() async {
//     final int score = _controller!.score;
//     final int high = _controller!.highScore;
//     final bool retry = await Navigator.of(context).push<bool>(
//           MaterialPageRoute<bool>(
//             fullscreenDialog: true,
//             builder: (_) => GameOverScreen(score: score, highScore: high),
//           ),
//         ) ??
//         false;
//     if (!mounted) return;
//     if (retry) {
//       _hasShownGameOver = false;
//       _controller!.restart();
//       // Preload ad for next game over
//       _adService.loadInterstitialAd();
//     } else {
//       if (mounted) Navigator.of(context).pop();
//     }
//   }

//   KeyEventResult _handleKey(FocusNode node, KeyEvent e) {
//     if (_controller == null) return KeyEventResult.ignored;
//     if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
//     if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
//       _controller!.nudgeBasket(-32);
//       return KeyEventResult.handled;
//     }
//     if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
//       _controller!.nudgeBasket(32);
//       return KeyEventResult.handled;
//     }
//     if (e.logicalKey == LogicalKeyboardKey.space) {
//       _controller!.togglePause();
//       return KeyEventResult.handled;
//     }
//     return KeyEventResult.ignored;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: LayoutBuilder(
//         builder: (BuildContext context, BoxConstraints c) {
//           final Size playfield = Size(c.maxWidth, c.maxHeight);
//           _ensureController(playfield);
//           final GameController g = _controller!;

//           return Focus(
//             focusNode: _focus,
//             autofocus: true,
//             onKeyEvent: _handleKey,
//             child: GestureDetector(
//               behavior: HitTestBehavior.opaque,
//               onPanUpdate: (DragUpdateDetails d) =>
//                   g.moveBasketTo(d.localPosition.dx),
//               onPanStart: (DragStartDetails d) =>
//                   g.moveBasketTo(d.localPosition.dx),
//               onTapDown: (TapDownDetails d) =>
//                   g.moveBasketTo(d.localPosition.dx),
//               child: Stack(
//                 children: <Widget>[
//                   // Background gradient
//                   const Positioned.fill(
//                     child: DecoratedBox(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: <Color>[
//                             GameConstants.skyTop,
//                             GameConstants.skyBottom,
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   // Decorative stars
//                   ..._starField(playfield),
//                   // Damage flash
//                   IgnorePointer(
//                     child: AnimatedOpacity(
//                       opacity: g.flashRed ? 0.35 : 0,
//                       duration: const Duration(milliseconds: 200),
//                       child: Container(color: Colors.red),
//                     ),
//                   ),
//                   // Falling items
//                   for (final dynamic it in g.items)
//                     Positioned(
//                       left: it.x - GameConstants.itemSize / 2,
//                       top: it.y - GameConstants.itemSize / 2,
//                       child: FruitWidget(item: it),
//                     ),
//                   // Pop FX
//                   for (final PopFx p in _popQueue)
//                     _PopText(key: ValueKey<int>(p.id), fx: p),
//                   // Basket
//                   Positioned(
//                     left: g.basket.x - GameConstants.basketWidth / 2,
//                     bottom: GameConstants.basketBottomPadding,
//                     child: const BasketWidget(),
//                   ),
//                   // HUD
//                   Align(
//                     alignment: Alignment.topCenter,
//                     child: ScorePanel(
//                       score: g.score,
//                       highScore: g.highScore,
//                       lives: g.lives,
//                       isPaused: g.isPaused,
//                       onPause: g.togglePause,
//                     ),
//                   ),
//                   // Pause overlay
//                   if (g.isPaused) _pauseOverlay(g),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   List<Widget> _starField(Size s) {
//     final List<Widget> stars = <Widget>[];
//     final List<List<double>> positions = <List<double>>[
//       <double>[0.10, 0.14], <double>[0.85, 0.08], <double>[0.30, 0.20],
//       <double>[0.60, 0.28], <double>[0.18, 0.40], <double>[0.78, 0.45],
//       <double>[0.50, 0.55], <double>[0.90, 0.62],
//     ];
//     for (final List<double> p in positions) {
//       stars.add(Positioned(
//         left: p[0] * s.width,
//         top: p[1] * s.height,
//         child: Container(
//           width: 3, height: 3,
//           decoration: const BoxDecoration(
//             color: Colors.white, shape: BoxShape.circle,
//           ),
//         ),
//       ));
//     }
//     return stars;
//   }

//   Widget _pauseOverlay(GameController g) {
//     return Positioned.fill(
//       child: ColoredBox(
//         color: Colors.black.withOpacity(0.55),
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: <Widget>[
//               const Icon(Icons.pause_circle_filled,
//                   size: 80, color: Colors.white70),
//               const SizedBox(height: 8),
//               const Text('Paused',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 28,
//                       fontWeight: FontWeight.w800)),
//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 onPressed: g.resume,
//                 icon: const Icon(Icons.play_arrow_rounded),
//                 label: const Text('Resume'),
//                 style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 24, vertical: 12)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// A small "+pts" label that floats upward and fades out.
// class _PopText extends StatefulWidget {
//   const _PopText({super.key, required this.fx});
//   final PopFx fx;

//   @override
//   State<_PopText> createState() => _PopTextState();
// }

// class _PopTextState extends State<_PopText>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _c = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 700),
//   )..forward();

//   @override
//   void dispose() {
//     _c.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _c,
//       builder: (BuildContext context, Widget? child) {
//         final double t = _c.value;
//         return Positioned(
//           left: widget.fx.x - 20,
//           top: widget.fx.y - 30 - t * 40,
//           child: Opacity(
//             opacity: 1 - t,
//             child: Text(
//               widget.fx.label,
//               style: TextStyle(
//                 color: widget.fx.color,
//                 fontSize: 22,
//                 fontWeight: FontWeight.w900,
//                 shadows: const <Shadow>[
//                   Shadow(blurRadius: 8, color: Colors.black54),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../game/game_constants.dart';
import '../game/game_controller.dart';
import '../services/ad_service.dart';
import '../widgets/basket_widget.dart';
import '../widgets/fruit_widget.dart';
import 'game_over_screen.dart';

/// The live gameplay screen. Hosts the [GameController], wires up input and
/// renders the basket + falling items on a [Stack].
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  GameController? _controller;
  final FocusNode _focus = FocusNode();
  bool _hasShownGameOver = false;
  List<PopFx> _popQueue = const <PopFx>[];
  final AdService _adService = AdService();

  // Animation controllers for premium effects
  late final AnimationController _bgAnimController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _shimmerAnim;

  // Previous score for animation
  int _displayedScore = 0;
  int _previousScore = 0;

  @override
  void initState() {
    super.initState();

    // Background animation controller
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Pulse animation for lives
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      _adService.loadInterstitialAd();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _focus.dispose();
    _adService.dispose();
    _bgAnimController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _ensureController(Size playfield) {
    if (_controller == null) {
      _controller = GameController(playfieldSize: playfield)
        ..addListener(_onControllerTick);
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller!.start());
    } else {
      _controller!.updatePlayfield(playfield);
    }
  }

  void _onControllerTick() {
    final List<PopFx> fx = _controller!.consumePopFx();
    if (fx.isNotEmpty) _popQueue = fx;
    if (_controller!.isGameOver && !_hasShownGameOver) {
      _hasShownGameOver = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOverWithAd());
    }
    // Animate score
    _previousScore = _displayedScore;
    _displayedScore = _controller!.score;
    setState(() {});
  }

  Future<void> _showGameOverWithAd() async {
    await _adService.showInterstitialAd();
    if (mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    _showGameOver();
  }

  Future<void> _showGameOver() async {
    final int score = _controller!.score;
    final int high = _controller!.highScore;
    final bool retry = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            fullscreenDialog: true,
            builder: (_) => GameOverScreen(score: score, highScore: high),
          ),
        ) ??
        false;
    if (!mounted) return;
    if (retry) {
      _hasShownGameOver = false;
      _controller!.restart();
      _adService.loadInterstitialAd();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent e) {
    if (_controller == null) return KeyEventResult.ignored;
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _controller!.nudgeBasket(-32);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      _controller!.nudgeBasket(32);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.space) {
      _controller!.togglePause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          final Size playfield = Size(c.maxWidth, c.maxHeight);
          _ensureController(playfield);
          final GameController g = _controller!;

          return Focus(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _handleKey,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (DragUpdateDetails d) =>
                  g.moveBasketTo(d.localPosition.dx),
              onPanStart: (DragStartDetails d) =>
                  g.moveBasketTo(d.localPosition.dx),
              onTapDown: (TapDownDetails d) =>
                  g.moveBasketTo(d.localPosition.dx),
              child: Stack(
                children: <Widget>[
                  // Premium animated background
                  _AnimatedBackground(controller: _bgAnimController),
                  
                  // Floating orbs
                  ..._floatingOrbs(playfield),
                  
                  // Twinkling stars
                  ..._twinklingStars(playfield),
                  
                  // Damage flash with glow
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: g.flashRed ? 0.4 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withOpacity(0.3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade500.withOpacity(0.5),
                              blurRadius: 100,
                              spreadRadius: 50,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Ground with gradient
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.green.shade900.withOpacity(0.6),
                            Colors.green.shade800.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Falling items with glow
                  for (final dynamic it in g.items)
                    Positioned(
                      left: it.x - GameConstants.itemSize / 2,
                      top: it.y - GameConstants.itemSize / 2,
                      child: _GlowingFruit(item: it),
                    ),

                  // Pop FX
                  for (final PopFx p in _popQueue)
                    _PremiumPopText(
                      key: ValueKey<int>(p.id),
                      fx: p,
                    ),

                  // Basket with glow effect
                  Positioned(
                    left: g.basket.x - GameConstants.basketWidth / 2,
                    bottom: GameConstants.basketBottomPadding,
                    child: _GlowingBasket(),
                  ),

                  // Premium HUD (FIXED LAYOUT)
                  _PremiumHUD(
                    score: g.score,
                    highScore: g.highScore,
                    lives: g.lives,
                    isPaused: g.isPaused,
                    onPause: g.togglePause,
                    pulseAnim: _pulseAnim,
                    shimmerAnim: _shimmerAnim,
                    scoreIncreased: _displayedScore > _previousScore,
                  ),

                  // Premium pause overlay
                  if (g.isPaused) _PremiumPauseOverlay(g: g),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _floatingOrbs(Size s) {
    return <Widget>[
      _FloatingOrb(
        x: 0.15, y: 0.25, size: 120,
        color: Colors.purple.withOpacity(0.15),
        controller: _bgAnimController,
        delay: 0.0,
      ),
      _FloatingOrb(
        x: 0.85, y: 0.15, size: 100,
        color: Colors.blue.withOpacity(0.12),
        controller: _bgAnimController,
        delay: 0.3,
      ),
      _FloatingOrb(
        x: 0.7, y: 0.65, size: 150,
        color: Colors.teal.withOpacity(0.1),
        controller: _bgAnimController,
        delay: 0.6,
      ),
      _FloatingOrb(
        x: 0.25, y: 0.75, size: 90,
        color: Colors.orange.withOpacity(0.12),
        controller: _bgAnimController,
        delay: 0.9,
      ),
    ];
  }

  List<Widget> _twinklingStars(Size s) {
    final List<Widget> stars = <Widget>[];
    final List<List<double>> positions = <List<double>>[
      <double>[0.10, 0.14], <double>[0.85, 0.08], <double>[0.30, 0.20],
      <double>[0.60, 0.28], <double>[0.18, 0.40], <double>[0.78, 0.45],
      <double>[0.50, 0.55], <double>[0.90, 0.62], <double>[0.42, 0.12],
      <double>[0.72, 0.35], <double>[0.08, 0.58], <double>[0.55, 0.78],
      <double>[0.35, 0.88], <double>[0.92, 0.85], <double>[0.15, 0.92],
    ];
    
    for (int i = 0; i < positions.length; i++) {
      stars.add(
        _TwinklingStar(
          x: positions[i][0] * s.width,
          y: positions[i][1] * s.height,
          size: 2 + (i % 3).toDouble(),
          delay: i * 0.2,
          controller: _bgAnimController,
        ),
      );
    }
    return stars;
  }
}

// ============================================================================
// PREMIUM WIDGETS
// ============================================================================

/// Animated gradient background with smooth color transitions
class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double t = controller.value;
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 0.5, -1),
                end: Alignment(1 - t * 0.5, 1),
                colors: <Color>[
                  Color.lerp(const Color(0xFF0a0a2e), const Color(0xFF1a0a3e), t)!,
                  Color.lerp(const Color(0xFF1a1a4e), const Color(0xFF0a2a5e), t)!,
                  Color.lerp(const Color(0xFF2a1a3e), const Color(0xFF1a3a4e), t)!,
                  Color.lerp(const Color(0xFF0a1a3e), const Color(0xFF2a1a5e), t)!,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Floating orb with blur effect
class _FloatingOrb extends StatelessWidget {
  const _FloatingOrb({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.controller,
    required this.delay,
  });

  final double x, y, size, delay;
  final Color color;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double t = (controller.value + delay) % 1.0;
        final double offsetY = sin(t * 2 * pi) * 30;
        final double offsetX = cos(t * 1.5 * pi) * 15;
        return Positioned(
          left: x * MediaQuery.of(context).size.width + offsetX - size / 2,
          top: y * MediaQuery.of(context).size.height + offsetY - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color, color.withOpacity(0)],
                stops: const [0.3, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Twinkling star with glow
class _TwinklingStar extends StatelessWidget {
  const _TwinklingStar({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
    required this.controller,
  });

  final double x, y, size, delay;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double t = (controller.value * 2 + delay) % 1.0;
        final double opacity = 0.3 + 0.7 * pow(sin(t * pi), 2).toDouble();

        return Positioned(
          left: x - size * 2,
          top: y - size * 2,
          child: SizedBox(
            width: size * 4,
            height: size * 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: size * 4,
                  height: size * 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(opacity * 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5],
                    ),
                  ),
                ),
                // Star core
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(opacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(opacity * 0.8),
                        blurRadius: size * 2,
                        spreadRadius: size * 0.5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Glowing fruit wrapper
class _GlowingFruit extends StatelessWidget {
  const _GlowingFruit({required this.item});
  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final bool isBadItem = _checkIfBad(item);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isBadItem
                ? Colors.redAccent.withOpacity(0.5)
                : Colors.amberAccent.withOpacity(0.4),
            blurRadius: isBadItem ? 20 : 15,
            spreadRadius: isBadItem ? 4 : 2,
          ),
          if (isBadItem)
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 8,
            ),
        ],
      ),
      child: FruitWidget(item: item),
    );
  }

  bool _checkIfBad(dynamic item) {
    try {
      if (item.isBad != null) return item.isBad as bool;
      if (item.isBomb != null) return item.isBomb as bool;
      if (item.isHarmful != null) return item.isHarmful as bool;
      if (item.type != null) {
        final String typeStr = item.type.toString().toLowerCase();
        if (typeStr.contains('bomb') ||
            typeStr.contains('bad') ||
            typeStr.contains('harmful')) {
          return true;
        }
      }
      if (item.points != null && (item.points as num) < 0) return true;
      if (item.score != null && (item.score as num) < 0) return true;
    } catch (_) {}
    return false;
  }
}

/// Glowing basket wrapper
class _GlowingBasket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const BasketWidget(),
    );
  }
}

/// Premium HUD - matches the reference layout
/// LEFT: Star + SCORE | RIGHT: Trophy + Hearts + Pause
class _PremiumHUD extends StatelessWidget {
  const _PremiumHUD({
    required this.score,
    required this.highScore,
    required this.lives,
    required this.isPaused,
    required this.onPause,
    required this.pulseAnim,
    required this.shimmerAnim,
    required this.scoreIncreased,
  });

  final int score, highScore, lives;
  final bool isPaused;
  final VoidCallback onPause;
  final Animation<double> pulseAnim;
  final Animation<double> shimmerAnim;
  final bool scoreIncreased;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ========== LEFT SIDE: SCORE ==========
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Star icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                // Score label + number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.5),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        score.toString(),
                        key: ValueKey<int>(score),
                        style: TextStyle(
                          color: scoreIncreased ? Colors.amber : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          shadows: scoreIncreased
                              ? [
                                  const Shadow(
                                    color: Colors.amber,
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ========== RIGHT SIDE: TROPHY + HEARTS + PAUSE ==========
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // High score (trophy + number)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      highScore.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Lives (hearts)
                AnimatedBuilder(
                  animation: pulseAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: lives <= 1 ? pulseAnim.value : 1.0,
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final bool hasLife = index < lives;
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 3),
                        child: Icon(
                          hasLife
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: hasLife
                              ? (lives <= 1
                                  ? Colors.red.shade400
                                  : Colors.red.shade600)
                              : Colors.white24,
                          size: 18,
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(width: 10),

                // Pause button
                GestureDetector(
                  onTap: onPause,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium pause overlay
class _PremiumPauseOverlay extends StatelessWidget {
  const _PremiumPauseOverlay({required this.g});
  final GameController g;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900.withOpacity(0.8),
              Colors.black.withOpacity(0.85),
              Colors.indigo.shade900.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pause_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    shadows: [
                      Shadow(color: Colors.purple, blurRadius: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take a break',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                _PremiumButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'RESUME',
                  onPressed: g.resume,
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade600],
                  ),
                ),
                const SizedBox(height: 16),
                _PremiumButton(
                  icon: Icons.exit_to_app_rounded,
                  label: 'QUIT',
                  onPressed: () => Navigator.of(context).pop(),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  isOutlined: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium button with gradient
class _PremiumButton extends StatelessWidget {
  const _PremiumButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.gradient,
    this.isOutlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final LinearGradient gradient;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            gradient: isOutlined ? null : gradient,
            borderRadius: BorderRadius.circular(16),
            border: isOutlined
                ? Border.all(color: Colors.white.withOpacity(0.3))
                : null,
            color: isOutlined ? Colors.white.withOpacity(0.05) : null,
            boxShadow: isOutlined
                ? null
                : [
                    BoxShadow(
                      color: (gradient.colors.first).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumPopText extends StatefulWidget {
  const _PremiumPopText({super.key, required this.fx});
  final PopFx fx;

  @override
  State<_PremiumPopText> createState() => _PremiumPopTextState();
}

class _PremiumPopTextState extends State<_PremiumPopText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double t = _c.value;
        final double scale = 1.0 + 0.3 * sin(t * pi);
        return Positioned(
          left: widget.fx.x - 25,
          top: widget.fx.y - 35 - t * 60,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: t < 0.2 ? t * 5 : 1.0 - ((t - 0.2) / 0.8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.fx.color.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.fx.label,
                  style: TextStyle(
                    color: widget.fx.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        blurRadius: 12,
                        color: widget.fx.color.withOpacity(0.8),
                      ),
                      const Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}