import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// How a prototype extent grid decides its number of columns and the
/// cross-axis extent of each cell.
///
/// The main-axis extent of every cell (the row height in a vertical grid) is
/// always the main-axis extent of the prototype item, measured at the cell's
/// cross-axis extent.
///
/// Three strategies are available:
///
///  * [PrototypeGridColumns.count]: a fixed number of columns that share the
///    available width.
///  * [PrototypeGridColumns.maxExtent]: as many columns as needed so that no
///    column is wider than a maximum.
///  * [PrototypeGridColumns.fit]: the prototype's own width decides how many
///    columns fit.
@immutable
sealed class PrototypeGridColumns {
  const PrototypeGridColumns._();

  /// Lays out exactly [count] columns of equal cross-axis extent.
  ///
  /// The prototype is measured with a tight cross-axis constraint equal to
  /// the column width, so text that wraps differently at different widths is
  /// accounted for.
  const factory PrototypeGridColumns.count(int count) = _CountColumns;

  /// Lays out the smallest number of equal columns whose cross-axis extent
  /// does not exceed [maxCrossAxisExtent].
  ///
  /// This is the prototype counterpart of
  /// [SliverGridDelegateWithMaxCrossAxisExtent]: columns grow and shrink with
  /// the viewport, and the row height follows the prototype at that width.
  const factory PrototypeGridColumns.maxExtent(double maxCrossAxisExtent) =
      _MaxExtentColumns;

  /// Lets the prototype's natural cross-axis extent decide the column count.
  ///
  /// The prototype is laid out with a loose cross-axis constraint, and as
  /// many columns of that width as fit (including spacing) are used, with a
  /// minimum of one.
  ///
  /// When [stretch] is false, cells keep the prototype's size and any
  /// leftover space stays at the end of each row. When [stretch] is true,
  /// cells widen to share the leftover space and the prototype is measured
  /// again at the stretched width to find the row height.
  ///
  /// The prototype must size itself in the cross axis (for example with a
  /// `SizedBox` of a fixed width); a prototype that
  /// expands to fill the available width produces a single column.
  const factory PrototypeGridColumns.fit({bool stretch}) = _FitColumns;
}

final class _CountColumns extends PrototypeGridColumns {
  const _CountColumns(this.count)
    : assert(count > 0, 'count must be positive'),
      super._();

  final int count;

  @override
  bool operator ==(Object other) =>
      other is _CountColumns && other.count == count;

  @override
  int get hashCode => Object.hash(_CountColumns, count);

  @override
  String toString() => 'PrototypeGridColumns.count($count)';
}

final class _MaxExtentColumns extends PrototypeGridColumns {
  const _MaxExtentColumns(this.maxCrossAxisExtent)
    : assert(maxCrossAxisExtent > 0, 'maxCrossAxisExtent must be positive'),
      super._();

  final double maxCrossAxisExtent;

  @override
  bool operator ==(Object other) =>
      other is _MaxExtentColumns &&
      other.maxCrossAxisExtent == maxCrossAxisExtent;

  @override
  int get hashCode => Object.hash(_MaxExtentColumns, maxCrossAxisExtent);

  @override
  String toString() => 'PrototypeGridColumns.maxExtent($maxCrossAxisExtent)';
}

final class _FitColumns extends PrototypeGridColumns {
  const _FitColumns({this.stretch = false}) : super._();

  final bool stretch;

  @override
  bool operator ==(Object other) =>
      other is _FitColumns && other.stretch == stretch;

  @override
  int get hashCode => Object.hash(_FitColumns, stretch);

  @override
  String toString() => 'PrototypeGridColumns.fit(stretch: $stretch)';
}

/// A sliver grid whose cells all share the size of an offstage prototype
/// child.
///
/// Before laying out the visible children, the prototype child is measured
/// according to [columns]. Its main-axis extent becomes the main-axis extent
/// of every cell. The prototype itself is never painted, hit tested or
/// included in the semantics tree.
///
/// This is the render object behind `SliverPrototypeExtentGrid`; most apps
/// use that widget instead.
class RenderSliverPrototypeExtentGrid extends RenderSliverGrid {
  /// Creates a sliver grid that sizes its cells from a prototype child.
  ///
  /// [mainAxisSpacing] and [crossAxisSpacing] must not be negative.
  RenderSliverPrototypeExtentGrid({
    required RenderSliverBoxChildManager childManager,
    PrototypeGridColumns columns = const PrototypeGridColumns.fit(),
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
  }) : this._(
         childManager,
         _MeasuredGridDelegate(),
         columns,
         mainAxisSpacing,
         crossAxisSpacing,
       );

  RenderSliverPrototypeExtentGrid._(
    RenderSliverBoxChildManager childManager,
    this._delegate,
    this._columns,
    this._mainAxisSpacing,
    this._crossAxisSpacing,
  ) : assert(_mainAxisSpacing >= 0.0),
      assert(_crossAxisSpacing >= 0.0),
      super(childManager: childManager, gridDelegate: _delegate);

  final _MeasuredGridDelegate _delegate;

  /// The grid delegate is computed from the prototype and cannot be replaced.
  @override
  set gridDelegate(SliverGridDelegate value) {
    assert(
      identical(value, _delegate),
      'RenderSliverPrototypeExtentGrid computes its own grid delegate. '
      'Use columns, mainAxisSpacing and crossAxisSpacing instead.',
    );
    super.gridDelegate = value;
  }

  /// How the number of columns and the cell cross-axis extent are chosen.
  PrototypeGridColumns get columns => _columns;
  PrototypeGridColumns _columns;
  set columns(PrototypeGridColumns value) {
    if (_columns == value) return;
    _columns = value;
    markNeedsLayout();
  }

  /// The gap between rows (along the main axis), in logical pixels.
  double get mainAxisSpacing => _mainAxisSpacing;
  double _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    assert(value >= 0.0);
    if (_mainAxisSpacing == value) return;
    _mainAxisSpacing = value;
    markNeedsLayout();
  }

  /// The gap between columns (along the cross axis), in logical pixels.
  double get crossAxisSpacing => _crossAxisSpacing;
  double _crossAxisSpacing;
  set crossAxisSpacing(double value) {
    assert(value >= 0.0);
    if (_crossAxisSpacing == value) return;
    _crossAxisSpacing = value;
    markNeedsLayout();
  }

  /// The offstage child whose size defines the size of every cell.
  RenderBox? get prototype => _prototype;
  RenderBox? _prototype;
  set prototype(RenderBox? value) {
    if (identical(_prototype, value)) return;
    if (_prototype != null) dropChild(_prototype!);
    _prototype = value;
    if (value != null) adoptChild(value);
    markNeedsLayout();
  }

  /// The number of columns chosen during the most recent layout.
  ///
  /// Zero before the first layout.
  int get crossAxisCount => _delegate.layout?.crossAxisCount ?? 0;

  /// The size of each cell in the most recent layout, in physical
  /// (width, height) terms regardless of the scroll direction.
  ///
  /// [Size.zero] before the first layout.
  Size get cellSize {
    final SliverGridRegularTileLayout? layout = _delegate.layout;
    if (layout == null) return Size.zero;
    return switch (constraints.axis) {
      Axis.vertical => Size(
        layout.childCrossAxisExtent,
        layout.childMainAxisExtent,
      ),
      Axis.horizontal => Size(
        layout.childMainAxisExtent,
        layout.childCrossAxisExtent,
      ),
    };
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _prototype?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    _prototype?.detach();
  }

  @override
  void redepthChildren() {
    if (_prototype != null) redepthChild(_prototype!);
    super.redepthChildren();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_prototype != null) visitor(_prototype!);
    super.visitChildren(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      if (_prototype != null) _prototype!.toDiagnosticsNode(name: 'prototype'),
      ...super.debugDescribeChildren(),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<PrototypeGridColumns>('columns', columns))
      ..add(DoubleProperty('mainAxisSpacing', mainAxisSpacing))
      ..add(DoubleProperty('crossAxisSpacing', crossAxisSpacing));
  }

  @override
  void performLayout() {
    _delegate.layout = _measure(constraints);
    super.performLayout();
  }

  SliverGridRegularTileLayout _measure(SliverConstraints constraints) {
    final double available = constraints.crossAxisExtent;
    final double gap = crossAxisSpacing;

    final int columnCount;
    final double cellCross;
    final double cellMain;
    switch (columns) {
      case _CountColumns(:final int count):
        columnCount = count;
        cellCross = _shareOf(available, columnCount);
        cellMain = _measurePrototype(constraints, cellCross, cellCross).main;
      case _MaxExtentColumns(:final double maxCrossAxisExtent):
        // The smallest n with (available - (n - 1) * gap) / n <= max.
        final double ratio = (available + gap) / (maxCrossAxisExtent + gap);
        columnCount = math.max(1, (ratio - precisionErrorTolerance).ceil());
        cellCross = _shareOf(available, columnCount);
        cellMain = _measurePrototype(constraints, cellCross, cellCross).main;
      case _FitColumns(:final bool stretch):
        final ({double cross, double main}) natural = _measurePrototype(
          constraints,
          0.0,
          available,
        );
        // The largest n with n * cell + (n - 1) * gap <= available.
        final double stride = natural.cross + gap;
        columnCount = stride > 0.0
            ? math.max(
                1,
                ((available + gap) / stride + precisionErrorTolerance).floor(),
              )
            : 1;
        if (stretch) {
          cellCross = _shareOf(available, columnCount);
          cellMain = _measurePrototype(constraints, cellCross, cellCross).main;
        } else {
          cellCross = natural.cross;
          cellMain = natural.main;
        }
    }
    return _tileLayout(constraints, columnCount, cellCross, cellMain);
  }

  /// The cross-axis extent of one of [count] equal columns.
  double _shareOf(double available, int count) {
    final double usable = available - crossAxisSpacing * (count - 1);
    return math.max(0.0, usable / count);
  }

  /// Lays out the prototype between [minCross] and [maxCross] in the cross
  /// axis, unconstrained in the main axis, and returns its size.
  ({double cross, double main}) _measurePrototype(
    SliverConstraints constraints,
    double minCross,
    double maxCross,
  ) {
    final RenderBox? prototype = _prototype;
    if (prototype == null) return (cross: minCross, main: 0.0);
    final BoxConstraints box = switch (constraints.axis) {
      Axis.vertical => BoxConstraints(minWidth: minCross, maxWidth: maxCross),
      Axis.horizontal => BoxConstraints(
        minHeight: minCross,
        maxHeight: maxCross,
      ),
    };
    prototype.layout(box, parentUsesSize: true);
    final Size size = prototype.size;
    return switch (constraints.axis) {
      Axis.vertical => (cross: size.width, main: size.height),
      Axis.horizontal => (cross: size.height, main: size.width),
    };
  }

  SliverGridRegularTileLayout _tileLayout(
    SliverConstraints constraints,
    int count,
    double cellCross,
    double cellMain,
  ) {
    return SliverGridRegularTileLayout(
      crossAxisCount: count,
      mainAxisStride: cellMain + mainAxisSpacing,
      crossAxisStride: cellCross + crossAxisSpacing,
      childMainAxisExtent: cellMain,
      childCrossAxisExtent: cellCross,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }
}

/// A grid delegate that hands [RenderSliverGrid] the layout measured by
/// [RenderSliverPrototypeExtentGrid] during the current layout pass.
class _MeasuredGridDelegate extends SliverGridDelegate {
  SliverGridRegularTileLayout? layout;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    assert(layout != null, 'The prototype has not been measured yet.');
    return layout!;
  }

  @override
  bool shouldRelayout(covariant SliverGridDelegate oldDelegate) => false;
}
