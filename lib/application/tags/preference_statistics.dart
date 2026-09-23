import 'dart:math' as math;

/// Lower bound of the Wilson score interval for `successes / trials`.
///
/// Shared by the tag ranking (P79) and the co-occurrence pairs (P81): both
/// divide an observed share by an expected one, and the point estimate alone
/// lets three comics out of 650 beat thirty. The lower bound answers "how
/// much does this share hold up given how little evidence there is", which
/// is exactly the penalty small samples need. Additive smoothing cannot do
/// that job here — it shifts every candidate by the same constant and leaves
/// the order untouched.
double wilsonLowerBound(int successes, int trials, {double z = 1.96}) {
  if (trials <= 0 || successes <= 0) return 0;
  final n = trials.toDouble();
  final observed = successes / n;
  final zSquared = z * z;
  final denominator = 1 + zSquared / n;
  final centre = observed + zSquared / (2 * n);
  final margin =
      z * math.sqrt((observed * (1 - observed) + zSquared / (4 * n)) / n);
  final lower = (centre - margin) / denominator;
  return lower < 0 ? 0 : lower;
}
