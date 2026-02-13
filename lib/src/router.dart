import 'package:unstory/unstory.dart';

import 'inlet.dart';
import 'middleware.dart';

class Unrouter {
  Unrouter({
    required this.routes,
    this.middleware = const [],
    History? history,
    String? base,
    HistoryStrategy strategy = HistoryStrategy.browser,
  }) : history = history ??= createHistory(strategy: strategy);

  final Iterable<Inlet> routes;
  final Iterable<Middleware> middleware;
  final History history;
}
