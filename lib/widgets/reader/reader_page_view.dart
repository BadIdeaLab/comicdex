import 'dart:io';

import 'package:concept_nhv/services/comic_page_source_resolver.dart';
import 'package:concept_nhv/widgets/fallback_cached_network_image.dart';
import 'package:flutter/material.dart';

/// Which horizontal region of a reader page was tapped.
enum ReaderTapZone { left, center, right }

/// Single page widget with pinch-to-zoom and tap-zone navigation.
///
/// Tapping within [tapZoneRatio] of either edge reports [ReaderTapZone.left]
/// / [ReaderTapZone.right] via [onTapZone]; taps elsewhere report
/// [ReaderTapZone.center]. Tap zones are disabled while zoomed in.
class ReaderPageView extends StatefulWidget {
  const ReaderPageView({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.tapZoneRatio,
    required this.onTapZone,
  });

  final String url;
  final int width;
  final int height;
  final double tapZoneRatio;
  final void Function(ReaderTapZone zone) onTapZone;

  @override
  State<ReaderPageView> createState() => _ReaderPageViewState();
}

class _ReaderPageViewState extends State<ReaderPageView> {
  final TransformationController _transformController =
      TransformationController();
  bool _isPanEnabled = false;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final panEnabled = scale > 1.01;
    if (panEnabled != _isPanEnabled) {
      setState(() => _isPanEnabled = panEnabled);
    }
  }

  bool get _isZoomed => _isPanEnabled;

  void _handleTapUp(TapUpDetails details) {
    // Tapping while zoomed in should not trigger page navigation, only
    // toggling the controls is allowed via the centre tap.
    if (_isZoomed) return;

    final width = context.size?.width ?? 1;
    final dx = details.localPosition.dx;

    if (dx < width * widget.tapZoneRatio) {
      widget.onTapZone(ReaderTapZone.left);
    } else if (dx > width * (1 - widget.tapZoneRatio)) {
      widget.onTapZone(ReaderTapZone.right);
    } else {
      widget.onTapZone(ReaderTapZone.center);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: _handleTapUp,
      child: InteractiveViewer(
        transformationController: _transformController,
        panEnabled: _isPanEnabled,
        minScale: 1.0,
        maxScale: 4.0,
        child: Center(
          child: ComicPageSourceResolver.isLocalPath(widget.url)
              ? Image.file(
                  File(widget.url),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                )
              : FallbackCachedNetworkImage(
                  url: widget.url,
                  width: widget.width,
                  height: widget.height,
                ),
        ),
      ),
    );
  }
}
