import '../history/browser.dart';
import '../history/history.dart';
import '../url_strategy.dart';

History createHistory(UrlStrategy strategy) {
  if (strategy == .browser) {
    return BrowserHistory();
  }

  return HashHistory();
}
