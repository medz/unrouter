import 'package:flutter/widgets.dart';

/// A route configuration that defines a path pattern and widget factory.
///
/// Routes can be created using named constructors:
/// - [Route.index] - Index route (matches when no path segment)
/// - [Route.path] - Path route (matches a specific path segment)
/// - [Route.layout] - Layout route (wraps children without adding path segment)
/// - [Route.nested] - Nested route (has path segment and wraps children)
///
/// Example:
/// ```dart
/// final routes = [
///   Route.index(HomePage.new),
///   Route.path('about', AboutPage.new),
///   Route.layout(AuthLayout.new, [
///     Route.path('login', LoginPage.new),
///     Route.path('register', RegisterPage.new),
///   ]),
///   Route.nested('users', UsersLayout.new, [
///     Route.index(UsersIndexPage.new),
///     Route.path(':id', UserDetailPage.new),
///   ]),
/// ];
/// ```
class Route {
  /// Path pattern for this route.
  /// - `null` for index routes and layout routes
  /// - Static segments: `'about'`, `'users'`
  /// - Dynamic params: `':id'`, `':userId'`
  final String? path;

  /// Factory function that creates the widget for this route.
  final Widget Function() factory;

  /// Child routes.
  final List<Route> children;

  /// Whether this is a layout route (no path segment, just wraps children).
  final bool layout;

  const Route({
    required this.path,
    required this.factory,
    this.children = const [],
    this.layout = false,
  });

  /// Creates an index route that matches when no path segment remains.
  ///
  /// Example:
  /// ```dart
  /// Route.index(HomePage.new)  // Matches '/' or when parent path is fully matched
  /// ```
  const Route.index(this.factory)
    : path = null,
      children = const [],
      layout = false;

  /// Creates a path route that matches a specific path segment.
  ///
  /// Example:
  /// ```dart
  /// Route.path('about', AboutPage.new)  // Matches '/about'
  /// Route.path(':id', UserPage.new)     // Matches '/123', params={'id': '123'}
  /// ```
  const Route.path(this.path, this.factory)
    : children = const [],
      layout = false;

  /// Creates a layout route that wraps children without adding a path segment.
  ///
  /// Layout routes are transparent for path matching but add a component
  /// to the widget hierarchy. They must use [RouterView] to render children.
  ///
  /// Example:
  /// ```dart
  /// Route.layout(AuthLayout.new, [
  ///   Route.path('login', LoginPage.new),    // Matches '/login'
  ///   Route.path('register', RegisterPage.new), // Matches '/register'
  /// ])
  /// ```
  const Route.layout(this.factory, this.children) : path = null, layout = true;

  /// Creates a nested route that has both a path segment and children.
  ///
  /// Nested routes add to both the URL path and the component hierarchy.
  /// They must use [RouterView] to render children.
  ///
  /// Example:
  /// ```dart
  /// Route.nested('users', UsersLayout.new, [
  ///   Route.index(UsersIndexPage.new),      // Matches '/users'
  ///   Route.path(':id', UserDetailPage.new), // Matches '/users/123'
  /// ])
  /// ```
  const Route.nested(this.path, this.factory, this.children) : layout = false;

  @override
  String toString() {
    final pathStr = path ?? (layout ? '<layout>' : '<index>');
    if (children.isEmpty) {
      return 'Route($pathStr)';
    }
    return 'Route($pathStr, children: ${children.length})';
  }
}
