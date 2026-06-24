import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fruit_catcher/main.dart';
import 'package:fruit_catcher/models/basket.dart';
import 'package:fruit_catcher/models/fruit.dart';

void main() {
  testWidgets('home screen shows title and play button', (WidgetTester tester) async {
    await tester.pumpWidget(const FruitCatcherApp());
    await tester.pump();

    expect(find.text('Fruit Catcher'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  group('Basket', () {
    test('catches a point inside its bounds', () {
      final Basket b = Basket(x: 200);
      // Point right at the center of the basket top
      expect(b.catches(200, 0), isTrue);
      // Point clearly inside
      expect(b.catches(210, 10), isTrue);
    });

    test('rejects a point outside its bounds', () {
      final Basket b = Basket(x: 200);
      // Far left of basket
      expect(b.catches(0, 0), isFalse);
      // Above its catch line
      expect(b.catches(200, -100), isFalse);
    });
  });

  group('FruitKind', () {
    test('bomb is identifiable and has negative points', () {
      expect(FruitKind.bomb.isBomb, isTrue);
      expect(FruitKind.bomb.points, lessThan(0));
    });

    test('all real fruits have positive points', () {
      for (final FruitKind k in FruitKind.values) {
        if (k == FruitKind.bomb) continue;
        expect(k.points, greaterThan(0), reason: '${k.name} should be worth >0');
      }
    });
  });
}
