import 'package:flutter/material.dart';

import '../game/game_constants.dart';

/// End-of-run summary. Returns `true` from [Navigator.pop] to request a
/// retry, `false` to bail back to the home screen.
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({
    super.key,
    required this.score,
    required this.highScore,
  });

  final int score;
  final int highScore;

  @override
  Widget build(BuildContext context) {
    final bool newRecord = score >= highScore && score > 0;
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const Spacer(),
                const Text('Game Over',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                if (newRecord)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFFD166).withOpacity(0.5)),
                    ),
                    child: const Text('🏆  New High Score!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFFFFD166),
                            fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 16),
                _bigStat('Your score', score, valueColor: Colors.white),
                const SizedBox(height: 12),
                _bigStat('Best',
                    score > highScore ? score : highScore,
                    valueColor: const Color(0xFFFFD166)),
                const Spacer(),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          side: const BorderSide(color: Colors.white24),
                        ),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Home',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          elevation: 6,
                          shadowColor: const Color(0xFFFF6B6B).withOpacity(0.6),
                        ),
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Retry',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigStat(String label, int value, {required Color valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text('$value',
              style: TextStyle(
                  color: valueColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
