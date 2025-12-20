import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'history/history.dart';

@immutable
sealed class Navigation {
  const Navigation({required this.from, required this.requested});

  final RouteInformation from;
  final RouteInformation requested;
}

final class NavigationSuccess extends Navigation {
  const NavigationSuccess({
    required super.from,
    required super.requested,
    required this.to,
    required this.action,
    this.redirectCount = 0,
  });

  final RouteInformation to;
  final HistoryAction action;
  final int redirectCount;
}

final class NavigationRedirected extends NavigationSuccess {
  const NavigationRedirected({
    required super.from,
    required super.requested,
    required super.to,
    required super.action,
    required super.redirectCount,
  });
}

final class NavigationCancelled extends Navigation {
  const NavigationCancelled({required super.from, required super.requested});
}

final class NavigationFailed extends Navigation {
  const NavigationFailed({
    required super.from,
    required super.requested,
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;
}
