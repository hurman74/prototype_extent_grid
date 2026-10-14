import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_extent_grid/prototype_extent_grid.dart';

// The default test surface is 800 x 600 logical pixels.

Widget host(
  Widget child, {
  TextDirection textDirection = TextDirection.ltr,
  double textScale = 1.0,
}) {
  return Directionality(
    textDirection: textDirection,
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        textScaler: TextScaler.linear(textScale),
      ),
      child: child,
    ),
  );
}

Widget item(int index) =>
    SizedBox.expand(key: ValueKey<int>(index), child: Text('$index'));

Widget gridView({
  required Widget prototype,
  PrototypeGridColumns columns = const PrototypeGridColumns.fit(),
  int? itemCount = 100,
  double mainAxisSpacing = 0,
  double crossAxisSpacing = 0,
  Axis scrollDirection = Axis.vertical,
  ScrollController? controller,
  NullableIndexedWidgetBuilder? itemBuilder,
}) {
  return PrototypeExtentGridView.builder(
    controller: controller,
    scrollDirection: scrollDirection,
    columns: columns,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    prototypeItem: prototype,
    itemCount: itemCount,
    itemBuilder:
        itemBuilder ?? (BuildContext context, int index) => item(index),
  );
}

Rect rectOf(WidgetTester tester, int index) =>
    tester.getRect(find.byKey(ValueKey<int>(index)));

RenderSliverPrototypeExtentGrid gridRenderObject(WidgetTester tester) =>
    tester.renderObject<RenderSliverPrototypeExtentGrid>(
      find.byType(SliverPrototypeExtentGrid, skipOffstage: false),
    );

/// A prototype whose height is half of the width it is given.
Widget halfAsTall() => LayoutBuilder(
  builder: (BuildContext context, BoxConstraints constraints) =>
      SizedBox(height: constraints.maxWidth / 2),
);

void main() {
  group('PrototypeGridColumns.count', () {
    testWidgets('cells share the width and take the prototype height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            prototype: const SizedBox(height: 50),
          ),
        ),
      );

      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 200, 50));
      expect(rectOf(tester, 3), const Rect.fromLTWH(600, 0, 200, 50));
      expect(rectOf(tester, 5), const Rect.fromLTWH(200, 50, 200, 50));
      expect(gridRenderObject(tester).crossAxisCount, 4);
      expect(gridRenderObject(tester).cellSize, const Size(200, 50));
    });

    testWidgets('the prototype is measured at the column width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            prototype: halfAsTall(),
          ),
        ),
      );

      expect(rectOf(tester, 4), const Rect.fromLTWH(0, 100, 200, 100));
    });

    testWidgets('spacing is applied between rows and columns', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            mainAxisSpacing: 10,
            crossAxisSpacing: 20,
            prototype: const SizedBox(height: 50),
          ),
        ),
      );

      // (800 - 3 * 20) / 4 = 185
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 185, 50));
      expect(rectOf(tester, 5), const Rect.fromLTWH(205, 60, 185, 50));
    });

    test('rejects a non-positive count', () {
      expect(() => PrototypeGridColumns.count(0), throwsAssertionError);
    });
  });

  group('PrototypeGridColumns.maxExtent', () {
    testWidgets('uses the fewest columns that respect the maximum', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.maxExtent(250),
            prototype: halfAsTall(),
          ),
        ),
      );

      // 3 columns would be 266.7 wide, so 4 columns of 200.
      expect(gridRenderObject(tester).crossAxisCount, 4);
      expect(rectOf(tester, 4), const Rect.fromLTWH(0, 100, 200, 100));
    });

    testWidgets('an exact fit does not add a column', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.maxExtent(200),
            prototype: const SizedBox(height: 10),
          ),
        ),
      );

      expect(gridRenderObject(tester).crossAxisCount, 4);
    });

    testWidgets('accounts for spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.maxExtent(200),
            crossAxisSpacing: 10,
            prototype: const SizedBox(height: 10),
          ),
        ),
      );

      // 4 columns: (800 - 30) / 4 = 192.5 <= 200; 3 would be 260.
      expect(gridRenderObject(tester).crossAxisCount, 4);
      expect(gridRenderObject(tester).cellSize.width, 192.5);
    });

    testWidgets('never uses fewer than one column', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.maxExtent(5000),
            prototype: const SizedBox(height: 10),
          ),
        ),
      );

      expect(gridRenderObject(tester).crossAxisCount, 1);
      expect(gridRenderObject(tester).cellSize, const Size(800, 10));
    });

    test('rejects a non-positive extent', () {
      expect(() => PrototypeGridColumns.maxExtent(0), throwsAssertionError);
    });
  });

  group('PrototypeGridColumns.fit', () {
    testWidgets('without stretch, cells keep the prototype size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(gridView(prototype: const SizedBox(width: 150, height: 40))),
      );

      expect(gridRenderObject(tester).crossAxisCount, 5);
      expect(rectOf(tester, 4), const Rect.fromLTWH(600, 0, 150, 40));
      expect(rectOf(tester, 5), const Rect.fromLTWH(0, 40, 150, 40));
    });

    testWidgets('counts spacing when deciding how many columns fit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            crossAxisSpacing: 50,
            prototype: const SizedBox(width: 150, height: 40),
          ),
        ),
      );

      // 4 * 150 + 3 * 50 = 750 fits, 5 * 150 + 4 * 50 = 950 does not.
      expect(gridRenderObject(tester).crossAxisCount, 4);
      expect(rectOf(tester, 1), const Rect.fromLTWH(200, 0, 150, 40));
    });

    testWidgets('an exact fit is not lost to rounding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            crossAxisSpacing: 0.1,
            // 3 * 266.6 + 2 * 0.1 = 800
            prototype: const SizedBox(width: 266.6, height: 40),
          ),
        ),
      );

      expect(gridRenderObject(tester).crossAxisCount, 3);
    });

    testWidgets('with stretch, cells fill the row and are re-measured', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.fit(stretch: true),
            prototype: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  SizedBox(width: 150, height: constraints.minWidth / 4),
            ),
          ),
        ),
      );

      // 5 columns fit; stretched to 160, so the prototype is 40 tall.
      expect(gridRenderObject(tester).crossAxisCount, 5);
      expect(rectOf(tester, 5), const Rect.fromLTWH(0, 40, 160, 40));
    });

    testWidgets('a prototype wider than the viewport gives one column', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(gridView(prototype: const SizedBox(width: 1000, height: 30))),
      );

      expect(gridRenderObject(tester).crossAxisCount, 1);
      expect(rectOf(tester, 1), const Rect.fromLTWH(0, 30, 800, 30));
    });

    testWidgets('a zero-width prototype without spacing gives one column', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(gridView(prototype: const SizedBox(width: 0, height: 30))),
      );

      expect(tester.takeException(), isNull);
      expect(gridRenderObject(tester).crossAxisCount, 1);
    });
  });

  group('layout', () {
    testWidgets('a zero-height prototype does not throw', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(3),
            prototype: const SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(gridRenderObject(tester).cellSize.height, 0);
    });

    testWidgets('an empty grid lays out with no scroll extent', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            itemCount: 0,
            columns: const PrototypeGridColumns.count(3),
            prototype: const SizedBox(height: 50),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final ScrollPosition position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.maxScrollExtent, 0);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('the scroll extent is exact from the first frame', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            mainAxisSpacing: 10,
            prototype: const SizedBox(height: 50),
          ),
        ),
      );

      // 25 rows of 50 with 24 gaps of 10 = 1490, minus the 600 viewport.
      final ScrollPosition position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.maxScrollExtent, 890);
    });

    testWidgets('only builds visible items', (WidgetTester tester) async {
      final Set<int> built = <int>{};
      await tester.pumpWidget(
        host(
          gridView(
            itemCount: 10000,
            columns: const PrototypeGridColumns.count(4),
            prototype: const SizedBox(height: 100),
            itemBuilder: (BuildContext context, int index) {
              built.add(index);
              return item(index);
            },
          ),
        ),
      );

      // 6 visible rows plus the default cache extent of 250 (3 rows).
      expect(built.length, lessThanOrEqualTo(4 * 9));
      expect(built, isNot(contains(1000)));
    });

    testWidgets('scrolling reaches the last item', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          gridView(
            controller: controller,
            columns: const PrototypeGridColumns.count(4),
            prototype: const SizedBox(height: 50),
          ),
        ),
      );

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();

      // Row 24 starts at 1200; scrolled by 650, so it is at 550.
      expect(rectOf(tester, 99), const Rect.fromLTWH(600, 550, 200, 50));
    });

    testWidgets('works with an unbounded builder', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          gridView(
            itemCount: null,
            columns: const PrototypeGridColumns.count(2),
            prototype: const SizedBox(height: 100),
            itemBuilder: (BuildContext context, int index) =>
                index < 7 ? item(index) : null,
          ),
        ),
      );

      expect(rectOf(tester, 6), const Rect.fromLTWH(0, 300, 400, 100));
      expect(find.byKey(const ValueKey<int>(7)), findsNothing);
    });

    testWidgets('right-to-left grids start at the right', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          textDirection: TextDirection.rtl,
          gridView(
            columns: const PrototypeGridColumns.count(4),
            prototype: const SizedBox(height: 50),
          ),
        ),
      );

      expect(rectOf(tester, 0), const Rect.fromLTWH(600, 0, 200, 50));
      expect(rectOf(tester, 4), const Rect.fromLTWH(600, 50, 200, 50));
    });

    testWidgets('horizontal grids measure the prototype width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            scrollDirection: Axis.horizontal,
            columns: const PrototypeGridColumns.count(3),
            prototype: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) =>
                  SizedBox(width: constraints.maxHeight / 2),
            ),
          ),
        ),
      );

      // 600 / 3 = 200 tall, so the prototype is 100 wide.
      expect(gridRenderObject(tester).cellSize, const Size(100, 200));
      expect(rectOf(tester, 1), const Rect.fromLTWH(0, 200, 100, 200));
      expect(rectOf(tester, 3), const Rect.fromLTWH(100, 0, 100, 200));
    });

    testWidgets('horizontal fit uses the prototype height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            scrollDirection: Axis.horizontal,
            prototype: const SizedBox(width: 120, height: 250),
          ),
        ),
      );

      expect(gridRenderObject(tester).crossAxisCount, 2);
      expect(rectOf(tester, 2), const Rect.fromLTWH(120, 0, 120, 250));
    });

    testWidgets('works inside a CustomScrollView with other slivers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: 70)),
              SliverPrototypeExtentGrid.list(
                columns: const PrototypeGridColumns.count(2),
                mainAxisSpacing: 5,
                prototypeItem: const SizedBox(height: 30),
                children: List<Widget>.generate(6, item),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 40, key: ValueKey<String>('footer')),
              ),
            ],
          ),
        ),
      );

      expect(rectOf(tester, 2), const Rect.fromLTWH(0, 105, 400, 30));
      // 3 rows: 3 * 30 + 2 * 5 = 100, after the 70 header.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey<String>('footer'))),
        const Offset(0, 170),
      );
    });

    testWidgets('shrink-wraps to the rows it needs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          Align(
            alignment: Alignment.topLeft,
            child: PrototypeExtentGridView(
              shrinkWrap: true,
              columns: const PrototypeGridColumns.count(3),
              prototypeItem: const SizedBox(height: 40),
              children: List<Widget>.generate(7, item),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(PrototypeExtentGridView)),
        const Size(800, 120),
      );
    });
  });

  group('updates', () {
    testWidgets('a new prototype relayouts the grid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            prototype: const SizedBox(height: 50),
          ),
        ),
      );
      expect(rectOf(tester, 4).top, 50);

      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            prototype: const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(height: 60),
            ),
          ),
        ),
      );
      expect(rectOf(tester, 4).top, 80);
    });

    testWidgets('a prototype that resizes itself relayouts the grid', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<double> height = ValueNotifier<double>(50);
      addTearDown(height.dispose);
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            prototype: ValueListenableBuilder<double>(
              valueListenable: height,
              builder: (BuildContext context, double value, Widget? child) =>
                  SizedBox(height: value),
            ),
          ),
        ),
      );
      expect(rectOf(tester, 4).top, 50);

      height.value = 75;
      await tester.pump();
      expect(rectOf(tester, 4).top, 75);
    });

    testWidgets('follows the text scale', (WidgetTester tester) async {
      Widget build(double scale) => host(
        textScale: scale,
        gridView(
          columns: const PrototypeGridColumns.count(4),
          prototype: const Text('Ab cd'),
        ),
      );

      // The test font is square: each glyph is as wide as the font size.
      await tester.pumpWidget(build(1));
      final double normal = gridRenderObject(tester).cellSize.height;
      await tester.pumpWidget(build(2));
      final double large = gridRenderObject(tester).cellSize.height;
      await tester.pumpWidget(build(3));
      final double huge = gridRenderObject(tester).cellSize.height;

      expect(normal, 14);
      expect(large, 28);
      // At 42 pixels per glyph the text no longer fits in 200 and wraps.
      expect(huge, 84);
    });

    testWidgets('changing columns and spacing relayouts the grid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(2),
            prototype: const SizedBox(height: 50),
          ),
        ),
      );
      expect(rectOf(tester, 1), const Rect.fromLTWH(400, 0, 400, 50));

      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            mainAxisSpacing: 4,
            crossAxisSpacing: 8,
            prototype: const SizedBox(height: 50),
          ),
        ),
      );
      // (800 - 3 * 8) / 4 = 194
      expect(rectOf(tester, 1), const Rect.fromLTWH(202, 0, 194, 50));
      expect(rectOf(tester, 4), const Rect.fromLTWH(0, 54, 194, 50));
    });

    testWidgets('can be removed from the tree cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(gridView(prototype: const SizedBox(width: 100, height: 50))),
      );
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });

    testWidgets('a prototype with a global key can move into the grid', (
      WidgetTester tester,
    ) async {
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(
        host(
          Column(
            children: <Widget>[
              SizedBox(key: key, height: 40),
              Expanded(
                child: gridView(
                  columns: const PrototypeGridColumns.count(2),
                  prototype: const SizedBox(height: 20),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          Column(
            children: <Widget>[
              Expanded(
                child: gridView(
                  columns: const PrototypeGridColumns.count(2),
                  prototype: SizedBox(key: key, height: 40),
                ),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(rectOf(tester, 2).top, 40);
    });
  });

  group('the prototype', () {
    testWidgets('is offstage and never shown', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            prototype: const Text('PROTOTYPE'),
          ),
        ),
      );

      expect(find.text('PROTOTYPE'), findsNothing);
      expect(find.text('PROTOTYPE', skipOffstage: false), findsOneWidget);
    });

    testWidgets('is not in the semantics tree', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            prototype: const Text('PROTOTYPE'),
          ),
        ),
      );

      expect(find.bySemanticsLabel('PROTOTYPE'), findsNothing);
      expect(find.bySemanticsLabel('0'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('does not receive taps', (WidgetTester tester) async {
      int prototypeTaps = 0;
      int itemTaps = 0;
      await tester.pumpWidget(
        host(
          gridView(
            columns: const PrototypeGridColumns.count(4),
            prototype: GestureDetector(
              onTap: () => prototypeTaps++,
              child: const SizedBox(height: 50),
            ),
            itemBuilder: (BuildContext context, int index) =>
                GestureDetector(onTap: () => itemTaps++, child: item(index)),
          ),
        ),
      );

      await tester.tapAt(const Offset(10, 10));
      expect(prototypeTaps, 0);
      expect(itemTaps, 1);
    });
  });

  group('PrototypeExtentGridView', () {
    testWidgets('the children constructor lays out its list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          PrototypeExtentGridView(
            columns: const PrototypeGridColumns.count(2),
            padding: const EdgeInsets.all(10),
            prototypeItem: const SizedBox(height: 30),
            children: List<Widget>.generate(4, item),
          ),
        ),
      );

      expect(rectOf(tester, 3), const Rect.fromLTWH(400, 40, 390, 30));
    });

    testWidgets('the custom constructor uses its delegate', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          PrototypeExtentGridView.custom(
            columns: const PrototypeGridColumns.count(2),
            prototypeItem: const SizedBox(height: 30),
            childrenDelegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => item(index),
              childCount: 3,
            ),
          ),
        ),
      );

      expect(rectOf(tester, 2), const Rect.fromLTWH(0, 30, 400, 30));
      expect(find.byKey(const ValueKey<int>(3)), findsNothing);
    });
  });

  group('PrototypeGridColumns', () {
    test('has value equality', () {
      expect(
        PrototypeGridColumns.count(3),
        const PrototypeGridColumns.count(3),
      );
      expect(
        const PrototypeGridColumns.count(3),
        isNot(const PrototypeGridColumns.count(4)),
      );
      expect(
        PrototypeGridColumns.maxExtent(100).hashCode,
        const PrototypeGridColumns.maxExtent(100).hashCode,
      );
      expect(
        const PrototypeGridColumns.fit(),
        isNot(const PrototypeGridColumns.fit(stretch: true)),
      );
      expect(
        const PrototypeGridColumns.fit(),
        isNot(const PrototypeGridColumns.count(1)),
      );
    });

    test('describes itself', () {
      expect(
        const PrototypeGridColumns.count(3).toString(),
        'PrototypeGridColumns.count(3)',
      );
      expect(
        const PrototypeGridColumns.maxExtent(120).toString(),
        'PrototypeGridColumns.maxExtent(120.0)',
      );
      expect(
        const PrototypeGridColumns.fit(stretch: true).toString(),
        'PrototypeGridColumns.fit(stretch: true)',
      );
    });
  });

  testWidgets('the render object rejects a foreign grid delegate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      host(gridView(prototype: const SizedBox(width: 100, height: 50))),
    );

    expect(
      () => gridRenderObject(tester).gridDelegate =
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      throwsAssertionError,
    );
  });
}
