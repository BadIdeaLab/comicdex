import 'package:concept_nhv/application/home/app_shell_navigation_controller.dart';
import 'package:concept_nhv/application/home/home_shell_controller.dart';
import 'package:concept_nhv/screens/bootstrap_screen.dart';
import 'package:concept_nhv/screens/collection_screen.dart';
import 'package:concept_nhv/screens/comic_reader_screen.dart';
import 'package:concept_nhv/screens/home_shell.dart';
import 'package:concept_nhv/screens/settings_screen.dart';
import 'package:concept_nhv/state/comic_feed_model.dart';
import 'package:concept_nhv/state/home_ui_model.dart';
import 'package:concept_nhv/state/download_manager_model.dart';
import 'package:concept_nhv/models/downloads_sort_mode.dart';
import 'package:concept_nhv/widgets/downloads_sort_bottom_sheet.dart';
import 'package:concept_nhv/widgets/glass_container.dart';
import 'package:concept_nhv/widgets/sort_filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter createAppRouter() {
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const BootstrapScreen()),
      ShellRoute(
        builder: (context, state, child) {
          return _AppShellScaffold(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            name: 'index',
            path: '/index',
            builder: (context, state) => const HomeShell(),
          ),
          GoRoute(
            name: 'collection',
            path: '/collection',
            builder: (context, state) {
              final collectionName =
                  state.uri.queryParameters['collectionName'] ?? '';
              return CollectionScreen(collectionName: collectionName);
            },
          ),
        ],
      ),
      GoRoute(
        name: 'third',
        path: '/third',
        builder: (context, state) {
          final comicId = state.uri.queryParameters['id'] ?? '';
          return ComicReaderScreen(comicId: comicId);
        },
      ),
      GoRoute(
        name: 'settings',
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

class _AppShellScaffold extends StatelessWidget {
  const _AppShellScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      floatingActionButton: Consumer<HomeUiModel>(
        builder: (context, homeUiModel, child) {
          return switch (homeUiModel.navigationIndex) {
            0 => _SortFilterFab(),
            1 => _DownloadsSortFab(),
            _ => const SizedBox.shrink(),
          };
        },
      ),
      bottomNavigationBar: Consumer<HomeUiModel>(
        builder: (context, homeUiModel, child) {
          return GlassContainer.bar(
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: homeUiModel.navigationIndex,
              onDestinationSelected: (index) =>
                  _handleDestinationSelected(context, index),
              destinations: const <Widget>[
                NavigationDestination(
                  selectedIcon: Icon(Icons.home),
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                NavigationDestination(
                  selectedIcon: Icon(Icons.download),
                  icon: Icon(Icons.download_outlined),
                  label: 'Downloads',
                ),
                NavigationDestination(
                  selectedIcon: Icon(Icons.folder),
                  icon: Icon(Icons.folder_outlined),
                  label: 'Collections',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDestinationSelected(
    BuildContext context,
    int index,
  ) async {
    final result = await context
        .read<AppShellNavigationController>()
        .handleDestinationSelected(index);

    if (context.mounted) {
      if (result.statusMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.statusMessage!),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      context.goNamed('index');
      HapticFeedback.lightImpact();
    }
  }
}

class _DownloadsSortFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadManagerModel>(
      builder: (context, model, _) {
        final hasNonDefaultSort =
            model.downloadsSortMode != DownloadsSortMode.latestDownloaded ||
            model.downloadsSortDirection != DownloadsSortDirection.descending;
        return Badge(
          isLabelVisible: hasNonDefaultSort,
          child: FloatingActionButton(
            tooltip: 'Sort Downloads',
            onPressed: () => _openDownloadsSort(context),
            child: const Icon(Icons.tune),
          ),
        );
      },
    );
  }

  Future<void> _openDownloadsSort(BuildContext context) async {
    await DownloadsSortBottomSheet.show(context);
  }
}

/// FAB that opens the sort & filter sheet.
///
/// Shows a badge dot when any filter is active (sort type or tag filters).
class _SortFilterFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ComicFeedModel>(
      builder: (context, feedModel, _) {
        final hasActiveFilters = feedModel.sortByPopularType != null ||
            feedModel.tagFilters.isNotEmpty;

        return Badge(
          isLabelVisible: hasActiveFilters,
          child: FloatingActionButton(
            tooltip: 'Sort & Filter',
            onPressed: () => _openSortFilter(context),
            child: const Icon(Icons.tune),
          ),
        );
      },
    );
  }

  Future<void> _openSortFilter(BuildContext context) async {
    final applied = await SortFilterBottomSheet.show(context);
    if (!context.mounted || !applied) return;
    await context.read<HomeShellController>().applySortAndFilters();
  }
}
