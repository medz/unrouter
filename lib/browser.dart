/// Web history implementations for `unrouter`.
///
/// Most apps can rely on `Unrouter`'s default history selection. Import this
/// library when you need to construct and inject a web history manually.
///
/// ```dart
/// import 'package:unrouter/browser.dart';
/// import 'package:unrouter/unrouter.dart';
///
/// final router = Unrouter(
///   history: HashHistory(),
///   routes: const [Inlet(factory: HomePage.new)],
/// );
/// ```
///
/// This library is intended for Flutter Web. It depends on `dart:js_interop`
/// and `package:web`.
library;

export 'src/history/browser.dart' hide createHistory;
