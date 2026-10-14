import 'package:flutter/material.dart';
import 'package:prototype_extent_grid/prototype_extent_grid.dart';

void main() => runApp(const ExampleApp());

/// A catalog of recipes shown in a grid whose row height comes from a
/// prototype card. Change the text size or the column mode and watch the
/// rows resize without any hard-coded heights.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'prototype_extent_grid',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: const RecipeGridPage(),
    );
  }
}

enum ColumnMode { count, maxExtent, fit }

class RecipeGridPage extends StatefulWidget {
  const RecipeGridPage({super.key});

  @override
  State<RecipeGridPage> createState() => _RecipeGridPageState();
}

class _RecipeGridPageState extends State<RecipeGridPage> {
  ColumnMode _mode = ColumnMode.maxExtent;
  double _textScale = 1.0;

  PrototypeGridColumns get _columns => switch (_mode) {
    ColumnMode.count => const PrototypeGridColumns.count(2),
    ColumnMode.maxExtent => const PrototypeGridColumns.maxExtent(240),
    ColumnMode.fit => const PrototypeGridColumns.fit(stretch: true),
  };

  @override
  Widget build(BuildContext context) {
    // In fit mode the prototype needs its own width; the other modes give it
    // the column width.
    final Widget prototype = RecipeCard(
      recipe: Recipe.prototype,
      width: _mode == ColumnMode.fit ? 200 : null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(_textScale)),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _controls()),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverPrototypeExtentGrid.builder(
                columns: _columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                prototypeItem: prototype,
                itemCount: recipes.length,
                itemBuilder: (BuildContext context, int index) =>
                    RecipeCard(recipe: recipes[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SegmentedButton<ColumnMode>(
            segments: const <ButtonSegment<ColumnMode>>[
              ButtonSegment<ColumnMode>(
                value: ColumnMode.count,
                label: Text('2 columns'),
              ),
              ButtonSegment<ColumnMode>(
                value: ColumnMode.maxExtent,
                label: Text('Max 240'),
              ),
              ButtonSegment<ColumnMode>(
                value: ColumnMode.fit,
                label: Text('Fit'),
              ),
            ],
            selected: <ColumnMode>{_mode},
            onSelectionChanged: (Set<ColumnMode> value) =>
                setState(() => _mode = value.single),
          ),
          Row(
            children: <Widget>[
              const Text('Text size'),
              Expanded(
                child: Slider(
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  value: _textScale,
                  label: '${_textScale.toStringAsFixed(1)}x',
                  onChanged: (double value) =>
                      setState(() => _textScale = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Recipe {
  const Recipe(this.title, this.minutes, this.tags);

  /// The longest title and tag line we expect, used to size every card.
  static const Recipe prototype = Recipe(
    'Slow-roasted tomato and garlic soup',
    120,
    'vegetarian · gluten free',
  );

  final String title;
  final int minutes;
  final String tags;
}

const List<Recipe> recipes = <Recipe>[
  Recipe('Shakshuka', 30, 'vegetarian'),
  Recipe('Chicken karahi', 45, 'spicy'),
  Recipe('Lemon risotto', 35, 'vegetarian'),
  Recipe('Beef pho', 180, 'gluten free'),
  Recipe('Falafel wraps', 40, 'vegan'),
  Recipe('Miso salmon', 25, 'gluten free'),
  Recipe('Daal tadka', 50, 'vegan · gluten free'),
  Recipe('Pad thai', 30, 'spicy'),
  Recipe('Mushroom pie', 90, 'vegetarian'),
  Recipe('Fish tacos', 30, 'quick'),
  Recipe('Ratatouille', 75, 'vegan · gluten free'),
  Recipe('Biryani', 120, 'spicy'),
  Recipe('Caesar salad', 15, 'quick'),
  Recipe('Ramen', 240, 'comfort food'),
  Recipe('Gnocchi with sage butter', 40, 'vegetarian'),
  Recipe('Bibimbap', 45, 'gluten free'),
];

class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, this.width});

  final Recipe recipe;

  /// A fixed width, only needed for the prototype in fit mode.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.restaurant, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.minutes} min · ${recipe.tags}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
