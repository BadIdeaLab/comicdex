import 'package:flutter/material.dart';

/// Single source of truth for glassmorphism surface values. Change a preset
/// here to retune every screen that uses the matching [GlassContainer]
/// named constructor — screens should never hardcode opacity/blur/radius
/// themselves.
class GlassTokens {
  const GlassTokens._();

  static const double barOpacity = 0.35;
  static const double barBlurSigma = 20;
  static const BorderRadius barBorderRadius = BorderRadius.zero;

  static const double cardOpacity = 0.55;
  static const double cardBlurSigma = 20;
  static const BorderRadius cardBorderRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static const double sheetOpacity = 0.6;
  static const double sheetBlurSigma = 24;
  static const BorderRadius sheetBorderRadius = BorderRadius.vertical(
    top: Radius.circular(24),
  );

  /// Multiplier applied to blurSigma when [GlassContainer.lightweightMode]
  /// is enabled (P46 cross-platform performance validation).
  static const double lightweightBlurMultiplier = 0.4;
}
