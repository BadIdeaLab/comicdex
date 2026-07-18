import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/services/comic_page_source_resolver.dart';
import 'package:concept_nhv/state/comic_reader_model.dart';
import 'package:concept_nhv/widgets/reader/reader_bottom_controls.dart';
import 'package:concept_nhv/widgets/reader/reader_end_card.dart';
import 'package:concept_nhv/widgets/reader/reader_page_view.dart';
import 'package:concept_nhv/widgets/reader/reader_settings_sheet.dart';
import 'package:concept_nhv/widgets/reader/reader_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Public screen widget
// ---------------------------------------------------------------------------

class ComicReaderScreen extends StatefulWidget {
  const ComicReaderScreen({super.key, required this.comicId});

  final String comicId;

  @override
  State<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  bool _showEndCard = false;
  Timer? _endCardTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreLastSeenPage());
  }

  @override
  void dispose() {
    _endCardTimer?.cancel();
    super.dispose();
  }

  void _onPageChanged(int index, ComicReaderModel model) {
    model.onPageChanged(index, widget.comicId);
    _prefetchSurroundingPages(context, index + 1);

    final isLastPage = index + 1 == model.totalPages;
    if (isLastPage && !_showEndCard) {
      _triggerEndCard(model);
    }
  }

  void _triggerEndCard(ComicReaderModel model) {
    model.showControlsOverlay();
    setState(() => _showEndCard = true);
    _endCardTimer?.cancel();
    _endCardTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showEndCard = false);
    });
  }

  Future<void> _restoreLastSeenPage() async {
    final model = context.read<ComicReaderModel>();
    final lastPage = await model.loadLastSeenPage(widget.comicId);
    if (!mounted || lastPage == null || lastPage <= 1) return;

    // Wait until the comic is loaded so numPages is known.
    if (model.currentComic == null) return;
    final targetPage = lastPage.clamp(1, model.totalPages);
    model.goToPage(targetPage);

    if (!mounted) return;
    // Clear any still-queued/showing snackbar first — without this, opening
    // several comics in quick succession queues up one "Resumed from page"
    // message per comic, forcing the user to dismiss each one in turn.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Resumed from page $targetPage'),
          action: SnackBarAction(
            label: 'Go to start',
            onPressed: () => model.goToPage(1),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<ComicReaderModel>(
        builder: (context, model, _) {
          if (model.currentComic == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // ── Main paged reader ──────────────────────────────────────────
              // Isolated in its own widget so that page-change notifyListeners()
              // does not rebuild the PageView and flash image placeholders.
              _ComicPageView(
                comicId: widget.comicId,
                onPageChanged: _onPageChanged,
              ),

              // ── Top bar (fades in with controls) ──────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !model.showControls,
                  child: ReaderTopBar(
                    visible: model.showControls,
                    currentPage: model.currentPage,
                    totalPages: model.totalPages,
                    numFavorites: model.numFavorites,
                  ),
                ),
              ),

              // ── End-of-comic overlay card ─────────────────────────────────
              ReaderEndCard(visible: _showEndCard),

              // ── Bottom controls overlay ────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  ignoring: !model.showControls,
                  child: ReaderBottomControls(
                    visible: model.showControls,
                    currentPage: model.currentPage,
                    totalPages: model.totalPages,
                    onPageSliderChanged: (value) =>
                        model.goToPage(value.round()),
                    onSettingsTap: () => _showReaderSettings(context, model),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pre-fetch surrounding pages
  // ---------------------------------------------------------------------------

  void _prefetchSurroundingPages(BuildContext context, int currentPage) {
    final model = context.read<ComicReaderModel>();
    final comic = model.currentComic;
    if (comic == null) return;

    final resolver = context.read<ComicPageSourceResolver>();
    final headers = model.currentHeaders;
    final range = model.prefetchPageCount;

    final first = (currentPage - range).clamp(1, comic.numPages);
    final last = (currentPage + range).clamp(1, comic.numPages);

    for (int page = first; page <= last; page++) {
      if (page == currentPage) continue;
      final url = resolver.resolvePageUrl(comic: comic, pageNumber: page);
      if (ComicPageSourceResolver.isLocalPath(url)) {
        precacheImage(FileImage(File(url)), context);
        continue;
      }
      precacheImage(CachedNetworkImageProvider(url, headers: headers), context);
    }
  }

  // ---------------------------------------------------------------------------
  // Reader settings bottom sheet
  // ---------------------------------------------------------------------------

  void _showReaderSettings(BuildContext context, ComicReaderModel model) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return ReaderSettingsSheet(model: model);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Isolated PageView widget
// ---------------------------------------------------------------------------

/// Wraps [PageView.builder] in a [Selector] that only rebuilds when the comic
/// itself, tap-zone ratio, or reading direction changes — NOT on every page
/// turn. This prevents [ReaderPageView] from rebuilding on each
/// [ComicReaderModel.notifyListeners] call, which would flash image
/// placeholders and produce a visible flicker on tap navigation.
class _ComicPageView extends StatelessWidget {
  const _ComicPageView({
    required this.comicId,
    required this.onPageChanged,
  });

  final String comicId;
  final void Function(int index, ComicReaderModel model) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Selector<ComicReaderModel,
        ({Comic comic, double tapZoneRatio, ReadingDirection readingDirection})>(
      selector: (_, m) => (
        comic: m.currentComic!,
        tapZoneRatio: m.tapZoneRatio,
        readingDirection: m.readingDirection,
      ),
      builder: (context, data, _) {
        final model = context.read<ComicReaderModel>();
        return PageView.builder(
          controller: model.pageController,
          itemCount: data.comic.numPages,
          onPageChanged: (index) => onPageChanged(index, model),
          itemBuilder: (context, index) {
            final pageImage = data.comic.images.pages[index];
            final url = context
                .read<ComicPageSourceResolver>()
                .resolvePageUrl(comic: data.comic, pageNumber: index + 1);
            return ReaderPageView(
              url: url,
              width: pageImage.w ?? 9,
              height: pageImage.h ?? 16,
              tapZoneRatio: data.tapZoneRatio,
              onTapZone: (zone) => _handleTapZone(zone, model, data.readingDirection),
            );
          },
        );
      },
    );
  }

  void _handleTapZone(
    ReaderTapZone zone,
    ComicReaderModel model,
    ReadingDirection direction,
  ) {
    final isRtl = direction == ReadingDirection.rtl;
    switch (zone) {
      case ReaderTapZone.left:
        model.goToPage(isRtl ? model.currentPage + 1 : model.currentPage - 1);
      case ReaderTapZone.right:
        model.goToPage(isRtl ? model.currentPage - 1 : model.currentPage + 1);
      case ReaderTapZone.center:
        model.toggleControls();
    }
  }
}
