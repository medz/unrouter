import 'package:unrouter/history.dart';
import 'package:unrouter/src/history/browser.dart';

import '../url_strategy.dart';

/// Creates the default web [History] for the given [UrlStrategy].
History createHistory(UrlStrategy strategy) {
  return switch (strategy) {
    .browser => BrowserHistory(),
    _ => HashHistory(),
  };
}
