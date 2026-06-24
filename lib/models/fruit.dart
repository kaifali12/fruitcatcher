import 'package:flutter/material.dart';

/// What category an item belongs to. Used by levels to filter spawns.
// enum ItemCategory { fruit, vegetable, bomb }
enum ItemCategory { fruit, bomb }

/// Every catchable thing in the game — five fruits, five vegetables, and a
/// bomb. Each variant knows its emoji, tint color, point value and category.
enum FruitKind {
  // ── Fruits (Level 1) ──
  cherry    ('🍒', Color(0xFFE63946), 10, ItemCategory.fruit),
  apple     ('🍎', Color(0xFFEF476F),  8, ItemCategory.fruit),
  stawberry ('🍓', Color(0xFFE63946),  6, ItemCategory.fruit),
  grape     ('🍇', Color(0xFF9D4EDD), 12, ItemCategory.fruit),
  watermelon('🍉', Color(0xFF06D6A0), 15, ItemCategory.fruit),
  kiwi      ('🥝', Color(0xFF7AC943), 15, ItemCategory.fruit),
  pineapple ('🍍', Color(0xFFF4C542), 15, ItemCategory.fruit),
  coconut   ('🥥', Color(0xFF6F4E37), 15, ItemCategory.fruit),
  nashpati  ('🍐', Color(0xFFC5E384), 15, ItemCategory.fruit),
  mango     ('🥭', Color(0xFFFFB300), 15, ItemCategory.fruit),
  

  // ── Vegetables (Level 2) ──
  // carrot    ('🥕', Color(0xFFFF8C42), 12, ItemCategory.vegetable),
  // broccoli  ('🥦', Color(0xFF52B788), 14, ItemCategory.vegetable),
  // corn      ('🌽', Color(0xFFFFE066), 10, ItemCategory.vegetable),
  // tomato    ('🍅', Color(0xFFD62828), 11, ItemCategory.vegetable),
  // brinjal   ('🍆', Color(0xFF6F2DA8), 13, ItemCategory.vegetable),

  // ── Hazard ──
  bomb      ('💣', Color(0xFF2B2B2B), -1, ItemCategory.bomb);

  const FruitKind(this.emoji, this.color, this.points, this.category);
  final String emoji;
  final Color color;
  final int points;
  final ItemCategory category;

  bool get isBomb => category == ItemCategory.bomb;
  bool get isFruit => category == ItemCategory.fruit;
  // bool get isVegetable => category == ItemCategory.vegetable;
}

/// A single falling item on the playfield. Position is the *center* of the
/// item in screen coordinates; the game controller advances [y] each tick
/// based on [speed].
class FallingItem {
  FallingItem({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.speed,
    this.rotation = 0,
    this.rotationSpeed = 0,
  });

  final int id;
  final FruitKind kind;
  double x;
  double y;
  double speed;       // px/sec
  double rotation;    // radians
  double rotationSpeed;

  FallingItem copyWith({double? x, double? y, double? rotation}) =>
      FallingItem(
        id: id,
        kind: kind,
        x: x ?? this.x,
        y: y ?? this.y,
        speed: speed,
        rotation: rotation ?? this.rotation,
        rotationSpeed: rotationSpeed,
      );
}
