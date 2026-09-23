import 'package:concept_nhv/widgets/favorites_tag_filter_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('pushes Favorites with the tag id as a filter', (tester) async {
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => openFavoritesFilteredByTag(context, 2937),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/collection',
          builder: (context, state) => const Scaffold(body: Text('collection')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('collection'), findsOneWidget);
    final uri = router.state.uri;
    expect(uri.path, '/collection');
    expect(uri.queryParameters['collectionName'], 'Favorite');
    expect(uri.queryParameters['tagId'], '2937');
  });
}
