import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart' hide RouteData;
import 'package:flutter_unrouter/flutter_unrouter.dart';
import 'package:unstory/unstory.dart';
import 'package:zenrouter/zenrouter.dart';

typedef _RouterHarnessFactory = RouterBenchHarness Function();

final List<_RouterHarnessFactory> _harnessFactories = <_RouterHarnessFactory>[
  UnrouterBenchHarness.new,
  GoRouterBenchHarness.new,
  ZenRouterBenchHarness.new,
];

List<RouterBenchHarness> createHarnesses({int rotateBy = 0}) {
  if (_harnessFactories.isEmpty) {
    return const <RouterBenchHarness>[];
  }
  final count = _harnessFactories.length;
  final normalizedOffset = ((rotateBy % count) + count) % count;
  final orderedFactories = <_RouterHarnessFactory>[
    ..._harnessFactories.skip(normalizedOffset),
    ..._harnessFactories.take(normalizedOffset),
  ];
  return orderedFactories.map((factory) => factory()).toList(growable: false);
}

Future<BehaviorSnapshot> runSharedNavigationScript(
  RouterBenchHarness harness,
  WidgetTester tester,
) async {
  final checkpoints = <String>[harness.location];
  final pushResults = <Object?>[];

  await harness.go('/users/1');
  await harness.pump(tester);
  checkpoints.add(harness.location);

  final pushOne = harness.push('/settings');
  await harness.pump(tester);

  await harness.pop(7);
  await harness.pump(tester);
  pushResults.add(await pushOne);
  checkpoints.add(harness.location);

  await harness.go('/users/2');
  await harness.pump(tester);
  checkpoints.add(harness.location);

  final pushTwo = harness.push('/settings');
  await harness.pump(tester);

  await harness.pop();
  await harness.pump(tester);
  pushResults.add(await pushTwo);
  checkpoints.add(harness.location);

  return BehaviorSnapshot(
    routerName: harness.routerName,
    checkpoints: checkpoints,
    pushResults: pushResults,
  );
}

Future<String> runRedirectScript(
  RouterBenchHarness harness,
  WidgetTester tester,
) async {
  await harness.go('/legacy/9');
  await harness.pump(tester);
  return harness.location;
}

Future<String> runGuardRedirectScript(
  RouterBenchHarness harness,
  WidgetTester tester,
) async {
  await harness.go('/protected');
  await harness.pump(tester);
  return harness.location;
}

Future<BehaviorSnapshot> runNestedNavigationScript(
  RouterBenchHarness harness,
  WidgetTester tester,
) async {
  final checkpoints = <String>[harness.location];
  final pushResults = <Object?>[];

  await harness.go('/workspace/inbox');
  await harness.pump(tester);
  checkpoints.add(harness.location);

  final pushOne = harness.push('/workspace/inbox/details/3');
  await harness.pump(tester);

  await harness.pop(11);
  await harness.pump(tester);
  pushResults.add(await pushOne);
  checkpoints.add(harness.location);

  await harness.go('/workspace/archive');
  await harness.pump(tester);
  checkpoints.add(harness.location);

  final pushTwo = harness.push('/workspace/archive/details/5');
  await harness.pump(tester);

  await harness.pop();
  await harness.pump(tester);
  pushResults.add(await pushTwo);
  checkpoints.add(harness.location);

  return BehaviorSnapshot(
    routerName: harness.routerName,
    checkpoints: checkpoints,
    pushResults: pushResults,
  );
}

Future<BehaviorSnapshot> runBackForwardNavigationScript(
  RouterBenchHarness harness,
  WidgetTester tester,
) async {
  final checkpoints = <String>[harness.location];
  final pushResults = <Object?>[];

  await harness.go('/users/1');
  await harness.pump(tester);
  checkpoints.add(harness.location);

  final pushOne = harness.push('/users/2');
  await harness.pump(tester);
  await harness.pop('back');
  await harness.pump(tester);
  pushResults.add(await pushOne);
  checkpoints.add(harness.location);

  final pushTwo = harness.push('/users/2');
  await harness.pump(tester);
  await harness.pop('forward');
  await harness.pump(tester);
  pushResults.add(await pushTwo);
  checkpoints.add(harness.location);

  return BehaviorSnapshot(
    routerName: harness.routerName,
    checkpoints: checkpoints,
    pushResults: pushResults,
  );
}

Future<LongLivedSnapshot> runLongLivedRestorationScript(
  RouterBenchHarness harness,
  WidgetTester tester, {
  required int rounds,
}) async {
  var resultChecksum = 0;
  var userChecksum = 0;

  for (var i = 1; i <= rounds; i++) {
    final userId = ((i * 3) % 9) + 1;
    await harness.go('/users/$userId');
    await harness.pump(tester);

    final pending = harness.push('/settings');
    await harness.pump(tester);

    await harness.pop(i);
    await harness.pump(tester);
    final result = await pending;

    if (result is! int) {
      throw StateError(
        'Expected int push result at round $i for ${harness.routerName}, got $result',
      );
    }
    resultChecksum += result;

    final parsedUserId = _readTrailingUserId(harness.location);
    if (parsedUserId == null) {
      throw StateError(
        'Expected /users/:id location after pop at round $i for ${harness.routerName}, got ${harness.location}',
      );
    }
    userChecksum += parsedUserId;

    if (i % 8 == 0) {
      await harness.go('/workspace/archive');
      await harness.pump(tester);
      await harness.go('/workspace/inbox');
      await harness.pump(tester);
    }
  }

  await harness.go('/');
  await harness.pump(tester);

  return LongLivedSnapshot(
    routerName: harness.routerName,
    rounds: rounds,
    finalLocation: harness.location,
    resultChecksum: resultChecksum,
    userChecksum: userChecksum,
  );
}

int? _readTrailingUserId(String location) {
  final segments = Uri.parse(location).pathSegments;
  if (segments.length != 2 || segments.first != 'users') {
    return null;
  }
  return int.tryParse(segments[1]);
}

Future<PerformanceMetric> runPerformanceScript(
  RouterBenchHarness harness,
  WidgetTester tester, {
  required int rounds,
}) async {
  var checksum = 0;
  final stopwatch = Stopwatch()..start();

  for (var i = 0; i < rounds; i++) {
    final userId = (i % 9) + 1;
    await harness.go('/users/$userId');
    await harness.pump(tester);
    checksum += _readTrailingUserId(harness.location) ?? 0;

    final pending = harness.push('/settings');
    await harness.pump(tester);

    await harness.pop(i);
    await harness.pump(tester);
    final result = await pending;
    if (result is int) {
      checksum += result;
    }
    checksum += harness.location == '/users/$userId' ? 1 : 0;

    await harness.go('/');
    await harness.pump(tester);
    checksum += harness.location == '/' ? 1 : 0;
  }

  stopwatch.stop();
  return PerformanceMetric(
    routerName: harness.routerName,
    rounds: rounds,
    elapsed: stopwatch.elapsed,
    checksum: checksum,
  );
}

Future<PerformanceSeries> runPerformanceSeries(
  RouterBenchHarness harness,
  WidgetTester tester, {
  required int rounds,
  required int samples,
}) async {
  if (samples <= 0) {
    throw ArgumentError.value(samples, 'samples', 'must be greater than zero');
  }

  final metrics = <PerformanceMetric>[];
  for (var i = 0; i < samples; i++) {
    metrics.add(await runPerformanceScript(harness, tester, rounds: rounds));
  }
  return PerformanceSeries.fromMetrics(metrics);
}

class BehaviorSnapshot {
  const BehaviorSnapshot({
    required this.routerName,
    required this.checkpoints,
    required this.pushResults,
  });

  final String routerName;
  final List<String> checkpoints;
  final List<Object?> pushResults;
}

class PerformanceMetric {
  const PerformanceMetric({
    required this.routerName,
    required this.rounds,
    required this.elapsed,
    required this.checksum,
  });

  final String routerName;
  final int rounds;
  final Duration elapsed;
  final int checksum;

  double get averageMicrosPerRound {
    if (rounds == 0) {
      return 0;
    }
    return elapsed.inMicroseconds / rounds;
  }
}

class PerformanceSeries {
  const PerformanceSeries._({
    required this.routerName,
    required this.rounds,
    required this.metrics,
    required this.sampleAverageMicrosPerRound,
    required this.totalElapsedMilliseconds,
    required this.checksumParity,
    required this.checksum,
    required this.minAverageMicrosPerRound,
    required this.maxAverageMicrosPerRound,
    required this.meanAverageMicrosPerRound,
    required this.p50AverageMicrosPerRound,
    required this.p95AverageMicrosPerRound,
  });

  factory PerformanceSeries.fromMetrics(List<PerformanceMetric> metrics) {
    if (metrics.isEmpty) {
      throw ArgumentError.value(metrics, 'metrics', 'must not be empty');
    }

    final first = metrics.first;
    for (final metric in metrics.skip(1)) {
      if (metric.routerName != first.routerName) {
        throw ArgumentError(
          'all metrics in a series must share the same routerName',
        );
      }
      if (metric.rounds != first.rounds) {
        throw ArgumentError(
          'all metrics in a series must share the same rounds',
        );
      }
    }

    final averages = metrics
        .map((metric) => metric.averageMicrosPerRound)
        .toList(growable: false);
    final sortedAverages = List<double>.from(averages)..sort();
    final totalElapsed = metrics.fold<int>(
      0,
      (sum, metric) => sum + metric.elapsed.inMilliseconds,
    );

    final firstChecksum = metrics.first.checksum;
    final checksumParity = metrics.every(
      (metric) => metric.checksum == firstChecksum,
    );
    final mean =
        sortedAverages.fold<double>(0, (sum, value) => sum + value) /
        sortedAverages.length;

    return PerformanceSeries._(
      routerName: first.routerName,
      rounds: first.rounds,
      metrics: List<PerformanceMetric>.unmodifiable(metrics),
      sampleAverageMicrosPerRound: List<double>.unmodifiable(averages),
      totalElapsedMilliseconds: totalElapsed,
      checksumParity: checksumParity,
      checksum: checksumParity ? firstChecksum : null,
      minAverageMicrosPerRound: sortedAverages.first,
      maxAverageMicrosPerRound: sortedAverages.last,
      meanAverageMicrosPerRound: mean,
      p50AverageMicrosPerRound: _percentile(sortedAverages, 0.50),
      p95AverageMicrosPerRound: _percentile(sortedAverages, 0.95),
    );
  }

  final String routerName;
  final int rounds;
  final List<PerformanceMetric> metrics;
  final List<double> sampleAverageMicrosPerRound;
  final int totalElapsedMilliseconds;
  final bool checksumParity;
  final int? checksum;
  final double minAverageMicrosPerRound;
  final double maxAverageMicrosPerRound;
  final double meanAverageMicrosPerRound;
  final double p50AverageMicrosPerRound;
  final double p95AverageMicrosPerRound;

  int get sampleCount => metrics.length;
}

double _percentile(List<double> sortedValues, double fraction) {
  if (sortedValues.isEmpty) {
    return 0;
  }
  if (sortedValues.length == 1) {
    return sortedValues.first;
  }

  final rank = fraction * (sortedValues.length - 1);
  final lowerIndex = rank.floor();
  final upperIndex = rank.ceil();
  if (lowerIndex == upperIndex) {
    return sortedValues[lowerIndex];
  }

  final lowerValue = sortedValues[lowerIndex];
  final upperValue = sortedValues[upperIndex];
  final weight = rank - lowerIndex;
  return lowerValue + (upperValue - lowerValue) * weight;
}

class LongLivedSnapshot {
  const LongLivedSnapshot({
    required this.routerName,
    required this.rounds,
    required this.finalLocation,
    required this.resultChecksum,
    required this.userChecksum,
  });

  final String routerName;
  final int rounds;
  final String finalLocation;
  final int resultChecksum;
  final int userChecksum;
}

abstract class RouterBenchHarness {
  String get routerName;

  String get location;

  Future<void> attach(WidgetTester tester);

  Future<void> detach(WidgetTester tester);

  Future<void> go(String location);

  Future<Object?> push(String location);

  Future<void> pop([Object? result]);

  Future<void> pump(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
  }
}

sealed class _UnrouterBenchRoute implements RouteData {
  const _UnrouterBenchRoute();
}

final class _UnrouterHomeRoute extends _UnrouterBenchRoute {
  const _UnrouterHomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class _UnrouterUserRoute extends _UnrouterBenchRoute {
  const _UnrouterUserRoute(this.userId);

  final String userId;

  @override
  Uri toUri() => Uri(path: '/users/$userId');
}

final class _UnrouterLegacyRoute extends _UnrouterBenchRoute {
  const _UnrouterLegacyRoute(this.userId);

  final String userId;

  @override
  Uri toUri() => Uri(path: '/legacy/$userId');
}

final class _UnrouterWorkspaceRoute extends _UnrouterBenchRoute {
  const _UnrouterWorkspaceRoute(this.tab);

  final String tab;

  @override
  Uri toUri() => Uri(path: '/workspace/$tab');
}

final class _UnrouterWorkspaceDetailRoute extends _UnrouterBenchRoute {
  const _UnrouterWorkspaceDetailRoute(this.tab, this.detailId);

  final String tab;
  final String detailId;

  @override
  Uri toUri() => Uri(path: '/workspace/$tab/details/$detailId');
}

final class _UnrouterSettingsRoute extends _UnrouterBenchRoute {
  const _UnrouterSettingsRoute();

  @override
  Uri toUri() => Uri(path: '/settings');
}

final class _UnrouterLoginRoute extends _UnrouterBenchRoute {
  const _UnrouterLoginRoute();

  @override
  Uri toUri() => Uri(path: '/login');
}

final class _UnrouterProtectedRoute extends _UnrouterBenchRoute {
  const _UnrouterProtectedRoute();

  @override
  Uri toUri() => Uri(path: '/protected');
}

class UnrouterBenchHarness extends RouterBenchHarness {
  final Completer<UnrouterController<_UnrouterBenchRoute>>
  _controllerCompleter = Completer<UnrouterController<_UnrouterBenchRoute>>();

  late final Unrouter<_UnrouterBenchRoute> _router =
      Unrouter<_UnrouterBenchRoute>(
        history: MemoryHistory(),
        routes: [
          route<_UnrouterHomeRoute>(
            path: '/',
            parse: (_) => const _UnrouterHomeRoute(),
            builder: (context, route) {
              _bindController(context);
              return const SizedBox.shrink();
            },
          ),
          route<_UnrouterUserRoute>(
            path: '/users/:id',
            parse: (state) => _UnrouterUserRoute(state.path('id')),
            builder: (context, route) {
              _bindController(context);
              return const SizedBox.shrink();
            },
          ),
          route<_UnrouterWorkspaceRoute>(
            path: '/workspace/:tab',
            parse: (state) => _UnrouterWorkspaceRoute(state.path('tab')),
            builder: (context, route) {
              _bindController(context);
              return const SizedBox.shrink();
            },
          ),
          route<_UnrouterWorkspaceDetailRoute>(
            path: '/workspace/:tab/details/:id',
            parse: (state) => _UnrouterWorkspaceDetailRoute(
              state.path('tab'),
              state.path('id'),
            ),
            builder: (context, route) {
              _bindController(context);
              return const SizedBox.shrink();
            },
          ),
          route<_UnrouterLegacyRoute>(
            path: '/legacy/:id',
            parse: (state) => _UnrouterLegacyRoute(state.path('id')),
            redirect: (context) => Uri(path: '/users/${context.route.userId}'),
            builder: (context, route) {
              _bindController(context);
              return const SizedBox.shrink();
            },
          ),
          route<_UnrouterSettingsRoute>(
            path: '/settings',
            parse: (_) => const _UnrouterSettingsRoute(),
            builder: (context, route) {
              _bindController(context);
              return const SizedBox.shrink();
            },
          ),
          route<_UnrouterLoginRoute>(
            path: '/login',
            parse: (_) => const _UnrouterLoginRoute(),
            builder: (context, route) {
              _bindController(context);
              return const SizedBox.shrink();
            },
          ),
          route<_UnrouterProtectedRoute>(
            path: '/protected',
            parse: (_) => const _UnrouterProtectedRoute(),
            guards: [(_) => RouteGuardResult.redirect(Uri(path: '/login'))],
            builder: (context, route) {
              _bindController(context);
              return const SizedBox.shrink();
            },
          ),
        ],
      );

  late UnrouterController<_UnrouterBenchRoute> _controller;

  @override
  String get routerName => 'unrouter';

  @override
  String get location => _controller.uri.path;

  @override
  Future<void> attach(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router));
    await pump(tester);
    _controller = await _controllerCompleter.future.timeout(
      const Duration(seconds: 2),
    );
  }

  @override
  Future<void> detach(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  @override
  Future<void> go(String location) async {
    _controller.goUri(Uri.parse(location));
  }

  @override
  Future<Object?> push(String location) {
    return _controller.pushUri<Object?>(Uri.parse(location));
  }

  @override
  Future<void> pop([Object? result]) async {
    _controller.pop(result);
  }

  void _bindController(BuildContext context) {
    if (_controllerCompleter.isCompleted) {
      return;
    }
    _controllerCompleter.complete(context.unrouterAs<_UnrouterBenchRoute>());
  }
}

class GoRouterBenchHarness extends RouterBenchHarness {
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(
        path: '/users/:id',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/workspace/:tab',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/workspace/:tab/details/:id',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/legacy/:id',
        redirect: (_, state) => '/users/${state.pathParameters['id']}',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/protected',
        redirect: (context, state) => '/login',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );

  @override
  String get routerName => 'go_router';

  @override
  String get location => _router.routeInformationProvider.value.uri.path;

  @override
  Future<void> attach(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router));
    await pump(tester);
  }

  @override
  Future<void> detach(WidgetTester tester) async {
    _router.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  @override
  Future<void> go(String location) async {
    _router.go(location);
  }

  @override
  Future<Object?> push(String location) {
    return _router.push<Object?>(location);
  }

  @override
  Future<void> pop([Object? result]) async {
    _router.pop(result);
  }
}

abstract class _ZenBenchRoute extends RouteTarget with RouteUnique {
  _ZenBenchRoute();

  @override
  Widget build(
    covariant _ZenBenchCoordinator coordinator,
    BuildContext context,
  ) {
    return const SizedBox.shrink();
  }
}

final class _ZenHomeRoute extends _ZenBenchRoute {
  _ZenHomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class _ZenUserRoute extends _ZenBenchRoute {
  _ZenUserRoute(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];

  @override
  Uri toUri() => Uri(path: '/users/$userId');
}

final class _ZenSettingsRoute extends _ZenBenchRoute {
  _ZenSettingsRoute();

  @override
  Uri toUri() => Uri(path: '/settings');
}

final class _ZenWorkspaceRoute extends _ZenBenchRoute {
  _ZenWorkspaceRoute(this.tab);

  final String tab;

  @override
  List<Object?> get props => [tab];

  @override
  Uri toUri() => Uri(path: '/workspace/$tab');
}

final class _ZenWorkspaceDetailRoute extends _ZenBenchRoute {
  _ZenWorkspaceDetailRoute(this.tab, this.detailId);

  final String tab;
  final String detailId;

  @override
  List<Object?> get props => [tab, detailId];

  @override
  Uri toUri() => Uri(path: '/workspace/$tab/details/$detailId');
}

final class _ZenLoginRoute extends _ZenBenchRoute {
  _ZenLoginRoute();

  @override
  Uri toUri() => Uri(path: '/login');
}

class _ZenBenchCoordinator extends Coordinator<_ZenBenchRoute> {
  @override
  FutureOr<_ZenBenchRoute> parseRouteFromUri(Uri uri) {
    return _routeForUri(uri);
  }

  _ZenBenchRoute routeForLocation(String location) {
    return _routeForUri(Uri.parse(location));
  }

  _ZenBenchRoute _routeForUri(Uri uri) {
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    final parts = segments.toList(growable: false);
    if (parts.isEmpty) {
      return _ZenHomeRoute();
    }

    if (parts.length == 2 && parts[0] == 'users') {
      return _ZenUserRoute(parts[1]);
    }
    if (parts.length == 2 && parts[0] == 'workspace') {
      return _ZenWorkspaceRoute(parts[1]);
    }
    if (parts.length == 4 && parts[0] == 'workspace' && parts[2] == 'details') {
      return _ZenWorkspaceDetailRoute(parts[1], parts[3]);
    }
    if (parts.length == 2 && parts[0] == 'legacy') {
      return _ZenUserRoute(parts[1]);
    }
    if (parts.length == 1 && parts[0] == 'settings') {
      return _ZenSettingsRoute();
    }
    if (parts.length == 1 && parts[0] == 'login') {
      return _ZenLoginRoute();
    }
    if (parts.length == 1 && parts[0] == 'protected') {
      return _ZenLoginRoute();
    }

    return _ZenHomeRoute();
  }
}

class ZenRouterBenchHarness extends RouterBenchHarness {
  late final _ZenBenchCoordinator _coordinator = _ZenBenchCoordinator();

  @override
  String get routerName => 'zenrouter';

  @override
  String get location {
    final active = _coordinator.activePath.activeRoute;
    if (active != null) {
      return active.toUri().path;
    }
    return _coordinator.routeInformationProvider.value.uri.path;
  }

  @override
  Future<void> attach(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _coordinator));
    await pump(tester);
  }

  @override
  Future<void> detach(WidgetTester tester) async {
    _coordinator.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  @override
  Future<void> go(String location) {
    return _coordinator.replace(_coordinator.routeForLocation(location));
  }

  @override
  Future<Object?> push(String location) {
    return _coordinator.push<Object>(_coordinator.routeForLocation(location));
  }

  @override
  Future<void> pop([Object? result]) {
    return _coordinator.pop(result);
  }
}
