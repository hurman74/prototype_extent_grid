# prototype_extent_grid

A Flutter grid whose cell size is measured from a **prototype item**, the grid counterpart of
`SliverPrototypeExtentList`.

Give the grid one representative card. It is laid out offstage, and its size becomes the size of
every cell. Change the text scale, the theme, the locale or the window width, and the rows follow.
No more guessing a `childAspectRatio` or hard-coding a `mainAxisExtent`.

## Install

```sh
flutter pub add prototype_extent_grid
```

## Usage

### As a scroll view

```dart
import 'package:prototype_extent_grid/prototype_extent_grid.dart';

PrototypeExtentGridView.builder(
  columns: const PrototypeGridColumns.maxExtent(240),
  padding: const EdgeInsets.all(12),
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  // The longest content you expect. Never shown, only measured.
  prototypeItem: const RecipeCard(recipe: Recipe.prototype),
  itemCount: recipes.length,
  itemBuilder: (context, index) => RecipeCard(recipe: recipes[index]),
)
```

### As a sliver

```dart
CustomScrollView(
  slivers: [
    const SliverAppBar(title: Text('Recipes')),
    SliverPrototypeExtentGrid.builder(
      columns: const PrototypeGridColumns.count(2),
      prototypeItem: const RecipeCard(recipe: Recipe.prototype),
      itemCount: recipes.length,
      itemBuilder: (context, index) => RecipeCard(recipe: recipes[index]),
    ),
  ],
)
```

### Choosing the columns

| Strategy | Columns | Cell width | Cell height |
| --- | --- | --- | --- |
| `PrototypeGridColumns.count(n)` | exactly `n` | shared equally | prototype at that width |
| `PrototypeGridColumns.maxExtent(w)` | fewest that keep cells `<= w` | shared equally | prototype at that width |
| `PrototypeGridColumns.fit()` | as many prototypes as fit | prototype's own width | prototype's own height |
| `PrototypeGridColumns.fit(stretch: true)` | as many prototypes as fit | stretched to fill the row | prototype at the stretched width |

For `fit`, the prototype has to choose its own width, for example by wrapping it in a
`SizedBox(width: 200)`. In horizontal grids, "width" and "height" swap roles.

## Why this package

Flutter's `GridView` needs the tile shape up front, as a `childAspectRatio` or a fixed
`mainAxisExtent`. Real cards hold text, so their height depends on the column width, the font,
the user's text scale and the language. A hard-coded number is either too small (overflow
stripes at large text sizes) or too big (wasted space everywhere else).

Lists solved this with `SliverPrototypeExtentList` and `ListView(prototypeItem:)`, but there is
no grid equivalent ([flutter/flutter#86467](https://github.com/flutter/flutter/issues/86467)).
This package fills that gap:

- **Measured, not guessed.** The prototype is laid out at the real column width, so wrapping text
  and `AspectRatio` images are accounted for.
- **Still a fast, lazy grid.** All cells share one size, so only visible items are built, and the
  scroll extent is exact from the first frame. Jumping to the end or dragging the scrollbar is
  accurate even in grids with thousands of items.
- **Reacts to change.** If the prototype's size changes (text scale, theme, constraints, its own
  state), the grid lays out again.
- **Pure Flutter.** No platform code and no dependencies beyond the Flutter SDK.

## Limitations

- Every cell has the same size. Items with more content than the prototype are clipped or
  overflow, so pick the largest item you expect as the prototype. For truly variable-height
  tiles, use a masonry or staggered grid instead.
- The prototype is built offstage in the grid's context. Avoid prototypes that start network
  requests, animations or other side effects, and don't give it a `GlobalKey` that a real item
  also uses.
- The prototype is laid out with an unbounded main axis, so it must have a finite height in
  vertical grids (and a finite width in horizontal ones).
- With `fit` and `stretch: false`, leftover space stays at the end of each row.

## License

MIT
