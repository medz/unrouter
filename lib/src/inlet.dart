import 'package:flutter/widgets.dart';

/// A route configuration that defines a path pattern and widget factory.
///
/// Inlets can be created using named constructors:
/// - [Inlet.index] - Index route (matches when no path segment)
/// - [Inlet.path] - Path route (matches a specific path segment)
/// - [Inlet.layout] - Layout route (wraps children without adding path segment)
/// - [Inlet.nested] - Nested route (has path segment and wraps children)
///
/// Example:
/// ```dart
/// final routes = [
///   Inlet.index(HomePage.new),
///   Inlet.path('about', AboutPage.new),
///   Inlet.layout(AuthLayout.new, [
///     Inlet.path('login', LoginPage.new),
///     Inlet.path('register', RegisterPage.new),
///   ]),
///   Inlet.nested('users', UsersLayout.new, [
///     Inlet.index(UsersIndexPage.new),
///     Inlet.path(':id', UserDetailPage.new),
///   ]),
/// ];
/// ```
class Inlet {
  /// Path pattern for this route.
  /// - `null` for index routes and layout routes
  /// - Static segments: `'about'`, `'users'`
  /// - Dynamic params: `':id'`, `':userId'`
  final String? path;

  /// Factory function that creates the widget for this route.
  final Widget Function() factory;

  /// Child routes.
  final List<Inlet> children;

  /// Creates a path route that matches a specific path segment.
  ///
  /// Example:
  /// ```dart
  /// Inlet.path('about', AboutPage.new)  // Matches '/about'
  /// Inlet.path(':id', UserPage.new)     // Matches '/123', params={'id': '123'}
  /// ```
  const Inlet.path(this.path, this.factory) : children = const [];

  /// Creates an index route that matches when no path segment remains.
  ///
  /// Example:
  /// ```dart
  /// Inlet.index(HomePage.new)  // Matches '/' or when parent path is fully matched
  /// ```
  const Inlet.index(this.factory) : path = null, children = const [];

  /// Creates a layout route that wraps children without adding a path segment.
  ///
  /// Layout routes are transparent for path matching but add a component
  /// to the widget hierarchy. They must use [Outlet] to render children.
  ///
  /// Example:
  /// ```dart
  /// Inlet.layout(AuthLayout.new, [
  ///   Inlet.path('login', LoginPage.new),    // Matches '/login'
  ///   Inlet.path('register', RegisterPage.new), // Matches '/register'
  /// ])
  /// ```
  const Inlet.layout(this.factory, this.children) : path = null;

  /// Creates a nested route that has both a path segment and children.
  ///
  /// Nested routes add to both the URL path and the component hierarchy.
  /// They must use [Outlet] to render children.
  ///
  /// Example:
  /// ```dart
  /// Inlet.nested('users', UsersLayout.new, [
  ///   Inlet.index(UsersIndexPage.new),      // Matches '/users'
  ///   Inlet.path(':id', UserDetailPage.new), // Matches '/users/123'
  /// ])
  /// ```
  const Inlet.nested(this.path, this.factory, this.children);

  /// Creates a custom route that matches a specific path segment.
  ///
  /// Custom routes are used when the path segment is not a simple string.
  /// They must use [Outlet] to render children.
  ///
  /// Example:
  /// ```dart
  /// Inlet.custom(path: '/:id', factory: UserPage.new) // Matches '/123', params={'id': '123'}
  /// ```
  const Inlet.custom({
    required this.path,
    required this.factory,
    this.children = const [],
  });

  @override
  String toString() {
    final str = (path != null && path?.isNotEmpty == true)
        ? path
        : children.isNotEmpty
        ? '<layout>'
        : '<index>';
    if (children.isEmpty) return 'Inlet($str)';
    return 'Inlet($str, children: ${children.length})';
  }
}
