import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_extent_grid/prototype_extent_grid.dart';
import 'package:prototype_extent_grid_example/main.dart';

void main() {
  testWidgets('every column mode lays out without overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Shakshuka'), findsOneWidget);

    for (final String mode in <String>['2 columns', 'Fit', 'Max 240']) {
      await tester.tap(find.text(mode));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: mode);
      expect(find.byType(RecipeCard), findsWidgets);
    }
  });

  testWidgets('rows grow with the text size', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    final RenderSliverPrototypeExtentGrid grid = tester
        .renderObject<RenderSliverPrototypeExtentGrid>(
          find.byType(SliverPrototypeExtentGrid),
        );
    final double before = grid.cellSize.height;

    await tester.drag(find.byType(Slider), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(grid.cellSize.height, greaterThan(before));
    expect(tester.takeException(), isNull);
  });
}
