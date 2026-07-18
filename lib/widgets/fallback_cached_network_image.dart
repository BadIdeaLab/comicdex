import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:concept_nhv/services/image_url_resolver.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

typedef CachedImageBuilder =
    Widget Function(
      BuildContext context,
      String imageUrl,
      Map<String, String>? headers,
      Widget Function(BuildContext context, String url)? placeholderBuilder,
      Widget Function(BuildContext context, String url, Object error)?
      errorBuilder,
    );

class FallbackCachedNetworkImage extends StatefulWidget {
  const FallbackCachedNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.imageBuilder,
    this.imageUrlResolver,
  });

  final String url;
  final int width;
  final int height;
  final CachedImageBuilder? imageBuilder;
  final ImageUrlResolver? imageUrlResolver;

  @override
  State<FallbackCachedNetworkImage> createState() =>
      _FallbackCachedNetworkImageState();
}

class _FallbackCachedNetworkImageState
    extends State<FallbackCachedNetworkImage> {
  static const bool _demoMode = false;

  late List<String> _candidateUrls;
  int _currentIndex = 0;
  bool _retryScheduled = false;

  String get _currentUrl => _candidateUrls[_currentIndex];

  @override
  void initState() {
    super.initState();
    _resetFallbackCandidates();
  }

  @override
  void didUpdateWidget(covariant FallbackCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _resetFallbackCandidates();
    }
  }

  void _resetFallbackCandidates() {
    final resolver = widget.imageUrlResolver ?? _readResolverFromContext();
    _candidateUrls = resolver.buildFallbackImageUrls(widget.url);
    _currentIndex = 0;
    _retryScheduled = false;
  }

  ImageUrlResolver _readResolverFromContext() {
    try {
      return context.read<ImageUrlResolver>();
    } on ProviderNotFoundException {
      return const ImageUrlResolver();
    }
  }

  bool get _hasNextCandidate => _currentIndex + 1 < _candidateUrls.length;

  void _scheduleNextFallbackAttempt() {
    if (_retryScheduled || !_hasNextCandidate || !mounted) {
      return;
    }

    _retryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hasNextCandidate) {
        return;
      }
      setState(() {
        _currentIndex += 1;
        _retryScheduled = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final headers = context.watch<ComicReaderModel?>()?.currentHeaders;
    final imageBuilder = widget.imageBuilder ?? _defaultCachedImageBuilder;

    return Stack(
      children: <Widget>[
        imageBuilder(
          context,
          _currentUrl,
          headers,
          _buildLoadingState,
          _buildErrorState,
        ),
        if (_demoMode)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
      ],
    );
  }

  Widget _defaultCachedImageBuilder(
    BuildContext context,
    String imageUrl,
    Map<String, String>? headers,
    Widget Function(BuildContext context, String url)? placeholderBuilder,
    Widget Function(BuildContext context, String url, Object error)?
    errorBuilder,
  ) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: headers,
      placeholder: placeholderBuilder,
      errorWidget: errorBuilder,
    );
  }

  Widget _buildLoadingState(BuildContext context, String url) {
    return AspectRatio(
      aspectRatio: widget.width / widget.height,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(BuildContext context, String url, Object error) {
    return AspectRatio(
      aspectRatio: widget.width / widget.height,
      child: Builder(
        builder: (context) {
          if (_hasNextCandidate) {
            _scheduleNextFallbackAttempt();
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: IconButton(
              tooltip: 'Copy image URL',
              iconSize: 24,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
              icon: const Icon(Icons.broken_image_outlined, color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
