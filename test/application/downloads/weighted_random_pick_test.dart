import 'dart:math';

import 'package:concept_nhv/application/downloads/weighted_random_pick.dart';
import 'package:flutter_test/flutter_test.dart';

class _Item {
  const _Item(this.id, this.lastReadAt);

  final String id;
  final DateTime? lastReadAt;
}

/// Returns whatever roll the test asks for, so the assertions are about the
/// weighting rather than about one lucky draw.
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final int value;
  int? lastBound;

  @override
  int nextInt(int max) {
    lastBound = max;
    return value % max;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  group('pickByReadingStaleness', () {
    String? pick(List<_Item> items, int roll) {
      return pickByReadingStaleness<_Item>(
        items,
        lastReadAt: (item) => item.lastReadAt,
        tieBreaker: (item) => item.id,
        random: _FixedRandom(roll),
      )?.id;
    }

    final never = _Item('never', null);
    final old = _Item('old', DateTime(2025, 1, 1));
    final recent = _Item('recent', DateTime(2026, 9, 24));

    test('returns null for an empty library', () {
      expect(pick(<_Item>[], 0), isNull);
    });

    test('returns the only item there is', () {
      expect(pick(<_Item>[recent], 0), 'recent');
    });

    test('weights the stalest item twice as heavily as the freshest', () {
      // Two items: weights 2 and 1, so rolls 0..2 across a total of 3.
      final picks = <String?>[for (var roll = 0; roll < 3; roll++) pick(<_Item>[recent, never], roll)];
      expect(picks, <String>['never', 'never', 'recent']);
    });

    test('still reaches the most recently read one', () {
      // The requirement in the user's words: "not that they should never
      // appear". A weighting that excluded anything would fail here, and
      // excluding is exactly the shortcut someone might reach for later.
      final picks = <String?>[
        for (var roll = 0; roll < 6; roll++)
          pick(<_Item>[never, old, recent], roll),
      ];
      expect(picks, contains('recent'));
    });

    test('orders never-read, then oldest, then most recent', () {
      // Weights 3, 2, 1 over a total of 6.
      final picks = <String?>[
        for (var roll = 0; roll < 6; roll++)
          pick(<_Item>[recent, never, old], roll),
      ];
      expect(picks, <String>[
        'never',
        'never',
        'never',
        'old',
        'old',
        'recent',
      ]);
    });

    test('rolls over the whole weight total', () {
      final random = _FixedRandom(0);
      pickByReadingStaleness<_Item>(
        <_Item>[never, old, recent],
        lastReadAt: (item) => item.lastReadAt,
        tieBreaker: (item) => item.id,
        random: random,
      );
      // 3 + 2 + 1: a bound of 3 would mean the weights were never applied.
      expect(random.lastBound, 6);
    });

    test('breaks ties deterministically so a fresh install is stable', () {
      final a = _Item('a', null);
      final b = _Item('b', null);
      expect(pick(<_Item>[b, a], 0), 'a');
      expect(pick(<_Item>[a, b], 0), 'a');
    });
  });
}
