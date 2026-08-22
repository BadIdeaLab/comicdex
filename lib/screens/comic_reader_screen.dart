import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:concept_nhv/application/reader/reader_settings_repository.dart';
import 'package:concept_nhv/models/comic.dart';
import 'package:concept_nhv/services/comic_page_source_resolver.dart';
import 'package:concept_nhv/state/reader_session_model.dart';
import 'package:concept_nhv/state/reader_settings_model.dart';
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

/// Shows one comic, and owns the state for reading it.
///
/// The screen loads the comic itself rather than being handed an already-loaded
/// one. That is what lets [ReaderSessionModel] — and with it the
/// [PageController] — live and die with this route instead of app-wide.
class ComicReaderScreen extends StatefulWidget {
  const ComicReaderScreen({
    super.key,
    required this.comicId,
    this.offline = false,
  });

  final String comicId;

  /// Read from local files instead of the network. Set by the Downloads tab.
  final bool offline;

  @override
  State<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late final ReaderSessionModel _session;
  bool _showEndCard = false;
  Timer? _endCardTimer;

  @override
  void initState() {
    super.initState();
    _session = ReaderSessionModel(
      loadComicDetailUseCase: context.read(),
      loadOfflineComicUseCase: context.read(),
      openComicUseCase: context.read(),
      readerProgressRepository: context.read(),
      readerSettingsRepository: context.read(),
      downloadedLibraryRepository: context.read(),
    );
    _load();
  }

  @override
  void dispose() {
    _endCardTimer?.cancel();
    _session.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _session.open(comicId: widget.comicId, offline: widget.offline);
    if (!mounted || !_session.isReady) return;
    // One frame later, so the PageView exists and its controller is attached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreLastSeenPage();
    });
  }

  void _onPageChanged(int index, ReaderSessionModel session) {
    session.onPageChanged(index, widget.comicId);
    _prefetchSurroundingPages(context, index + 1);

    final isLastPage = index + 1 == session.totalPages;
    if (isLastPage && !_showEndCard) {
      _triggerEndCard(session);
    }
  }

  void _triggerEndCard(ReaderSessionModel session) {
    session.showControlsOverlay();
    setState(() => _showEndCard = true);
    _endCardTimer?.cancel();
    _endCardTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showEndCard = false);
    });
  }

  Future<void> _restoreLastSeenPage() async {
    final lastPage = await _session.loadLastSeenPage(widget.comicId);
    if (!mounted || lastPage == null || lastPage <= 1) return;
    if (_session.currentComic == null) return;

    final targetPage = lastPage.clamp(1, _session.totalPages);
    _session.goToPage(targetPage);

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
            onPressed: () => _session.goToPage(1),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReaderSessionModel>.value(
      value: _session,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<ReaderSessionModel>(
          builder: (context, session, _) {
            return switch (session.loadState) {
              // Both non-ready states keep a back button on screen. The reader
              // has no AppBar and its overlay controls only exist once a comic
              // is loaded, so without one there is no way out of this route.
              ReaderLoadState.loading => const _ReaderMessage(
                child: CircularProgressIndicator(),
              ),
              ReaderLoadState.failed => _ReaderMessage(
                child: _FailureBody(
                  failure: session.failure ?? ReaderLoadFailure.loadFailed,
                  onRetry: _load,
                ),
              ),
              ReaderLoadState.ready => _buildReader(context, session),
            };
          },
        ),
      ),
    );
  }

  Widget _buildReader(BuildContext context, ReaderSessionModel session) {
    return Stack(
      children: [
        // ── Main paged reader ──────────────────────────────────────────────
        // Isolated in its own widget so that page-change notifyListeners()
        // does not rebuild the PageView and flash image placeholders.
        _ComicPageView(comicId: widget.comicId, onPageChanged: _onPageChanged),

        // ── Top bar (fades in with controls) ───────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !session.showControls,
            child: ReaderTopBar(
              visible: session.showControls,
              currentPage: session.currentPage,
              totalPages: session.totalPages,
              numFavorites: session.numFavorites,
            ),
          ),
        ),

        // ── End-of-comic overlay card ──────────────────────────────────────
        ReaderEndCard(visible: _showEndCard),

        // ── Bottom controls overlay ────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !session.showControls,
            child: ReaderBottomControls(
              visible: session.showControls,
              currentPage: session.currentPage,
              totalPages: session.totalPages,
              onPageSliderChanged: (value) => session.goToPage(value.round()),
              onSettingsTap: () => _showReaderSettings(context),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pre-fetch surrounding pages
  // ---------------------------------------------------------------------------

  void _prefetchSurroundingPages(BuildContext context, int currentPage) {
    final comic = _session.currentComic;
    if (comic == null) return;

    final resolver = context.read<ComicPageSourceResolver>();
    final range = context.read<ReaderSettingsModel>().prefetchPageCount;

    final first = (currentPage - range).clamp(1, comic.numPages);
    final last = (currentPage + range).clamp(1, comic.numPages);

    for (int page = first; page <= last; page++) {
      if (page == currentPage) continue;
      final url = resolver.resolvePageUrl(comic: comic, pageNumber: page);
      if (ComicPageSourceResolver.isLocalPath(url)) {
        precacheImage(FileImage(File(url)), context);
        continue;
      }
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  // ---------------------------------------------------------------------------
  // Reader settings bottom sheet
  // ---------------------------------------------------------------------------

  void _showReaderSettings(BuildContext context) {
    final settings = context.read<ReaderSettingsModel>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => ReaderSettingsSheet(model: settings),
    );
  }
}

// ---------------------------------------------------------------------------
// Non-reading states
// ---------------------------------------------------------------------------

/// Centres [child] on the black reader background, with a back button.
class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Center(child: child),
          const Positioned(
            top: 0,
            left: 0,
            child: BackButton(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.failure, required this.onRetry});

  final ReaderLoadFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isMissingDownload = failure == ReaderLoadFailure.notDownloaded;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isMissingDownload ? Icons.download_for_offline_outlined : Icons.error_outline,
            color: Colors.white70,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isMissingDownload
                ? 'This comic is not downloaded, so there is nothing to read '
                      'offline. Download it first, or repair it from the '
                      'Downloads tab.'
                : 'Could not load this comic. Check your connection and try '
                      'again.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          // Retrying a missing download would fail identically every time, so
          // that case only offers the way out.
          if (isMissingDownload)
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go back'),
            )
          else
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Isolated PageView widget
// ---------------------------------------------------------------------------

/// Wraps [PageView.builder] in a [Selector] that only rebuilds when the comic
/// itself changes — NOT on every page turn. This prevents [ReaderPageView]
/// from rebuilding on each [ReaderSessionModel.notifyListeners] call, which
/// would flash image placeholders and produce a visible flicker on tap
/// navigation.
class _ComicPageView extends StatelessWidget {
  const _ComicPageView({required this.comicId, required this.onPageChanged});

  final String comicId;
  final void Function(int index, ReaderSessionModel session) onPageChanged;

  @override
  Widget build(BuildContext context) {
    // Watched, not selected: these change only when the user edits reader
    // settings, which should rebuild the pages.
    final settings = context.watch<ReaderSettingsModel>();

    return Selector<ReaderSessionModel, Comic>(
      selector: (_, session) => session.currentComic!,
      builder: (context, comic, _) {
        final session = context.read<ReaderSessionModel>();
        return PageView.builder(
          controller: session.pageController,
          itemCount: comic.numPages,
          onPageChanged: (index) => onPageChanged(index, session),
          itemBuilder: (context, index) {
            final pageImage = comic.images.pages[index];
            final url = context
                .read<ComicPageSourceResolver>()
                .resolvePageUrl(comic: comic, pageNumber: index + 1);
            return ReaderPageView(
              url: url,
              width: pageImage.w ?? 9,
              height: pageImage.h ?? 16,
              tapZoneRatio: settings.tapZoneRatio,
              onTapZone: (zone) =>
                  _handleTapZone(zone, session, settings.readingDirection),
            );
          },
        );
      },
    );
  }

  void _handleTapZone(
    ReaderTapZone zone,
    ReaderSessionModel session,
    ReadingDirection direction,
  ) {
    final isRtl = direction == ReadingDirection.rtl;
    switch (zone) {
      case ReaderTapZone.left:
        session.goToPage(isRtl ? session.currentPage + 1 : session.currentPage - 1);
      case ReaderTapZone.right:
        session.goToPage(isRtl ? session.currentPage - 1 : session.currentPage + 1);
      case ReaderTapZone.center:
        session.toggleControls();
    }
  }
}
