import '../game/game_constants.dart';

/// Simple model that holds the basket's horizontal position. The vertical
/// position is fixed near the bottom of the playfield.
class Basket {
  Basket({required this.x});

  /// X coordinate of the *center* of the basket.
  double x;

  double get width => GameConstants.basketWidth;
  double get height => GameConstants.basketHeight;

  /// Returns true if a point (px, py) lies inside the basket's catch box.
  bool catches(double px, double py) {
    final double left = x - width / 2;
    final double right = x + width / 2;
    final double top = py - height / 2;
    return px >= left && px <= right && py >= top;
  }
}
