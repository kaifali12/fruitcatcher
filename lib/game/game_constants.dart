import 'package:flutter/material.dart';

import '../models/fruit.dart';

/// Tunable constants for the Fruit Catcher game.
class GameConstants {
  GameConstants._();

  // ── Basket ──
  static const double basketWidth = 130;
  static const double basketHeight = 76;
  static const double basketBottomPadding = 32;
  static const double basketMoveSpeed = 520; // px/sec when using keys

  // ── Falling items ── (BIGGER per request)
  static const double itemSize = 80;
  static const double itemEmojiSize = 56;
  static const double minFallSpeed = 200; // px/sec
  static const double maxFallSpeed = 520; // px/sec
  static const double bombChance = 0.18;

  /// Time between item spawns at level 1 (seconds)
  static const double initialSpawnInterval = 1.1;
  static const double minSpawnInterval = 0.40;

  // ── Lives ──
  static const int startingLives = 3;
  static const int maxLives = 3;

  // ── Palette ──
  static const Color skyTop = Color(0xFF1A1E45);
  static const Color skyBottom = Color(0xFF0A0B1F);
  static const Color basketWood = Color(0xFFB07248);
  static const Color basketWoodDark = Color(0xFF7A4E2D);
  static const Color basketRim = Color(0xFFE4A66B);
  static const Color basketHandle = Color(0xFF8B5A2B);

  // ── Persistence keys ──
  static const String prefsHighScoreKey = 'fc_high_score';
  static const String prefsHighLevelKey = 'fc_high_level';
  static const String prefsSoundKey = 'fc_sound_enabled';
  static const String prefsMusicKey = 'fc_music_enabled';
}

/// A level: which categories spawn, how fast, and what target score advances
/// you to the next one.
class LevelDef {
  const LevelDef({
    required this.index,
    required this.name,
    required this.description,
    required this.allowed,
    required this.targetScore,
    required this.spawnInterval,
    required this.speedBonus,
    required this.bombChance,
    required this.accentColor,
  });

  final int index;
  final String name;
  final String description;
  final Set<ItemCategory> allowed;
  final int targetScore;       // score needed to advance to NEXT level
  final double spawnInterval;  // base spawn interval (sec)
  final double speedBonus;     // px/sec added to falling speed range
  final double bombChance;
  final Color accentColor;
}

/// Master ordered list of levels. Add more entries to extend the game.
const List<LevelDef> kLevels = <LevelDef>[
  LevelDef(
    index: 1,
    name: 'Orchard',
    description: 'Catch the fruits.',
    allowed: <ItemCategory>{ItemCategory.fruit, ItemCategory.bomb},
    targetScore: 100,
    spawnInterval: 1.10,
    speedBonus: 0,
    bombChance: 0.14,
    accentColor: Color(0xFFEF476F),
  ),
  // LevelDef(
  //   index: 2,
  //   name: 'Garden',
  //   description: 'Vegetables join the harvest.',
  //   // allowed: <ItemCategory>{ItemCategory.vegetable, ItemCategory.bomb},
  //   targetScore: 250,
  //   spawnInterval: 0.95,
  //   speedBonus: 40,
  //   bombChance: 0.18,
  //   accentColor: Color(0xFF52B788),
  // ),
  LevelDef(
    index: 3,
    name: 'Market',
    description: 'Fruits AND veggies, faster.',
    allowed: <ItemCategory>{
      ItemCategory.fruit,
      // ItemCategory.vegetable,
      ItemCategory.bomb
    },
    targetScore: 450,
    spawnInterval: 0.80,
    speedBonus: 80,
    bombChance: 0.20,
    accentColor: Color(0xFFFFD166),
  ),
  LevelDef(
    index: 4,
    name: 'Storm',
    description: 'Chaos. Stay sharp.',
    allowed: <ItemCategory>{
      ItemCategory.fruit,
      // ItemCategory.vegetable,
      ItemCategory.bomb
    },
    targetScore: 700,
    spawnInterval: 0.65,
    speedBonus: 130,
    bombChance: 0.24,
    accentColor: Color(0xFF9D4EDD),
  ),
  LevelDef(
    index: 5,
    name: 'Frenzy',
    description: 'Endless mode — survive!',
    allowed: <ItemCategory>{
      ItemCategory.fruit,
      // ItemCategory.vegetable,
      ItemCategory.bomb
    },
    targetScore: 9999999,
    spawnInterval: 0.50,
    speedBonus: 200,
    bombChance: 0.28,
    accentColor: Color(0xFFFF6B6B),
  ),
];

/// Returns the level that the player is currently in, given their score.
LevelDef levelForScore(int score) {
  for (int i = 0; i < kLevels.length; i++) {
    final LevelDef l = kLevels[i];
    final int prevTarget = i == 0 ? 0 : kLevels[i - 1].targetScore;
    if (score >= prevTarget && score < l.targetScore) return l;
  }
  return kLevels.last;
}
