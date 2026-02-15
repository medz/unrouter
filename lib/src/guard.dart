import 'dart:async';

import 'package:ht/ht.dart';
import 'package:unstory/unstory.dart';

import 'route_params.dart';

typedef Guard = FutureOr<GuardResult> Function(GuardContext context);

Guard defineGuard(Guard guard) => guard;

final class GuardContext {
  const GuardContext({
    required this.from,
    required this.to,
    required this.action,
    required this.params,
    required this.query,
    required this.meta,
    required this.state,
  });

  final HistoryLocation from;
  final HistoryLocation to;
  final HistoryAction action;
  final RouteParams params;
  final URLSearchParams query;
  final Map<String, Object?> meta;
  final Object? state;
}

sealed class GuardResult {
  const GuardResult();

  const factory GuardResult.allow() = GuardAllow;
  const factory GuardResult.block() = GuardBlock;
  const factory GuardResult.redirect(
    String pathOrName, {
    Map<String, String>? params,
    URLSearchParams? query,
    Object? state,
  }) = GuardRedirect;
}

final class GuardAllow extends GuardResult {
  const GuardAllow();
}

final class GuardBlock extends GuardResult {
  const GuardBlock();
}

final class GuardRedirect extends GuardResult {
  const GuardRedirect(
    this.pathOrName, {
    this.params,
    this.query,
    this.state,
  });

  final String pathOrName;
  final Map<String, String>? params;
  final URLSearchParams? query;
  final Object? state;
}
