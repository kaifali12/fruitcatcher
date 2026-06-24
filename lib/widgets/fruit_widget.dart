import 'package:flutter/material.dart';

import '../game/game_constants.dart';
import '../models/fruit.dart';

/// Renders a single falling item — a fruit or a bomb.
///
/// Uses the kind's emoji on top of a soft colored glow so it reads well on the
/// dark playfield without needing any image assets.
class FruitWidget extends StatelessWidget {
  const FruitWidget({super.key, required this.item});

  final FallingItem item;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: item.rotation,
      child: Container(
        width: GameConstants.itemSize,
        height: GameConstants.itemSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              item.kind.color.withOpacity(0.55),
              item.kind.color.withOpacity(0.0),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: item.kind.color.withOpacity(0.35),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          item.kind.emoji,
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }
}
