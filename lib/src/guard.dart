import 'dart:async';

import 'package:unstory/unstory.dart';

import 'route_params.dart';
import 'url_search_params.dart';

/// Evaluates whether a navigation attempt should continue.
typedef Guard = FutureOr<GuardResult> Function(GuardContext context);

/// Returns the provided [guard] unchanged.
///
/// This helper keeps guard declarations explicit and discoverable in code.
Guard defineGuard(Guard guard) => guard;

/// Immutable context passed to each [Guard] during navigation evaluation.
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

  /// The last accepted location before this attempt.
  final HistoryLocation from;

  /// The candidate destination currently being evaluated.
  final HistoryLocation to;

  /// The action that triggered this evaluation.
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

/// Represents the outcome of a guard evaluation.
sealed class GuardResult {
  /// Creates a guard result.
  const GuardResult();

  /// Allows navigation to continue.
  const factory GuardResult.allow() = GuardAllow;

  /// Blocks navigation and keeps the current location.
  const factory GuardResult.block() = GuardBlock;

  /// Redirects navigation to another route name or absolute path.
  const factory GuardResult.redirect(
    /// Route name or absolute path used as the redirect target.
    String pathOrName, {

    /// Optional params used when [pathOrName] resolves by route name.
    Map<String, String>? params,

    /// Optional query that overrides existing keys on collision.
    URLSearchParams? query,

    /// Optional state for the redirect destination.
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

  /// Optional params used for route-name redirects.
  final Map<String, String>? params;

  /// Optional query that overrides existing keys on collision.
  final URLSearchParams? query;

  /// Optional state forwarded to the redirected location.
  final Object? state;
}
