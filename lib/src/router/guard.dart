import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'route_location.dart';

class GuardContext {
  final RouteLocation to;
  final RouteLocation from;
  final int redirectCount;
  final bool replace;

  const GuardContext({
    required this.to,
    required this.from,
    required this.redirectCount,
    required this.replace,
  });
}

sealed class GuardResult {
  const GuardResult();

  static const GuardResult allow = _GuardResultAllow();
  static const GuardResult cancel = _GuardResultCancel();

  factory GuardResult.redirect({
    String? name,
    String? path,
    Map<String, String> params,
    Map<String, String>? query,
    String? fragment,
    Object? state,
    bool replace,
  }) = GuardRedirect;

  factory GuardResult.redirectUri(Uri uri, {Object? state, bool replace}) =
      GuardRedirectUri;
}

class GuardRedirect extends GuardResult {
  const GuardRedirect({
    this.name,
    this.path,
    this.params = const {},
    this.query,
    this.fragment,
    this.state,
    this.replace = true,
  }) : assert(
         (name != null && name != '') || (path != null && path != ''),
         'Provide a route name or a path.',
       ),
       assert(
         name == null || path == null,
         'Provide either name or path, not both.',
       );

  final String? name;
  final String? path;
  final Map<String, String> params;
  final Map<String, String>? query;
  final String? fragment;
  final Object? state;
  final bool replace;
}

class GuardRedirectUri extends GuardResult {
  const GuardRedirectUri(this.uri, {this.state, this.replace = true});

  final Uri uri;
  final Object? state;
  final bool replace;
}

class _GuardResultAllow extends GuardResult {
  @literal
  const _GuardResultAllow();
}

class _GuardResultCancel extends GuardResult {
  @literal
  const _GuardResultCancel();
}

typedef Guard = FutureOr<GuardResult> Function(GuardContext context);

class GuardExecutor {
  GuardExecutor(this.guards, this.maxRedirects);

  final Iterable<Guard> guards;
  final int maxRedirects;

  ValueGetter<bool>? _hasCompleted;
  VoidCallback? _complete;

  Future<GuardContext?> execute(
    GuardContext context, {
    Iterable<Guard> extraGuards = const [],
    RouteLocation Function(RouteInformation location)? decorateLocation,
    RouteInformation Function(GuardRedirect redirect)? resolveRedirect,
  }) {
    if (guards.isEmpty && extraGuards.isEmpty) {
      return SynchronousFuture(context);
    }
    if (_hasCompleted?.call() != true) {
      _complete?.call();
    }

    final completer = Completer<GuardContext?>();
    bool completed = false;
    void cancel() {
      if (completed) return;
      completed = true;
      completer.complete(null);
    }

    void fail(Object error, StackTrace stackTrace) {
      if (completed) return;
      completed = true;
      completer.completeError(error, stackTrace);
    }

    _complete = cancel;
    _hasCompleted = () => completed;

    final decorate =
        decorateLocation ??
        (RouteInformation location) => location is RouteLocation
            ? location
            : RouteLocation(
                uri: location.uri,
                state: location.state,
                name: null,
              );

    unawaited(
      Future.microtask(() async {
        try {
          final result = await _executeGuardChain(
            [...guards, ...extraGuards],
            context,
            () => completed,
            decorate,
            resolveRedirect,
          );
          if (completed) return;
          if (result == null) {
            cancel();
            return;
          }
          completed = true;
          completer.complete(result);
        } catch (error, stackTrace) {
          fail(error, stackTrace);
        }
      }),
    );

    return completer.future;
  }

  Future<GuardContext?> _executeGuardChain(
    Iterable<Guard> guards,
    GuardContext context,
    bool Function() isCompleted,
    RouteLocation Function(RouteInformation location) decorateLocation,
    RouteInformation Function(GuardRedirect redirect)? resolveRedirect,
  ) async {
    for (final guard in guards) {
      if (isCompleted()) return null;
      final result = await Future.value(guard(context)).catchError((e) {
        if (e is GuardResult) return e;
        throw e;
      });
      if (isCompleted()) return null;
      if (result == .cancel) return null;
      if (result is GuardRedirectUri) {
        final nextContext = GuardContext(
          to: decorateLocation(
            RouteInformation(uri: result.uri, state: result.state),
          ),
          from: context.to,
          redirectCount: context.redirectCount + 1,
          replace: result.replace,
        );
        if (nextContext.redirectCount > maxRedirects) {
          return null;
        }
        return nextContext;
      }

      if (result is GuardRedirect) {
        if (resolveRedirect == null) {
          throw FlutterError(
            'GuardResult.redirect requires a router to resolve the destination.',
          );
        }
        final resolved = resolveRedirect(result);
        final nextContext = GuardContext(
          to: decorateLocation(resolved),
          from: context.to,
          redirectCount: context.redirectCount + 1,
          replace: result.replace,
        );
        if (nextContext.redirectCount > maxRedirects) {
          return null;
        }
        return nextContext;
      }
    }
    return context;
  }
}
