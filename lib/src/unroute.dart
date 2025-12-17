import 'package:flutter/widgets.dart';

/// A route configuration that can be nested in the widget tree.
///
/// Example:
/// ```dart
/// Routes([
///   Unroute(path: null, factory: Home.new),           // index route
///   Unroute(path: 'about', factory: About.new),       // static route
///   Unroute(path: 'users/:id', factory: User.new),    // dynamic param
///   Unroute(path: ':lang?/blog', factory: Blog.new),  // optional param
///   Unroute(path: 'files/*', factory: Files.new),     // wildcard
/// ])
/// ```
class Unroute extends StatelessWidget {
  const Unroute({
    super.key,
    this.path,
    required this.factory,
  });

  /// The path pattern for this route.
  ///
  /// - `null`, `''`, or `'/'` for index routes
  /// - Static segments: `'about'`, `'users/profile'`
  /// - Dynamic params: `':id'`, `':userId'`
  /// - Optional params: `':id?'`, `':lang?/about'`
  /// - Optional segments: `'edit?'`
  /// - Wildcard: `'*'`, `'files/*'`
  final String? path;

  /// Factory function that creates the widget for this route.
  final Widget Function() factory;

  @override
  Widget build(BuildContext context) {
    // The actual rendering logic will be handled by Routes
    // This is just a placeholder that should never be called directly
    throw UnimplementedError(
      'Unroute should not be built directly. '
      'It must be a child of a Routes widget.',
    );
  }
}
