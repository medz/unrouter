import 'package:nocterm/nocterm.dart';
import 'package:unrouter_core/unrouter_core.dart' as core;
import 'package:unstory/unstory.dart';

import 'inlet.dart';

/// Nocterm-specialized Unrouter type alias.
typedef Unrouter<V> = core.Unrouter<V>;

/// Creates a Nocterm router backed by [core.createRouter].
Unrouter<Component> createRouter({
  required Iterable<Inlet> routes,
  Iterable<core.Guard>? guards,
  String base = '/',
  int maxRedirectDepth = 8,
  History? history,
  HistoryStrategy strategy = HistoryStrategy.browser,
}) {
  return core.createRouter<Component>(
    routes: routes,
    guards: guards,
    base: base,
    maxRedirectDepth: maxRedirectDepth,
    history: history,
    strategy: strategy,
  );
}
