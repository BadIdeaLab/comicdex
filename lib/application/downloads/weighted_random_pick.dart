import 'dart:math';

/// Picks one item at random, favouring the ones read longest ago.
///
/// Uniform random is why the shuffle button felt repetitive: drawing `k`
/// times from `N` comics hits a repeat with probability around `k²/2N`, so a
/// 500-comic library repeats about four times in twenty draws. That is not a
/// flaw in the randomness, it is what randomness does — so the fix is to stop
/// being uniform.
///
/// The weight is the item's **rank**, not a function of elapsed time: after
/// sorting by [lastReadAt] ascending, the stalest item gets weight `n` and
/// the most recently read gets `1`. A time-decay curve would need a half-life
/// constant nobody can justify, and would be thrown off by imported or
/// clock-skewed timestamps; a rank only needs the order to be right.
///
/// Nothing is stored and nothing is decremented — the weights are derived on
/// each call from timestamps the reader already maintains.
///
/// Every item keeps a non-zero chance by construction. That is a requirement,
/// not a side effect: the point is to stop repeats being *likely*, not to
/// stop them happening.
T? pickByReadingStaleness<T>(
  List<T> items, {
  required DateTime? Function(T item) lastReadAt,
  required String Function(T item) tieBreaker,
  required Random random,
}) {
  if (items.isEmpty) return null;
  if (items.length == 1) return items.first;

  // Never-read first: something downloaded and not yet opened is the best
  // thing this button can offer.
  final ordered = List<T>.of(items)
    ..sort((a, b) {
      final left = lastReadAt(a);
      final right = lastReadAt(b);
      if (left != null || right != null) {
        if (left == null) return -1;
        if (right == null) return 1;
        final byTime = left.compareTo(right);
        if (byTime != 0) return byTime;
      }
      // Ties would otherwise leave the order to the input, which makes the
      // outcome depend on how the list happened to be built.
      return tieBreaker(a).compareTo(tieBreaker(b));
    });

  final count = ordered.length;
  var roll = random.nextInt(count * (count + 1) ~/ 2);
  for (var index = 0; index < count; index++) {
    final weight = count - index;
    if (roll < weight) return ordered[index];
    roll -= weight;
  }
  return ordered.last;
}
