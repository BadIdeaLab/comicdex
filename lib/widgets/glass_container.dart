import 'dart:ui';

import 'package:concept_nhv/widgets/glass_tokens.dart';
import 'package:flutter/material.dart';

/// A frosted-glass container: blurred, translucent background with a subtle
/// border. [lightweightMode] reduces the blur sigma for lower-end devices
/// (see P46 cross-platform performance validation).
///
/// Prefer the named constructors ([GlassContainer.bar], [GlassContainer.card],
/// [GlassContainer.sheet]) over the base constructor so opacity/blur/radius
/// stay centralized in [GlassTokens] instead of being hardcoded per call site.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 20,
    this.opacity = 0.5,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.lightweightMode = false,
    this.showBorder = true,
  });

  /// Full-width overlay bar (reader top bar / bottom controls / app bars).
  ///
  /// No border: a 4-sided border on an edge-to-edge bar draws a hard line
  /// across the middle of the screen where the blur region ends, which reads
  /// as a floating box rather than a bar blending into the content below.
  factory GlassContainer.bar({
    Key? key,
    required Widget child,
    bool lightweightMode = false,
  }) {
    return GlassContainer(
      key: key,
      blurSigma: GlassTokens.barBlurSigma,
      opacity: GlassTokens.barOpacity,
      borderRadius: GlassTokens.barBorderRadius,
      lightweightMode: lightweightMode,
      showBorder: false,
      child: child,
    );
  }

  /// Rounded card surface (end card, list/grid cards).
  factory GlassContainer.card({
    Key? key,
    required Widget child,
    bool lightweightMode = false,
  }) {
    return GlassContainer(
      key: key,
      blurSigma: GlassTokens.cardBlurSigma,
      opacity: GlassTokens.cardOpacity,
      borderRadius: GlassTokens.cardBorderRadius,
      lightweightMode: lightweightMode,
      child: child,
    );
  }

  /// Bottom-sheet surface — pair with [showGlassModalBottomSheet].
  factory GlassContainer.sheet({
    Key? key,
    required Widget child,
    bool lightweightMode = false,
  }) {
    return GlassContainer(
      key: key,
      blurSigma: GlassTokens.sheetBlurSigma,
      opacity: GlassTokens.sheetOpacity,
      borderRadius: GlassTokens.sheetBorderRadius,
      lightweightMode: lightweightMode,
      child: child,
    );
  }

  final Widget child;
  final double blurSigma;
  final double opacity;
  final BorderRadius borderRadius;
  final bool lightweightMode;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final effectiveSigma = lightweightMode
        ? blurSigma * GlassTokens.lightweightBlurMultiplier
        : blurSigma;
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveSigma, sigmaY: effectiveSigma),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: showBorder
                ? Border.all(color: colorScheme.outline.withValues(alpha: 0.2))
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
