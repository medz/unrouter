import 'package:flutter/widgets.dart';

/// A route configuration that defines a path pattern and widget factory.
///
/// The semantics are based on [path] and [children]:
/// - **Index**: `path == ''` and `children.isEmpty`
/// - **Layout**: `path == ''` and `children.isNotEmpty` (does not consume a
///   segment; must use `Outlet` to render children)
/// - **Leaf**: `path != ''` and `children.isEmpty`
/// - **Nested**: `path != ''` and `children.isNotEmpty` (consumes one or more
///   path segments; must use `Outlet` to render children)
///
/// Tip: Keep [Inlet] instances stable (prefer `const` routes). `unrouter`
/// reuses layout widgets across navigation based on route identity.
///
/// Example:
/// ```dart
/// final routes = [
///   Inlet(factory: HomePage.new),
///   Inlet(path: 'about', factory: AboutPage.new),
///   Inlet(factory: AuthLayout.new, children: [
///     Inlet(path: 'login', factory: LoginPage.new),
///     Inlet(path: 'register', factory: RegisterPage.new),
///   ]),
///   Inlet(path: 'users', factory: UsersLayout.new, children: [
///     Inlet(factory: UsersIndexPage.new),
///     Inlet(path: ':id', factory: UserDetailPage.new),
///   ]),
/// ];
/// ```
class Inlet {
  /// Path pattern for this route.
  ///
  /// Patterns are typically written without a leading slash (e.g. `users/:id`).
  ///
  /// Supported syntax:
  /// - `''` for index routes and layout routes
  /// - Static segments: `'about'`, `'users'`
  /// - Dynamic params: `':id'`, `':userId'`
  /// - Optional params/segments: `':id?'`, `'edit?'`
  /// - Wildcard: `'*'`
  final String path;

  /// Factory function that creates the widget for this route.
  final Widget Function() factory;

  /// Child routes.
  final List<Inlet> children;

  const Inlet({
    this.path = '',
    required this.factory,
    this.children = const [],
  });

  @override
  String toString() {
    final str = path.isNotEmpty
        ? path
        : children.isNotEmpty
        ? '<layout>'
        : '<index>';
    if (children.isEmpty) return 'Inlet($str)';
    return 'Inlet($str, children: ${children.length})';
  }
}
