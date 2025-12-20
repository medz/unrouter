import 'package:flutter/widgets.dart';

import '../extensions.dart';
import '../navigation.dart';

/// Signature for the builder callback used by `Link(builder: ...)`.
///
/// The [location] parameter provides the target route information.
/// The [navigate] callback can be called to trigger navigation with optional
/// overrides and returns a `Future<Navigation>`.
typedef LinkBuilder =
    Widget Function(
      BuildContext context,
      RouteInformation location,
      Future<Navigation> Function({Object? state, bool? replace}) navigate,
    );

/// A widget that navigates to a specified route when tapped.
///
/// [Link] provides a declarative way to create navigation links in your app.
/// It handles tap gestures, accessibility semantics, and mouse cursor behavior
/// automatically.
///
/// Basic usage with a child widget:
/// ```dart
/// Link(
///   to: Uri.parse('/about'),
///   child: const Text('About Us'),
/// )
/// ```
///
/// For more control, use `builder`:
/// ```dart
/// Link(
///   to: Uri.parse('/products/1'),
///   state: {'source': 'homepage'},
///   builder: (context, location, navigate) {
///     return GestureDetector(
///       onTap: () => navigate(),
///       onLongPress: () => navigate(replace: true),
///       child: Text('Product 1'),
///     );
///   },
/// )
/// ```
class Link extends StatelessWidget {
  /// Creates a link that navigates to [to] when tapped.
  ///
  /// The [child] widget is wrapped in a [GestureDetector] that handles tap
  /// events and triggers navigation.
  const Link({
    super.key,
    required this.to,
    this.child,
    this.builder,
    this.replace = false,
    this.state,
  }) : assert(child != null || builder != null, 'Provide a child or builder.'),
       assert(
         child == null || builder == null,
         'Provide either child or builder, not both.',
       );

  /// The target URI to navigate to.
  final Uri to;

  /// Whether to replace the current history entry instead of pushing a new one.
  ///
  /// Defaults to `false`.
  final bool replace;

  /// Optional state to associate with the navigation.
  ///
  /// This can be any object and will be available via [RouterState.location].
  final Object? state;

  /// The widget to display for the link.
  ///
  /// Only used when [builder] is null.
  final Widget? child;

  /// The builder function for custom link rendering.
  ///
  /// Only used when [child] is null.
  final LinkBuilder? builder;

  @override
  Widget build(BuildContext context) {
    Future<Navigation> navigate({Object? state, bool? replace}) {
      return context.navigate(
        to,
        state: state ?? this.state,
        replace: replace ?? this.replace,
      );
    }

    // If builder is provided, use it
    if (builder != null) {
      final location = RouteInformation(uri: to, state: state);
      return builder!(context, location, navigate);
    }

    // Default implementation with child
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: navigate,
        child: Semantics(link: true, child: child),
      ),
    );
  }
}
