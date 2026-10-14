// Renders the README images into ../doc/. Run from the example directory:
//
//   flutter test tool/render_screenshots.dart
//   tool/make_gif.sh
//
// It uses the real Roboto and Material Icons fonts from the Flutter SDK so the
// images look like the app on a device.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_extent_grid/prototype_extent_grid.dart';
import 'package:prototype_extent_grid_example/main.dart';

const double _pixelRatio = 2;
final Directory _docDir = Directory('../doc');
final Directory _framesDir = Directory('build/gif_frames');

Future<void> _loadFonts() async {
  final String flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final String fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(File('$fonts/$name').readAsBytesSync());
  await (FontLoader('Roboto')
        ..addFont(read('Roboto-Regular.ttf'))
        ..addFont(read('Roboto-Medium.ttf')))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('MaterialIcons-Regular.otf'))).load();
}

final ThemeData _theme = ThemeData(
  colorSchemeSeed: Colors.teal,
  fontFamily: 'Roboto',
);

/// A phone-sized screen with an app bar, showing [body] at [textScale].
Widget _phone({
  required String title,
  required Widget body,
  double textScale = 1,
  double width = 360,
  double height = 640,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            appBar: AppBar(title: Text(title)),
            body: body,
          ),
        ),
      ),
    ),
  );
}

Widget _prototypeGrid(PrototypeGridColumns columns, {double? prototypeWidth}) {
  return PrototypeExtentGridView.builder(
    columns: columns,
    padding: const EdgeInsets.all(12),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    prototypeItem: RecipeCard(recipe: Recipe.prototype, width: prototypeWidth),
    itemCount: recipes.length,
    itemBuilder: (BuildContext context, int index) =>
        RecipeCard(recipe: recipes[index]),
  );
}

Widget _caption(String text, {String? detail}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: <Widget>[
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (detail != null)
          Text(
            detail,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              color: Color(0xFF5F6368),
            ),
          ),
      ],
    ),
  );
}

/// Pumps [scene] on a white canvas of [size] and writes it to [path] as a PNG.
Future<void> _capture(
  WidgetTester tester,
  Size size,
  Widget scene,
  String path,
) async {
  final GlobalKey boundary = GlobalKey();
  tester.view.physicalSize = size * _pixelRatio;
  tester.view.devicePixelRatio = _pixelRatio;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme,
      home: RepaintBoundary(
        key: boundary,
        child: Material(
          color: Colors.white,
          child: Center(child: scene),
        ),
      ),
    ),
  );
  await tester.pump();
  final RenderRepaintBoundary render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ByteData? png = await tester.runAsync<ByteData?>(() async {
    final ui.Image image = await render.toImage(pixelRatio: _pixelRatio);
    return image.toByteData(format: ui.ImageByteFormat.png);
  });
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('comparison', (WidgetTester tester) async {
    const double scale = 1.6;
    await _capture(
      tester,
      const Size(820, 760),
      Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                _caption(
                  'GridView + childAspectRatio',
                  detail: 'Larger text overflows the cells',
                ),
                _phone(
                  title: 'GridView',
                  textScale: scale,
                  body: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: recipes.length,
                    itemBuilder: (BuildContext context, int index) =>
                        RecipeCard(recipe: recipes[index]),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 40),
            Column(
              children: <Widget>[
                _caption(
                  'PrototypeExtentGridView',
                  detail: 'Rows are measured from the prototype',
                ),
                _phone(
                  title: 'PrototypeExtentGridView',
                  textScale: scale,
                  body: _prototypeGrid(const PrototypeGridColumns.count(2)),
                ),
              ],
            ),
          ],
        ),
      ),
      '${_docDir.path}/comparison.png',
    );
    // The GridView overflows on purpose; that is what this image shows.
    while (tester.takeException() != null) {}
  });

  testWidgets('column modes', (WidgetTester tester) async {
    Widget mode(
      String name,
      String detail,
      PrototypeGridColumns columns, {
      double? width,
    }) {
      return Column(
        children: <Widget>[
          _caption(name, detail: detail),
          _phone(
            title: 'Recipes',
            width: 400,
            height: 600,
            body: _prototypeGrid(columns, prototypeWidth: width),
          ),
        ],
      );
    }

    await _capture(
      tester,
      const Size(1380, 720),
      Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 30,
          children: <Widget>[
            mode(
              '.count(2)',
              'Exactly 2 columns',
              const PrototypeGridColumns.count(2),
            ),
            mode(
              '.maxExtent(130)',
              'Fewest columns at most 130 wide',
              const PrototypeGridColumns.maxExtent(130),
            ),
            mode(
              '.fit()',
              'As many 170-wide prototypes as fit',
              const PrototypeGridColumns.fit(),
              width: 170,
            ),
          ],
        ),
      ),
      '${_docDir.path}/column_modes.png',
    );
  });

  testWidgets('gif frames', (WidgetTester tester) async {
    // Text size sweeps up and back down; the rows follow the prototype.
    final List<double> scales = <double>[
      for (int i = 0; i <= 12; i++) 0.8 + i * 0.1,
      for (int i = 11; i >= 2; i--) 0.8 + i * 0.1,
    ];
    int frame = 0;
    for (final double scale in scales) {
      await _capture(
        tester,
        const Size(400, 760),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              _caption(
                'Text size ${scale.toStringAsFixed(1)}x',
                detail: 'Every row follows the prototype',
              ),
              _phone(
                title: 'Recipes',
                textScale: scale,
                body: _prototypeGrid(const PrototypeGridColumns.count(2)),
              ),
            ],
          ),
        ),
        '${_framesDir.path}/${(frame++).toString().padLeft(3, '0')}.png',
      );
    }
  });
}
