import '../history/history.dart';
import '../history/memory.dart';
import '../url_strategy.dart';

History createHistory(UrlStrategy _) => MemoryHistory();
