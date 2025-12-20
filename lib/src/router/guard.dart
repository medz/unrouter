import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class GuardContext {
  final RouteInformation to;
  final RouteInformation from;
  final int redirectCount;
  final bool replace;

  const GuardContext({
    required this.to,
    required this.from,
    required this.redirectCount,
    required this.replace,
  });
}

class GuardResult {
  final Uri uri;
  final Object? state;
  final bool replace;

  const GuardResult.redirect(this.uri, {this.state, this.replace = true});

  static const GuardResult allow = _GuardResultAllow();
  static const GuardResult cancel = _GuardResultCancel();
}

mixin _GuardResultPlaceholder implements GuardResult {
  @override
  bool get replace => throw UnimplementedError();

  @override
  Object? get state => throw UnimplementedError();

  @override
  Uri get uri => throw UnimplementedError();
}

class _GuardResultAllow with _GuardResultPlaceholder {
  @literal
  const _GuardResultAllow();
}

class _GuardResultCancel with _GuardResultPlaceholder {
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

    unawaited(
      Future.microtask(() async {
        try {
          for (final guard in guards) {
            if (completed) return;
            final result = await Future.value(guard(context)).catchError((e) {
              if (e is GuardResult) return e;
              throw e;
            });
            if (completed) return;
            if (result == .cancel) return cancel();
            if (result != .allow) {
              final nextContext = GuardContext(
                to: RouteInformation(uri: result.uri, state: result.state),
                from: context.to,
                redirectCount: context.redirectCount + 1,
                replace: result.replace,
              );
              if (nextContext.redirectCount > maxRedirects) {
                return cancel();
              }
              completed = true;
              completer.complete(nextContext);
              return;
            }
          }

          for (final guard in extraGuards) {
            if (completed) return;
            final result = await Future.value(guard(context)).catchError((e) {
              if (e is GuardResult) return e;
              throw e;
            });
            if (completed) return;
            if (result == .cancel) return cancel();
            if (result != .allow) {
              final nextContext = GuardContext(
                to: RouteInformation(uri: result.uri, state: result.state),
                from: context.to,
                redirectCount: context.redirectCount + 1,
                replace: result.replace,
              );
              if (nextContext.redirectCount > maxRedirects) {
                return cancel();
              }
              completed = true;
              completer.complete(nextContext);
              return;
            }
          }

          if (!completed) {
            completed = true;
            completer.complete(context);
          }
        } catch (error, stackTrace) {
          fail(error, stackTrace);
        }
      }),
    );

    return completer.future;
  }
}
