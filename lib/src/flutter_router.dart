import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter/widgets.dart' as flutter show Router;
import 'package:ht/ht.dart';
import 'package:unrouter/src/inlet.dart';
import 'package:unstory/unstory.dart';

import 'middleware.dart';
import 'outlet.dart';
import 'route_params.dart';
import 'route_scope.dart';
import 'router.dart';

RouterConfig<HistoryLocation> createRouterConfig(Unrouter router) {
  final location = router.history.location;
  final info = RouteInformation(uri: location.uri, state: location.state);

  return RouterConfig(
    routerDelegate: _RouterDelegate(router),
    routeInformationParser: const _RouteInformationParser(),
    routeInformationProvider: _HistoryRouteInformationProvider(
      router: router,
      initialRouteInformation: info,
    ),
    backButtonDispatcher: UnrouterBackButtonDispatcher(),
  );
}

class UnrouterBackButtonDispatcher extends RootBackButtonDispatcher {
  Future<bool>? _inFlightPop;

  @override
  Future<bool> didPopRoute() {
    if (_inFlightPop case final inFlight?) {
      return inFlight;
    }

    final task = invokeCallback(Future<bool>.value(false));
    _inFlightPop = task.whenComplete(() {
      _inFlightPop = null;
    });
    return _inFlightPop!;
  }
}

final class _RouteInformationParser
    extends RouteInformationParser<HistoryLocation> {
  const _RouteInformationParser();

  @override
  Future<HistoryLocation> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return .new(routeInformation.uri, routeInformation.state);
  }

  @override
  RouteInformation? restoreRouteInformation(HistoryLocation configuration) {
    return RouteInformation(uri: configuration.uri, state: configuration.state);
  }
}

final class _HistoryRouteInformationProvider extends RouteInformationProvider
    with WidgetsBindingObserver, ChangeNotifier {
  _HistoryRouteInformationProvider({
    required this.router,
    required RouteInformation initialRouteInformation,
  }) : _value = initialRouteInformation {
    router.addListener(_syncFromRouter);
  }

  final Unrouter router;
  RouteInformation _value;

  @override
  RouteInformation get value => _value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    _value = routeInformation;
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    if (_isSameRouteInformation(_value, routeInformation)) {
      return true;
    }

    _value = routeInformation;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> didPushRoute(String route) async {
    return didPushRouteInformation(RouteInformation(uri: Uri.parse(route)));
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      WidgetsBinding.instance.addObserver(this);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void dispose() {
    router.removeListener(_syncFromRouter);
    if (hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  bool _isSameRouteInformation(RouteInformation a, RouteInformation b) {
    return a.uri == b.uri && a.state == b.state;
  }

  void _syncFromRouter() {
    final location = router.history.location;
    _value = RouteInformation(uri: location.uri, state: location.state);
  }
}

class _RouterDelegate extends RouterDelegate<HistoryLocation>
    with ChangeNotifier {
  _RouterDelegate(this.router) : _configuration = router.history.location {
    router.addListener(_handleRouterChange);
  }

  final Unrouter router;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  HistoryLocation _configuration;
  HistoryLocation? _fromLocation;

  @override
  HistoryLocation get currentConfiguration => _configuration;

  @override
  Widget build(BuildContext context) {
    final result = router.matcher.match(currentConfiguration.path);
    final content = switch (result) {
      null => const SizedBox.shrink(),
      final match => RouteScopeProvider(
        route: match.data,
        params: RouteParams(match.params ?? const {}),
        location: currentConfiguration,
        fromLocation: _fromLocation,
        query: URLSearchParams(currentConfiguration.uri.query),
        child: makeRouterView(
          match.data.views,
          middleware: match.data.middleware,
        ),
      ),
    };

    return Navigator(
      key: _navigatorKey,
      pages: [
        _RouterPage(
          key: const ValueKey('unrouter-root-page'),
          name: currentConfiguration.path,
          child: content,
        ),
      ],
      onDidRemovePage: (_) {},
    );
  }

  Widget makeRouterView(
    Iterable<ViewBuilder> views, {
    Iterable<Middleware> middleware = const [],
  }) {
    final routeView = buildOutletTree(views);
    final chain = middleware.toList(growable: false);
    if (chain.isEmpty) {
      return routeView;
    }

    return _MiddlewareRunner(
      middleware: chain,
      token: Object.hash(
        _configuration.uri.toString(),
        _configuration.state,
        chain.length,
      ),
      child: routeView,
    );
  }

  @override
  Future<bool> popRoute() async {
    final navigator = _navigatorKey.currentState;
    if (navigator != null && await navigator.maybePop()) {
      return true;
    }

    final index = router.history.index ?? 0;
    if (index <= 0) {
      return false;
    }

    router.back();
    return true;
  }

  @override
  Future<void> setNewRoutePath(HistoryLocation configuration) async {
    final current = router.history.location;
    if (current.uri == configuration.uri &&
        current.state == configuration.state) {
      return;
    }

    await router.replace(
      configuration.uri.toString(),
      state: configuration.state,
    );
  }

  void _handleRouterChange() {
    final next = router.history.location;
    if (next.uri == _configuration.uri && next.state == _configuration.state) {
      return;
    }

    _fromLocation = _configuration;
    _configuration = next;
    notifyListeners();
  }

  @override
  void dispose() {
    router.removeListener(_handleRouterChange);
    super.dispose();
  }
}

class _RouterPage extends Page<void> {
  const _RouterPage({required this.child, required super.key, super.name});

  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) {
    return _RouterPageRoute(this);
  }
}

class _RouterPageRoute extends PageRoute<void> {
  _RouterPageRoute(_RouterPage page) : super(settings: page);

  _RouterPage get _page => settings as _RouterPage;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _page.child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

Unrouter useRouter(BuildContext context) {
  final flutter.Router(:routerDelegate) = .of(context);
  if (routerDelegate case _RouterDelegate(:final router)) {
    return router;
  }

  throw FlutterError('Router is not an instance of Unrouter');
}

class _MiddlewareRunner extends StatefulWidget {
  const _MiddlewareRunner({
    required this.middleware,
    required this.child,
    required this.token,
  });

  final List<Middleware> middleware;
  final Widget child;
  final Object token;

  @override
  State<_MiddlewareRunner> createState() => _MiddlewareRunnerState();
}

class _MiddlewareRunnerState extends State<_MiddlewareRunner> {
  Future<Widget>? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _result = _run();
  }

  @override
  void didUpdateWidget(covariant _MiddlewareRunner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.middleware, widget.middleware) ||
        oldWidget.token != widget.token ||
        oldWidget.child != widget.child) {
      _result = _run();
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result ??= _run();
    return FutureBuilder<Widget>(
      future: result,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorWidget(snapshot.error!);
        }
        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }

  Future<Widget> _run() {
    return _runAt(0);
  }

  Future<Widget> _runAt(int index) {
    if (index >= widget.middleware.length) {
      return SynchronousFuture(widget.child);
    }

    final middleware = widget.middleware[index];
    var called = false;
    Future<Widget> next() {
      if (called) {
        throw StateError('Middleware next() called more than once.');
      }
      called = true;
      return _runAt(index + 1);
    }

    return Future<Widget>.value(middleware(context, next));
  }
}
