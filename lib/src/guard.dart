import 'dart:async';

import 'package:unstory/unstory.dart';

import 'route_params.dart';
import 'url_search_params.dart';

/// Evaluates whether a navigation attempt should continue.
///
/// Guards run during push/replace navigation and history pop navigation.
/// They receive a [GuardContext] and must return one of the explicit
/// [GuardResult] variants to allow, block, or redirect the attempt.
typedef Guard = FutureOr<GuardResult> Function(GuardContext context);

/// Returns the provided [guard] unchanged.
///
/// This helper keeps guard declarations explicit and discoverable at callsites,
/// especially when declaring route-level or global guard lists.
Guard defineGuard(Guard guard) => guard;

/// Immutable navigation snapshot passed to each [Guard].
///
/// A new context is created for each evaluated destination, including redirected
/// destinations in the same navigation flow.
final class GuardContext {
  /// Creates a guard context for a single navigation attempt.
  const GuardContext({
    required this.from,
    required this.to,
    required this.action,
    required this.params,
    required this.query,
    required this.meta,
    required this.state,
  });

  /// The last accepted location before this evaluation.
  final HistoryLocation from;

  /// The candidate destination currently being evaluated.
  final HistoryLocation to;

  /// The history action that triggered this evaluation.
  final HistoryAction action;

  /// Route params resolved for [to].
  final RouteParams params;

  /// Query params resolved for [to].
  final URLSearchParams query;

  /// Merged route metadata for [to].
  final Map<String, Object?> meta;

  /// Candidate navigation state for [to].
  final Object? state;
}

/// The outcome returned by a [Guard].
///
/// This sealed hierarchy is the only supported guard control flow.
/// Throwing exceptions is treated as an error, not as navigation control.
sealed class GuardResult {
  /// Creates a guard result.
  const GuardResult();

  /// Allows navigation to continue with the current destination.
  const factory GuardResult.allow() = GuardAllow;

  /// Blocks navigation and keeps the current location.
  const factory GuardResult.block() = GuardBlock;

  /// Redirects navigation to another route name or absolute path.
  ///
  /// The [pathOrName] target is resolved with the same rules as router
  /// navigation APIs: route-name lookup first, then absolute-path resolution.
  /// If [query] is provided, it overrides same-name keys from inline query
  /// inside [pathOrName].
  const factory GuardResult.redirect(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    Object? state,
  }) = GuardRedirect;
}

/// A [GuardResult] that permits navigation.
final class GuardAllow extends GuardResult {
  /// Creates an allow result.
  const GuardAllow();
}

/// A [GuardResult] that denies navigation.
final class GuardBlock extends GuardResult {
  /// Creates a block result.
  const GuardBlock();
}

/// A [GuardResult] that requests navigation redirection.
final class GuardRedirect extends GuardResult {
  /// Creates a redirect result.
  const GuardRedirect(this.pathOrName, {this.params, this.query, this.state});

  /// Route name or absolute path used as the redirect target.
  final String pathOrName;

  /// Params used when [pathOrName] resolves as a route name.
  ///
  /// This value is ignored when [pathOrName] resolves as an absolute path.
  final Map<String, String>? params;

  /// Query values that override same-name keys on collision.
  final URLSearchParams? query;

  /// Navigation state forwarded to the redirected destination.
  final Object? state;
}
