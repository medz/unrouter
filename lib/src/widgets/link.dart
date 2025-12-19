import 'package:flutter/widgets.dart';

import '../navigation.dart';

/// Signature for the builder callback used by [Link.builder].
///
/// The [location] parameter provides the target route information.
/// The [navigate] callback can be called to trigger navigation with optional overrides.
typedef LinkBuilder =
    Widget Function(
      BuildContext context,
      RouteInformation location,
      void Function({Object? state, bool? replace}) navigate,
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
/// For more control, use [Link.builder]:
/// ```dart
/// Link.builder(
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
    required this.child,
    this.replace = false,
    this.state,
  }) : builder = null;

  /// Creates a link with a custom builder.
  ///
  /// The [builder] callback receives:
  /// - [context]: The build context
  /// - [location]: A [RouteInformation] containing [to] and [state]
  /// - [navigate]: A function to trigger navigation with optional overrides
  ///
  /// This constructor gives you full control over the widget structure and
  /// gesture handling.
  const Link.builder({
    super.key,
    required this.to,
    required LinkBuilder this.builder,
    this.replace = false,
    this.state,
  }) : child = null;

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
  /// Only used when creating a [Link] with the default constructor.
  final Widget? child;

  /// The builder function for custom link rendering.
  ///
  /// Only used when creating a [Link.builder].
  final LinkBuilder? builder;

  @override
  Widget build(BuildContext context) {
    void navigate({Object? state, bool? replace}) {
      context.navigate(
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
