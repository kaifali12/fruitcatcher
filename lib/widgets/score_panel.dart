import 'package:flutter/material.dart';

import '../game/game_constants.dart';


class ScorePanel extends StatelessWidget {
  const ScorePanel({
    super.key,
    required this.score,
    required this.highScore,
    required this.lives,
    required this.onPause,
    required this.isPaused,
  });

  final int score;
  final int highScore;
  final int lives;
  final VoidCallback onPause;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: <Widget>[
            _Chip(
              icon: '⭐',
              label: 'Score',
              value: '$score',
              valueStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFD166),
              ),
            ),
            const SizedBox(width: 8),
            _Chip(
              icon: '🏆',
              label: 'Best',
              value: '$highScore',
              valueStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            // Lives
            Row(
              children: <Widget>[
                for (int i = 0; i < GameConstants.maxLives; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i < lives ? Icons.favorite : Icons.favorite_border,
                      color: i < lives ? const Color(0xFFE63946) : Colors.white24,
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Pause / resume button
            Material(
              color: Colors.white.withOpacity(0.08),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: isPaused ? 'Resume' : 'Pause',
                onPressed: onPause,
                icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueStyle,
  });
  final String icon;
  final String label;
  final String value;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: Colors.white54)),
              Text(value, style: valueStyle),
            ],
          ),
        ],
      ),
    );
  }
}
