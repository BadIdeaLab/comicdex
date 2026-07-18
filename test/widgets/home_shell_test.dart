import 'package:concept_nhv/models/collection_summary.dart';
import 'package:concept_nhv/widgets/collection_grid_sliver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows collection overview summaries', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              CollectionGridSliver(
                collections: <CollectionSummary>[
                  CollectionSummary(
                    collectionName: 'History',
                    collectedCount: 1,
                    thumbnailUrl: 'https://placehold.co/10x10/png?text=History',
                    thumbnailWidth: 10,
                    thumbnailHeight: 10,
                  ),
                  CollectionSummary(
                    collectionName: 'Favorite',
                    collectedCount: 2,
                    thumbnailUrl:
                        'https://placehold.co/10x10/png?text=Favorite',
                    thumbnailWidth: 10,
                    thumbnailHeight: 10,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Favorite'), findsOneWidget);
    expect(find.text('2 collected'), findsOneWidget);
  });
}
