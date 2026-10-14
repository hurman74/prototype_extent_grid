import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'render_sliver_prototype_extent_grid.dart';
import 'sliver_prototype_extent_grid.dart';

/// A scrollable grid whose cells all take the size of [prototypeItem].
///
/// This is to [SliverPrototypeExtentGrid] what [GridView] is to [SliverGrid]:
/// a ready-made scroll view with padding, a controller and the other usual
/// [ScrollView] options.
///
/// ```dart
/// PrototypeExtentGridView.builder(
///   columns: const PrototypeGridColumns.count(2),
///   padding: const EdgeInsets.all(12),
///   mainAxisSpacing: 12,
///   crossAxisSpacing: 12,
///   prototypeItem: const ContactTile(contact: Contact.longest),
///   itemCount: contacts.length,
///   itemBuilder: (context, index) => ContactTile(contact: contacts[index]),
/// )
/// ```
class PrototypeExtentGridView extends BoxScrollView {
  /// Creates a scrollable prototype extent grid from an explicit list of
  /// [children].
  ///
  /// [mainAxisSpacing] and [crossAxisSpacing] must not be negative.
  PrototypeExtentGridView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.prototypeItem,
    this.columns = const PrototypeGridColumns.fit(),
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    List<Widget> children = const <Widget>[],
    int? semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : assert(mainAxisSpacing >= 0.0),
       assert(crossAxisSpacing >= 0.0),
       childrenDelegate = SliverChildListDelegate(
         children,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
       ),
       super(semanticChildCount: semanticChildCount ?? children.length);

  /// Creates a scrollable prototype extent grid that builds its items on
  /// demand.
  ///
  /// [itemBuilder] is only called for items that are visible or within the
  /// cache extent. If [itemCount] is null, the grid continues until
  /// [itemBuilder] returns null.
  ///
  /// [mainAxisSpacing] and [crossAxisSpacing] must not be negative.
  PrototypeExtentGridView.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.prototypeItem,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
    this.columns = const PrototypeGridColumns.fit(),
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    int? semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : assert(mainAxisSpacing >= 0.0),
       assert(crossAxisSpacing >= 0.0),
       childrenDelegate = SliverChildBuilderDelegate(
         itemBuilder,
         childCount: itemCount,
         findChildIndexCallback: findChildIndexCallback,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
       ),
       super(semanticChildCount: semanticChildCount ?? itemCount);

  /// Creates a scrollable prototype extent grid with a custom
  /// [childrenDelegate].
  ///
  /// [mainAxisSpacing] and [crossAxisSpacing] must not be negative.
  const PrototypeExtentGridView.custom({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.prototypeItem,
    required this.childrenDelegate,
    this.columns = const PrototypeGridColumns.fit(),
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : assert(mainAxisSpacing >= 0.0),
       assert(crossAxisSpacing >= 0.0);

  /// The item whose size defines the size of every cell.
  ///
  /// See [SliverPrototypeExtentGrid.prototypeItem].
  final Widget prototypeItem;

  /// How the number of columns and the cell cross-axis extent are chosen.
  ///
  /// Defaults to [PrototypeGridColumns.fit].
  final PrototypeGridColumns columns;

  /// The gap between rows (along the main axis), in logical pixels.
  final double mainAxisSpacing;

  /// The gap between columns (along the cross axis), in logical pixels.
  final double crossAxisSpacing;

  /// The delegate that provides the items of the grid.
  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverPrototypeExtentGrid(
      delegate: childrenDelegate,
      prototypeItem: prototypeItem,
      columns: columns,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );
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
