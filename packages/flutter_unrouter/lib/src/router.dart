import 'package:flutter/widgets.dart';
import 'package:unrouter_core/unrouter_core.dart' as core;
import 'package:unstory/unstory.dart';

import 'inlet.dart';

/// Flutter-specialized Unrouter type alias.
typedef Unrouter = core.Unrouter<Widget>;

/// Creates a Flutter router backed by [core.createRouter].
Unrouter createRouter({
  required Iterable<Inlet> routes,
  Iterable<core.Guard>? guards,
  String base = '/',
  int maxRedirectDepth = 8,
  History? history,
  HistoryStrategy strategy = HistoryStrategy.browser,
}) {
  return core.createRouter<Widget>(
    routes: routes,
    guards: guards,
    base: base,
    maxRedirectDepth: maxRedirectDepth,
    history: history,
    strategy: strategy,
    errorReporter: (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          context: ErrorDescription('while processing history pop event'),
        ),
      );
    },
  );
}
