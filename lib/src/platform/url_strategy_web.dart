import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import '../url_strategy.dart';

void applyUrlStrategy(RouterUrlStrategy strategy) {
  switch (strategy) {
    case RouterUrlStrategy.hash:
      setUrlStrategy(const HashUrlStrategy());
    case RouterUrlStrategy.path:
      setUrlStrategy(PathUrlStrategy());
  }
}
