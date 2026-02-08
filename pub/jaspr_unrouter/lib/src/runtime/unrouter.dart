import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart'
    as core
    show
        RouteResolution,
        RouteResolutionType,
        Unrouter,
        UnrouterController,
        UnrouterStateSnapshot;
import 'package:unstory/unstory.dart';

import '../core/route_data.dart';
import '../core/route_definition.dart';
import 'navigation.dart';

typedef _CoreRouteResolution<R extends RouteData> = core.RouteResolution<R>;
typedef _CoreRouteResolutionType = core.RouteResolutionType;
typedef _CoreUnrouter<R extends RouteData> = core.Unrouter<R>;
typedef _CoreUnrouterController<R extends RouteData> =
    core.UnrouterController<R>;

/// Core router type reused directly by adapter.
typedef Unrouter<R extends RouteData> = _CoreUnrouter<R>;

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

/// Jaspr component that mounts a core [Unrouter] and renders from core runtime
/// state. Adapter package only handles platform binding + rendering.
class UnrouterRouter<R extends RouteData> extends StatefulComponent {
  const UnrouterRouter({
    required this.router,
    this.unknown,
    this.onError,
    this.loading,
    this.blocked,
    this.history,
    this.base,
    this.strategy = HistoryStrategy.browser,
    this.resolveInitialRoute = true,
    super.key,
  });

  final Unrouter<R> router;
  final UnknownRouteBuilder? unknown;
  final RouteErrorBuilder? onError;
  final RouteLoadingBuilder? loading;
  final UnknownRouteBuilder? blocked;

  /// Optional history override for this mounted router instance.
  final History? history;

  /// Optional base path for browser-backed history creation.
  final String? base;

  /// History strategy used when creating browser-backed history.
  final HistoryStrategy strategy;

  /// Whether runtime resolves the initial location when mounted.
  final bool resolveInitialRoute;

  @override
  State<UnrouterRouter<R>> createState() => _UnrouterRouterState<R>();
}

class _UnrouterRouterState<R extends RouteData> extends State<UnrouterRouter<R>>
    with PreloadStateMixin<UnrouterRouter<R>> {
  _CoreUnrouterController<R>? _controller;
  _CoreUnrouterController<RouteData>? _scopeController;
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
        oldComponent.base != component.base ||
        oldComponent.strategy != component.strategy ||
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
    final scopeController = _scopeController;
    if (controller == null || scopeController == null) {
      return const Component.empty();
    }

    return UnrouterScope(
      controller: scopeController,
      child: _buildFromResolution(context),
    );
  }

  void _ensureController() {
    if (_controller != null) {
      return;
    }

    final historyPlan = _resolveHistory();
    _controller = _CoreUnrouterController<R>(
      router: component.router,
      history: historyPlan.history,
      resolveInitialRoute: component.resolveInitialRoute,
      disposeHistory: historyPlan.disposeHistory,
    );
    _scopeController = _controller!.cast<RouteData>();
    _resolution = _controller!.resolution;
  }

  _HistoryPlan _resolveHistory() {
    final explicit = component.history;
    if (explicit != null) {
      return _HistoryPlan(history: explicit, disposeHistory: false);
    }

    if (context.binding.isClient) {
      return _HistoryPlan(
        history: createHistory(
          base: component.base,
          strategy: component.strategy,
        ),
        disposeHistory: true,
      );
    }

    final uri = _normalizeRequestUri(context.url);
    return _HistoryPlan(
      history: MemoryHistory(
        initialEntries: <HistoryLocation>[HistoryLocation(uri)],
        initialIndex: 0,
        base: component.base,
      ),
      disposeHistory: true,
    );
  }

  void _disposeController() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _controller?.dispose();
    _controller = null;
    _scopeController = null;
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
      final record = resolution.record;
      if (record is! RouteRecord<R>) {
        return _buildError(
          context,
          StateError(
            'Matched record does not implement jaspr RouteRecord. '
            'Build routes with jaspr_unrouter route()/routeWithLoader().',
          ),
          StackTrace.current,
        );
      }

      try {
        return record.build(context, resolution.route!, resolution.loaderData);
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
