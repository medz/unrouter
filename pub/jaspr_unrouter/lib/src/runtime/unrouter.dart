import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart'
    as core
    show
        RedirectDiagnosticsCallback,
        RedirectLoopPolicy,
        RouteExecutionSignal,
        RouteNeverCancelledSignal,
        RouteRecord,
        RouteResolution,
        RouteResolutionType,
        Unrouter,
        UnrouterController,
        UnrouterStateSnapshot;
import 'package:unstory/unstory.dart';

import '../core/route_data.dart';
import '../core/route_definition.dart';
import 'navigation.dart';

typedef _CoreRouteRecord<T extends RouteData> = core.RouteRecord<T>;
typedef _CoreRouteResolution<R extends RouteData> = core.RouteResolution<R>;
typedef _CoreRouteResolutionType = core.RouteResolutionType;
typedef _CoreUnrouter<R extends RouteData> = core.Unrouter<R>;
typedef _CoreUnrouterController<R extends RouteData> =
    core.UnrouterController<R>;

typedef RouteResolutionType = _CoreRouteResolutionType;
typedef RouteResolution<R extends RouteData> = _CoreRouteResolution<R>;

/// Builds fallback UI for unmatched locations.
typedef UnknownRouteBuilder = Component Function(BuildContext context, Uri uri);

/// Builds fallback UI for resolution errors.
typedef RouteErrorBuilder =
    Component Function(
      BuildContext context,
      Object error,
      StackTrace stackTrace,
    );

/// Builds fallback UI while route resolution is pending.
typedef RouteLoadingBuilder = Component Function(BuildContext context, Uri uri);

/// Jaspr adapter router configuration.
///
/// This adapter wraps the platform-agnostic `unrouter` core and exposes
/// `createController()` for pure-Dart usage.
class Unrouter<R extends RouteData> {
  Unrouter({
    required List<RouteRecord<R>> routes,
    this.maxRedirectHops = 8,
    this.redirectLoopPolicy = core.RedirectLoopPolicy.error,
    this.onRedirectDiagnostics,
    this.history,
    this.base,
    this.strategy = HistoryStrategy.browser,
    this.resolveInitialRoute = true,
  }) : assert(routes.isNotEmpty, 'Unrouter routes must not be empty.'),
       assert(
         maxRedirectHops > 0,
         'Unrouter maxRedirectHops must be greater than zero.',
       ),
       routes = List<RouteRecord<R>>.unmodifiable(routes),
       _recordsByCore = Map<_CoreRouteRecord<R>, RouteRecord<R>>.unmodifiable(
         <_CoreRouteRecord<R>, RouteRecord<R>>{
           for (final record in routes) record.core: record,
         },
       ),
       _core = _CoreUnrouter<R>(
         routes: routes
             .map<_CoreRouteRecord<R>>((record) => record.core)
             .toList(growable: false),
         maxRedirectHops: maxRedirectHops,
         redirectLoopPolicy: redirectLoopPolicy,
         onRedirectDiagnostics: onRedirectDiagnostics,
       );

  /// Immutable route table consumed by the matcher.
  final List<RouteRecord<R>> routes;
  final Map<_CoreRouteRecord<R>, RouteRecord<R>> _recordsByCore;
  final _CoreUnrouter<R> _core;

  /// Redirect hop limit used to prevent infinite redirect chains.
  final int maxRedirectHops;

  /// Policy used when redirect loops are detected.
  final core.RedirectLoopPolicy redirectLoopPolicy;

  /// Callback invoked when redirect safety checks emit diagnostics.
  final core.RedirectDiagnosticsCallback? onRedirectDiagnostics;

  /// Optional runtime history instance to use.
  final History? history;

  /// Optional base path for generated browser hrefs.
  final String? base;

  /// History strategy used when creating browser-backed history.
  final HistoryStrategy strategy;

  /// Whether controllers created by this router resolve initial location.
  final bool resolveInitialRoute;

  /// Resolves [uri] to a typed route, redirect, block, or error result.
  Future<RouteResolution<R>> resolve(
    Uri uri, {
    core.RouteExecutionSignal signal = const core.RouteNeverCancelledSignal(),
  }) {
    return _core.resolve(uri, signal: signal);
  }

  /// Returns adapter record from a core record when available.
  RouteRecord<R>? routeRecordOf(core.RouteRecord<R>? record) {
    if (record == null) {
      return null;
    }
    return _recordsByCore[record];
  }

  /// Underlying platform-agnostic core router.
  core.Unrouter<R> get coreRouter => _core;

  /// Creates a core runtime controller for this adapter router.
  UnrouterController<R> createController({
    History? history,
    bool? resolveInitialRoute,
    bool? disposeHistory,
  }) {
    final hasExternalHistory = history != null || this.history != null;
    final effectiveHistory =
        history ??
        this.history ??
        createHistory(base: base, strategy: strategy);
    final shouldDisposeHistory = disposeHistory ?? !hasExternalHistory;

    final coreController = _CoreUnrouterController<R>(
      router: _core,
      history: effectiveHistory,
      resolveInitialRoute: resolveInitialRoute ?? this.resolveInitialRoute,
      disposeHistory: shouldDisposeHistory,
    );
    return UnrouterController<R>.fromCore(coreController);
  }
}

/// Jaspr component that mounts an [Unrouter] and renders from core runtime
/// state, keeping semantics aligned across adapters.
class UnrouterRouter<R extends RouteData> extends StatefulComponent {
  const UnrouterRouter({
    required this.router,
    this.unknown,
    this.onError,
    this.loading,
    this.blocked,
    this.history,
    this.resolveInitialRoute,
    super.key,
  });

  final Unrouter<R> router;
  final UnknownRouteBuilder? unknown;
  final RouteErrorBuilder? onError;
  final RouteLoadingBuilder? loading;
  final UnknownRouteBuilder? blocked;

  /// Optional history override for this mounted router instance.
  final History? history;

  /// Optional initial-resolution override for this mounted router instance.
  final bool? resolveInitialRoute;

  @override
  State<UnrouterRouter<R>> createState() => _UnrouterRouterState<R>();
}

class _UnrouterRouterState<R extends RouteData> extends State<UnrouterRouter<R>>
    with PreloadStateMixin<UnrouterRouter<R>> {
  UnrouterController<R>? _controller;
  StreamSubscription<core.UnrouterStateSnapshot<R>>? _stateSubscription;
  late RouteResolution<R> _resolution;

  @override
  Future<void> preloadState() async {
    _ensureController();
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.idle;
    _resolution = controller.resolution;
  }

  @override
  void initState() {
    super.initState();
    _ensureController();
    final controller = _controller;
    if (controller == null) {
      return;
    }

    _resolution = controller.resolution;
    if (context.binding.isClient) {
      _stateSubscription = controller.states.listen((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _resolution = controller.resolution;
        });
      });
    }
  }

  @override
  void didUpdateComponent(covariant UnrouterRouter<R> oldComponent) {
    super.didUpdateComponent(oldComponent);
    final shouldRecreateController =
        oldComponent.router != component.router ||
        oldComponent.history != component.history ||
        oldComponent.resolveInitialRoute != component.resolveInitialRoute;
    if (!shouldRecreateController) {
      return;
    }

    _disposeController();
    _ensureController();
    final controller = _controller;
    if (controller == null) {
      return;
    }
    _resolution = controller.resolution;
    if (context.binding.isClient) {
      _stateSubscription = controller.states.listen((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _resolution = controller.resolution;
        });
      });
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Component.empty();
    }

    return UnrouterScope(
      controller: controller.cast<RouteData>(),
      child: _buildFromResolution(context),
    );
  }

  void _ensureController() {
    if (_controller != null) {
      return;
    }

    final historyPlan = _resolveHistory();
    _controller = component.router.createController(
      history: historyPlan.history,
      resolveInitialRoute: component.resolveInitialRoute,
      disposeHistory: historyPlan.disposeHistory,
    );
    _resolution = _controller!.resolution;
  }

  _HistoryPlan _resolveHistory() {
    final explicit = component.history;
    if (explicit != null) {
      return _HistoryPlan(history: explicit, disposeHistory: false);
    }

    final routerHistory = component.router.history;
    if (routerHistory != null) {
      return _HistoryPlan(history: routerHistory, disposeHistory: false);
    }

    if (context.binding.isClient) {
      return _HistoryPlan(
        history: createHistory(
          base: component.router.base,
          strategy: component.router.strategy,
        ),
        disposeHistory: true,
      );
    }

    final uri = _normalizeRequestUri(context.url);
    return _HistoryPlan(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[HistoryLocation(uri)],
        initialIndex: 0,
        base: component.router.base,
      ),
      disposeHistory: true,
    );
  }

  void _disposeController() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _controller?.dispose();
    _controller = null;
  }

  Component _buildFromResolution(BuildContext context) {
    final resolution = _resolution;
    if (resolution.isPending) {
      final loadingBuilder = component.loading;
      if (loadingBuilder != null) {
        return loadingBuilder(context, resolution.uri);
      }
      return const Component.empty();
    }

    if (resolution.hasError) {
      return _buildError(
        context,
        resolution.error!,
        resolution.stackTrace ?? StackTrace.current,
      );
    }

    if (resolution.isBlocked) {
      final blockedBuilder = component.blocked;
      if (blockedBuilder != null) {
        return blockedBuilder(context, resolution.uri);
      }

      return _buildError(
        context,
        StateError('Route blocked for "${resolution.uri}".'),
        StackTrace.current,
      );
    }

    if (resolution.isMatched) {
      final routeRecord = component.router.routeRecordOf(resolution.record);
      if (routeRecord == null) {
        return _buildError(
          context,
          StateError(
            'Matched route record is missing from jaspr adapter registry.',
          ),
          StackTrace.current,
        );
      }

      try {
        return routeRecord.build(
          context,
          resolution.route!,
          resolution.loaderData,
        );
      } catch (error, stackTrace) {
        return _buildError(context, error, stackTrace);
      }
    }

    final unknown = component.unknown;
    if (unknown != null) {
      return unknown(context, resolution.uri);
    }

    return Component.text('No route matches ${resolution.uri.path}');
  }

  Component _buildError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final fallback = component.onError;
    if (fallback != null) {
      return fallback(context, error, stackTrace);
    }
    return Component.text('jaspr_unrouter error: $error');
  }

  static Uri _normalizeRequestUri(String raw) {
    Uri parsed;
    try {
      parsed = Uri.parse(raw);
    } catch (_) {
      return Uri(path: '/');
    }

    final path = parsed.path.isEmpty
        ? '/'
        : (parsed.path.startsWith('/') ? parsed.path : '/${parsed.path}');
    return Uri(
      path: path,
      query: parsed.query.isEmpty ? null : parsed.query,
      fragment: parsed.fragment.isEmpty ? null : parsed.fragment,
    );
  }
}

final class _HistoryPlan {
  const _HistoryPlan({required this.history, required this.disposeHistory});

  final History history;
  final bool disposeHistory;
}
