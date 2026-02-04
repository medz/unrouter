import 'package:flutter/widgets.dart';

import 'guard.dart';

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
/// final routes = RouteIndex.fromRoutes([
///   Inlet(name: 'home', factory: HomePage.new),
///   Inlet(name: 'about', path: 'about', factory: AboutPage.new),
///   Inlet(factory: AuthLayout.new, children: [
///     Inlet(name: 'login', path: 'login', factory: LoginPage.new),
///     Inlet(name: 'register', path: 'register', factory: RegisterPage.new),
///   ]),
///   Inlet(path: 'users', factory: UsersLayout.new, children: [
///     Inlet(name: 'usersIndex', factory: UsersIndexPage.new),
///     Inlet(name: 'userDetail', path: ':id', factory: UserDetailPage.new),
///   ]),
/// ]);
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
  /// - Embedded params: `'files/:name.:ext'`
  /// - Single-segment wildcard: `'*'` (params `_0`, `_1`, ...)
  /// - Multi-segment wildcard: `'**'` (params `_`) or `'**:path'`
  final String path;

  /// Optional unique name for this route.
  ///
  /// Named routes can be used with `Navigate` (call with `name`) or
  /// `Navigate.route(...)` to generate URIs. Names must be unique within
  /// the route tree.
  final String? name;

  /// Factory function that creates the widget for this route.
  final Widget Function() factory;

  /// Guards that run when navigating to this route.
  ///
  /// Guards run after global guards and follow the matched route stack
  /// from root to leaf.
  final List<Guard> guards;

  /// Child routes.
  final List<Inlet> children;

  const Inlet({
    this.path = '',
    this.name,
    required this.factory,
    this.guards = const [],
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
