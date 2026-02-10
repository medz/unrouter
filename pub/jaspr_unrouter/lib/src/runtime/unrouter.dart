import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart' hide RouteRecord, Unrouter;
import 'package:unrouter/unrouter.dart'
    as core
    show Unrouter, UnrouterController, StateSnapshot, RouteRecord;
import 'package:unstory/unstory.dart';

import '../core/route_records.dart';
import 'navigation.dart';

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

/// Jaspr adapter router component.
///
/// Mirrors Flutter adapter ergonomics: configure routes and runtime options in
/// one place, while `unrouter` core continues to own route semantics.
class Unrouter<R extends RouteData> extends core.Unrouter<R>
    implements StatefulComponent {
  Unrouter({
    required List<RouteRecord<R>> routes,
    this.unknown,
    this.onError,
    this.loading,
    this.blocked,
    int maxRedirectHops = 8,
    RedirectLoopPolicy redirectLoopPolicy = RedirectLoopPolicy.error,
    RedirectDiagnosticsCallback? onRedirectDiagnostics,
    this.history,
    this.base,
    this.strategy = HistoryStrategy.browser,
    this.resolveInitialRoute = true,
    this.publishPendingState = false,
    Key? key,
  }) : assert(routes.isNotEmpty, 'Unrouter routes must not be empty.'),
       assert(
         maxRedirectHops > 0,
         'Unrouter maxRedirectHops must be greater than zero.',
       ),
       _key = key,
       super(
         routes: routes.cast<core.RouteRecord<R>>(),
         maxRedirectHops: maxRedirectHops,
         redirectLoopPolicy: redirectLoopPolicy,
         onRedirectDiagnostics: onRedirectDiagnostics,
       );

  final Key? _key;
  @override
  Key? get key => _key;

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

  /// Whether pending route resolution snapshots are published to listeners.
  final bool publishPendingState;

  @override
  Element createElement() => StatefulElement(this);

  @override
  State<Unrouter<R>> createState() => _UnrouterState<R>();
}

class _UnrouterState<R extends RouteData> extends State<Unrouter<R>>
    with PreloadStateMixin<Unrouter<R>> {
  core.UnrouterController<R>? _controller;
  core.UnrouterController<RouteData>? _scopeController;
  StreamSubscription<core.StateSnapshot<R>>? _stateSubscription;
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
  void didUpdateComponent(covariant Unrouter<R> oldComponent) {
    super.didUpdateComponent(oldComponent);
    final shouldRecreateController =
        oldComponent.routes != component.routes ||
        oldComponent.maxRedirectHops != component.maxRedirectHops ||
        oldComponent.redirectLoopPolicy != component.redirectLoopPolicy ||
        oldComponent.onRedirectDiagnostics != component.onRedirectDiagnostics ||
        oldComponent.history != component.history ||
        oldComponent.base != component.base ||
        oldComponent.strategy != component.strategy ||
        oldComponent.resolveInitialRoute != component.resolveInitialRoute ||
        oldComponent.publishPendingState != component.publishPendingState;
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
      child: Builder(
        builder: (innerContext) => _buildFromResolution(innerContext),
      ),
    );
  }

  void _ensureController() {
    if (_controller != null) {
      return;
    }

    final historyPlan = _resolveHistory();
    _controller = core.UnrouterController<R>(
      router: component,
      history: historyPlan.history,
      resolveInitialRoute: component.resolveInitialRoute,
      publishPendingState: component.publishPendingState,
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

      final unknownBuilder = component.unknown;
      if (unknownBuilder != null) {
        return unknownBuilder(context, resolution.uri);
      }

      return Component.text('No route matches ${resolution.uri.path}');
    }

    if (resolution.isMatched) {
      final record = _requireRouteRecord(resolution);
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

  RouteRecord<R>? _asAdapterRouteRecord(core.RouteRecord<R>? record) {
    if (record case RouteRecord<R> adapterRecord) {
      return adapterRecord;
    }
    return null;
  }

  RouteRecord<R> _requireRouteRecord(RouteResolution<R> resolution) {
    final record = _asAdapterRouteRecord(resolution.record);
    if (record != null) {
      return record;
    }

    throw StateError(
      'Matched record does not implement jaspr RouteRecord. '
      'Build routes with jaspr_unrouter route()/dataRoute().',
    );
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

    Error.throwWithStackTrace(error, stackTrace);
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
