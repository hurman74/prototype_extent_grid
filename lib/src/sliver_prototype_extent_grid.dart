import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'render_sliver_prototype_extent_grid.dart';

/// A sliver grid whose cells all take the size of [prototypeItem].
///
/// This is the grid counterpart of [SliverPrototypeExtentList]. Instead of
/// hard-coding a `childAspectRatio` or `mainAxisExtent`, you pass one
/// representative item. It is laid out offstage, and its size becomes the
/// size of every cell. When the prototype's size changes (because the text
/// scale, theme, locale or available width changed), the grid follows.
///
/// [columns] decides how many columns there are and how wide each one is.
/// The row height is always the height of the prototype at that width (in a
/// horizontal grid, the column width is the width of the prototype at the
/// row height).
///
/// The prototype is built in this widget's context, so it inherits the same
/// theme, media query and directionality as the real items. It is never
/// painted, hit tested or exposed to accessibility services.
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverPrototypeExtentGrid.builder(
///       columns: const PrototypeGridColumns.maxExtent(220),
///       mainAxisSpacing: 8,
///       crossAxisSpacing: 8,
///       prototypeItem: const ProductCard(product: Product.placeholder),
///       itemCount: products.length,
///       itemBuilder: (context, index) => ProductCard(product: products[index]),
///     ),
///   ],
/// )
/// ```
///
/// See also:
///
///  * [PrototypeGridColumns], the column strategies.
///  * `PrototypeExtentGridView`, a scrollable box widget built on this sliver.
class SliverPrototypeExtentGrid extends SliverMultiBoxAdaptorWidget {
  /// Creates a prototype extent grid that gets its children from [delegate].
  ///
  /// [mainAxisSpacing] and [crossAxisSpacing] must not be negative.
  const SliverPrototypeExtentGrid({
    super.key,
    required super.delegate,
    required this.prototypeItem,
    this.columns = const PrototypeGridColumns.fit(),
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
  }) : assert(mainAxisSpacing >= 0.0),
       assert(crossAxisSpacing >= 0.0);

  /// Creates a prototype extent grid that builds its items on demand.
  ///
  /// [itemBuilder] is only called for items that are visible or within the
  /// cache extent. If [itemCount] is null, the grid continues until
  /// [itemBuilder] returns null.
  ///
  /// The other arguments are passed to [SliverChildBuilderDelegate]; see its
  /// documentation for details.
  SliverPrototypeExtentGrid.builder({
    super.key,
    required NullableIndexedWidgetBuilder itemBuilder,
    required this.prototypeItem,
    int? itemCount,
    this.columns = const PrototypeGridColumns.fit(),
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : assert(mainAxisSpacing >= 0.0),
       assert(crossAxisSpacing >= 0.0),
       super(
         delegate: SliverChildBuilderDelegate(
           itemBuilder,
           childCount: itemCount,
           findChildIndexCallback: findChildIndexCallback,
           addAutomaticKeepAlives: addAutomaticKeepAlives,
           addRepaintBoundaries: addRepaintBoundaries,
           addSemanticIndexes: addSemanticIndexes,
         ),
       );

  /// Creates a prototype extent grid from an explicit list of [children].
  ///
  /// The other arguments are passed to [SliverChildListDelegate]; see its
  /// documentation for details.
  SliverPrototypeExtentGrid.list({
    super.key,
    required List<Widget> children,
    required this.prototypeItem,
    this.columns = const PrototypeGridColumns.fit(),
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : assert(mainAxisSpacing >= 0.0),
       assert(crossAxisSpacing >= 0.0),
       super(
         delegate: SliverChildListDelegate(
           children,
           addAutomaticKeepAlives: addAutomaticKeepAlives,
           addRepaintBoundaries: addRepaintBoundaries,
           addSemanticIndexes: addSemanticIndexes,
         ),
       );

  /// The item whose size defines the size of every cell.
  ///
  /// It is built and laid out offstage but never shown. Use a widget that
  /// looks like a typical item, ideally with the longest content you expect,
  /// because items larger than the cell are clipped or overflow.
  final Widget prototypeItem;

  /// How the number of columns and the cell cross-axis extent are chosen.
  ///
  /// Defaults to [PrototypeGridColumns.fit], which uses the prototype's own
  /// cross-axis extent.
  final PrototypeGridColumns columns;

  /// The gap between rows (along the main axis), in logical pixels.
  final double mainAxisSpacing;

  /// The gap between columns (along the cross axis), in logical pixels.
  final double crossAxisSpacing;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      _SliverPrototypeExtentGridElement(this);

  @override
  RenderSliverPrototypeExtentGrid createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;
    return RenderSliverPrototypeExtentGrid(
      childManager: element,
      columns: columns,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverPrototypeExtentGrid renderObject,
  ) {
    renderObject
      ..columns = columns
      ..mainAxisSpacing = mainAxisSpacing
      ..crossAxisSpacing = crossAxisSpacing;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<PrototypeGridColumns>('columns', columns))
      ..add(DoubleProperty('mainAxisSpacing', mainAxisSpacing))
      ..add(DoubleProperty('crossAxisSpacing', crossAxisSpacing));
  }
}

/// Manages the item children like any sliver grid, plus one extra child, the
/// prototype, which lives in its own slot.
class _SliverPrototypeExtentGridElement extends SliverMultiBoxAdaptorElement {
  _SliverPrototypeExtentGridElement(SliverPrototypeExtentGrid super.widget);

  static final Object _prototypeSlot = Object();

  Element? _prototype;

  @override
  RenderSliverPrototypeExtentGrid get renderObject =>
      super.renderObject as RenderSliverPrototypeExtentGrid;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _prototype = updateChild(
      _prototype,
      (widget as SliverPrototypeExtentGrid).prototypeItem,
      _prototypeSlot,
    );
  }

  @override
  void update(SliverPrototypeExtentGrid newWidget) {
    super.update(newWidget);
    _prototype = updateChild(
      _prototype,
      newWidget.prototypeItem,
      _prototypeSlot,
    );
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_prototype != null) visitor(_prototype!);
    super.visitChildren(visitor);
  }

  @override
  void forgetChild(Element child) {
    if (identical(child, _prototype)) _prototype = null;
    super.forgetChild(child);
  }

  @override
  void insertRenderObjectChild(RenderObject child, Object slot) {
    if (identical(slot, _prototypeSlot)) {
      renderObject.prototype = child as RenderBox;
    } else {
      super.insertRenderObjectChild(child, slot as int);
    }
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    Object oldSlot,
    Object newSlot,
  ) {
    assert(!identical(newSlot, _prototypeSlot));
    assert(!identical(oldSlot, _prototypeSlot));
    super.moveRenderObjectChild(child, oldSlot as int, newSlot as int);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object slot) {
    if (identical(slot, _prototypeSlot)) {
      assert(identical(renderObject.prototype, child));
      renderObject.prototype = null;
    } else {
      super.removeRenderObjectChild(child, slot as int);
    }
  }

  @override
  void didAdoptChild(RenderBox child) {
    // The prototype has no index; only the grid items are tracked.
    if (!identical(child, renderObject.prototype)) super.didAdoptChild(child);
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints? constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) {
    final int? childCount = estimatedChildCount;
    final SliverChildDelegate delegate =
        (widget as SliverMultiBoxAdaptorWidget).delegate;
    final bool canComputeExactly =
        childCount != null &&
        constraints != null &&
        delegate.estimateMaxScrollOffset(
              firstIndex ?? 0,
              lastIndex ?? 0,
              leadingScrollOffset ?? 0.0,
              trailingScrollOffset ?? 0.0,
            ) ==
            null;
    if (!canComputeExactly) {
      return super.estimateMaxScrollOffset(
        constraints,
        firstIndex: firstIndex,
        lastIndex: lastIndex,
        leadingScrollOffset: leadingScrollOffset,
        trailingScrollOffset: trailingScrollOffset,
      );
    }
    // Every row has the same extent, so the total is exact rather than
    // extrapolated from the children built so far.
    return renderObject.gridDelegate
        .getLayout(constraints)
        .computeMaxScrollOffset(childCount);
  }
}
