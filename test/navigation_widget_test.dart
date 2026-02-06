import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/machine.dart';
import 'package:unrouter/unrouter.dart';
import 'package:unstory/unstory.dart';

void main() {
  testWidgets('pushes and pops with context.unrouter', (tester) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('go-user'),
                onPressed: () {
                  context.unrouter.push(const UserRoute(id: 7));
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (_, route) => Text('user:${route.id}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);

    await tester.tap(find.byKey(const Key('go-user')));
    await tester.pumpAndSettle();

    expect(find.text('user:7'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('supports typed controller via context.unrouterAs', (
    tester,
  ) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            final current = context.unrouterAs<AppRoute>().route;
            return Center(
              child: TextButton(
                key: const Key('go-typed-user'),
                onPressed: () {
                  context.unrouterAs<AppRoute>().push(const UserRoute(id: 99));
                },
                child: Text('typed:${current.runtimeType}'),
              ),
            );
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (context, route) {
            final typedRoute = context.unrouterAs<AppRoute>().route;
            return Text('user:${route.id}:${typedRoute.runtimeType}');
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('typed:HomeRoute'), findsOneWidget);

    await tester.tap(find.byKey(const Key('go-typed-user')));
    await tester.pumpAndSettle();

    expect(find.text('user:99:UserRoute'), findsOneWidget);
  });

  testWidgets('supports public machine dispatch API', (tester) async {
    UnrouterMachine<AppRoute>? machine;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            machine ??= context.unrouterMachineAs<AppRoute>();
            return const Text('home');
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (_, route) => Text('user:${route.id}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(machine, isNotNull);
    expect(machine!.state.uri.toString(), '/');

    final pushResult = machine!.dispatchTyped<Future<Object?>>(
      UnrouterMachineCommand.pushUri(Uri(path: '/users/21')),
    );
    await tester.pumpAndSettle();
    expect(find.text('user:21'), findsOneWidget);

    final wentBack = machine!.dispatchTyped<bool>(
      UnrouterMachineCommand.back(),
    );
    expect(wentBack, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);

    await expectLater(pushResult, completion(isNull));
    expect(
      machine!.timeline.any(
        (entry) => entry.event == UnrouterMachineEvent.pushUri,
      ),
      isTrue,
    );
    expect(
      machine!.timeline.any(
        (entry) => entry.event == UnrouterMachineEvent.back,
      ),
      isTrue,
    );
  });

  testWidgets('supports public machine action API draft layer', (tester) async {
    UnrouterMachine<AppRoute>? machine;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            machine ??= context.unrouterMachineAs<AppRoute>();
            return const Text('home');
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (_, route) => Text('user:${route.id}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(machine, isNotNull);

    machine!.dispatchAction<void>(
      UnrouterMachineAction.navigateToRoute(const UserRoute(id: 21)),
    );
    await tester.pumpAndSettle();
    expect(find.text('user:21'), findsOneWidget);

    machine!.dispatchAction<void>(
      UnrouterMachineAction.replaceRoute(const UserRoute(id: 23)),
    );
    await tester.pumpAndSettle();
    expect(find.text('user:23'), findsOneWidget);

    machine!.dispatchAction<void>(
      UnrouterMachineAction.navigateRoute(
        const UserRoute(id: 24),
        mode: UnrouterMachineNavigateMode.replace,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('user:24'), findsOneWidget);

    final pushResult = machine!.dispatchAction<Future<int?>>(
      UnrouterMachineAction.pushRoute<UserRoute, int>(const UserRoute(id: 22)),
    );
    await tester.pumpAndSettle();
    expect(find.text('user:22'), findsOneWidget);

    final popped = machine!.dispatchAction<bool>(UnrouterMachineAction.pop(9));
    expect(popped, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('user:24'), findsOneWidget);

    await expectLater(pushResult, completion(9));
    expect(
      machine!.timeline.any(
        (entry) => entry.event == UnrouterMachineEvent.goUri,
      ),
      isTrue,
    );
    expect(
      machine!.timeline.any(
        (entry) => entry.event == UnrouterMachineEvent.replaceUri,
      ),
      isTrue,
    );
    expect(
      machine!.timeline.any(
        (entry) => entry.event == UnrouterMachineEvent.pushUri,
      ),
      isTrue,
    );
    expect(
      machine!.timeline.any((entry) => entry.event == UnrouterMachineEvent.pop),
      isTrue,
    );
  });

  testWidgets('classifies machine action envelopes by dispatch outcome', (
    tester,
  ) async {
    UnrouterMachine<AppRoute>? machine;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            machine ??= context.unrouterMachineAs<AppRoute>();
            return const Text('home');
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (_, route) => Text('user:${route.id}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(machine, isNotNull);

    final rejected = machine!.dispatchActionEnvelope<bool>(
      UnrouterMachineAction.back(),
    );
    expect(rejected.state, UnrouterMachineActionEnvelopeState.rejected);
    expect(rejected.isAccepted, isFalse);
    expect(rejected.value, isFalse);
    expect(rejected.rejectCode, UnrouterMachineActionRejectCode.noBackHistory);
    expect(rejected.rejectReason, isNotEmpty);
    expect(rejected.failure, isNotNull);
    expect(
      rejected.failure?.category,
      UnrouterMachineActionFailureCategory.history,
    );
    expect(rejected.failure?.retryable, isTrue);
    final rejectedJson = rejected.toJson();
    final rejectedFailure = rejectedJson['failure'] as Map<String, Object?>?;
    expect(
      rejectedFailure?['code'],
      UnrouterMachineActionRejectCode.noBackHistory.name,
    );
    expect(
      rejectedFailure?['category'],
      UnrouterMachineActionFailureCategory.history.name,
    );
    expect(
      UnrouterMachineActionEnvelope.isSchemaVersionCompatible(
        rejectedJson['schemaVersion']! as int,
      ),
      isTrue,
    );
    expect(
      UnrouterMachineActionEnvelope.isEventVersionCompatible(
        rejectedJson['eventVersion']! as int,
      ),
      isTrue,
    );
    expect(
      rejectedJson['schemaVersion'],
      UnrouterMachineActionEnvelope.schemaVersion,
    );
    expect(
      rejectedJson['eventVersion'],
      UnrouterMachineActionEnvelope.eventVersion,
    );
    expect(rejectedJson['producer'], UnrouterMachineActionEnvelope.producer);

    final accepted = machine!.dispatchActionEnvelope<void>(
      UnrouterMachineAction.navigateToRoute(const UserRoute(id: 31)),
    );
    expect(accepted.state, UnrouterMachineActionEnvelopeState.accepted);
    await tester.pumpAndSettle();
    expect(find.text('user:31'), findsOneWidget);

    final deferred = machine!.dispatchActionEnvelope<Future<int?>>(
      UnrouterMachineAction.pushRoute<UserRoute, int>(const UserRoute(id: 32)),
    );
    expect(deferred.state, UnrouterMachineActionEnvelopeState.deferred);
    await tester.pumpAndSettle();
    expect(find.text('user:32'), findsOneWidget);

    final completed = machine!.dispatchActionEnvelope<bool>(
      UnrouterMachineAction.pop(11),
    );
    expect(completed.state, UnrouterMachineActionEnvelopeState.completed);
    expect(completed.value, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('user:31'), findsOneWidget);

    await expectLater(deferred.value, completion(11));
    final envelopeTransitions = machine!.timeline
        .where((entry) => entry.event == UnrouterMachineEvent.actionEnvelope)
        .toList(growable: false);
    expect(envelopeTransitions, hasLength(5));
    expect(
      envelopeTransitions
          .map((entry) => entry.payload['actionState'])
          .toList(growable: false),
      containsAll(<String>['rejected', 'accepted', 'deferred', 'completed']),
    );
    expect(
      envelopeTransitions
          .map((entry) => entry.payload['actionEnvelope'])
          .every((value) => value is Map<String, Object?>),
      isTrue,
    );
    expect(
      envelopeTransitions
          .map((entry) => entry.payload['actionEnvelopeSchemaVersion'])
          .toSet(),
      {UnrouterMachineActionEnvelope.schemaVersion},
    );
    expect(
      envelopeTransitions
          .map((entry) => entry.payload['actionEnvelopeEventVersion'])
          .toSet(),
      {UnrouterMachineActionEnvelope.eventVersion},
    );
    expect(
      envelopeTransitions
          .map((entry) => entry.payload['actionEnvelopeProducer'])
          .toSet(),
      {UnrouterMachineActionEnvelope.producer},
    );
    expect(
      envelopeTransitions
          .map((entry) => entry.payload['actionEnvelopePhase'])
          .toList(growable: false),
      containsAll(<String>['dispatch', 'settled']),
    );
    expect(
      envelopeTransitions.any(
        (entry) => entry.payload['actionFailure'] is Map<String, Object?>,
      ),
      isTrue,
    );

    final typedTimeline = machine!.typedTimeline;
    expect(typedTimeline, hasLength(machine!.timeline.length));
    expect(typedTimeline, isNotEmpty);
    expect(
      typedTimeline.any(
        (entry) =>
            entry.payload.kind ==
            UnrouterMachineTypedPayloadKind.actionEnvelope,
      ),
      isTrue,
    );
    expect(
      typedTimeline.any(
        (entry) =>
            entry.payload.kind == UnrouterMachineTypedPayloadKind.navigation,
      ),
      isTrue,
    );
    expect(
      typedTimeline.any(
        (entry) => entry.payload.kind == UnrouterMachineTypedPayloadKind.route,
      ),
      isTrue,
    );
    expect(
      typedTimeline.any(
        (entry) =>
            entry.event ==
            UnrouterMachineEvent.controllerRouteMachineConfigured,
      ),
      isTrue,
    );
    expect(
      typedTimeline.any(
        (entry) =>
            entry.event == UnrouterMachineEvent.controllerShellResolversChanged,
      ),
      isTrue,
    );

    final typedControllerConfigured = typedTimeline.firstWhere(
      (entry) =>
          entry.event == UnrouterMachineEvent.controllerRouteMachineConfigured,
    );
    final typedControllerConfiguredPayload =
        typedControllerConfigured.payload
            as UnrouterMachineControllerTypedPayload;
    expect(typedControllerConfiguredPayload.maxRedirectHops, 8);
    expect(
      typedControllerConfiguredPayload.redirectLoopPolicy,
      RedirectLoopPolicy.error,
    );
    expect(
      typedControllerConfiguredPayload.redirectDiagnosticsEnabled,
      isFalse,
    );
    final typedRejected = envelopeTransitions
        .firstWhere((entry) => entry.payload['actionState'] == 'rejected')
        .typed;
    expect(
      typedRejected.payload.kind,
      UnrouterMachineTypedPayloadKind.actionEnvelope,
    );
    final typedRejectedPayload =
        typedRejected.payload as UnrouterMachineActionEnvelopeTypedPayload;
    expect(
      typedRejectedPayload.actionState,
      UnrouterMachineActionEnvelopeState.rejected,
    );
    expect(typedRejectedPayload.actionEvent, UnrouterMachineEvent.back);
    expect(
      typedRejectedPayload.failure?.category,
      UnrouterMachineActionFailureCategory.history,
    );
    expect(typedRejectedPayload.isSchemaCompatible, isTrue);
    expect(typedRejectedPayload.isEventCompatible, isTrue);

    final typedRoute = typedTimeline.firstWhere(
      (entry) => entry.payload.kind == UnrouterMachineTypedPayloadKind.route,
    );
    final typedRoutePayload =
        typedRoute.payload as UnrouterMachineRouteTypedPayload;
    expect(typedRoutePayload.generation, isNotNull);
    expect(typedRoutePayload.requestUri.toString(), isNotEmpty);
    expect(typedRoutePayload.toResolution, isNotNull);

    final typedNavigation = typedTimeline.firstWhere(
      (entry) =>
          entry.payload.kind == UnrouterMachineTypedPayloadKind.navigation,
    );
    final typedNavigationPayload =
        typedNavigation.payload as UnrouterMachineNavigationTypedPayload;
    expect(typedNavigationPayload.beforeAction, isNotNull);
    expect(typedNavigationPayload.afterAction, isNotNull);

    final typedController = UnrouterMachineTransitionEntry(
      sequence: 999,
      recordedAt: DateTime(2026, 2, 6, 15, 0, 0),
      source: UnrouterMachineSource.controller,
      event: UnrouterMachineEvent.initialized,
      from: machine!.state,
      to: machine!.state,
      payload: <String, Object?>{'historyIndex': machine!.state.historyIndex},
    ).typed;
    final typedControllerPayload =
        typedController.payload as UnrouterMachineControllerTypedPayload;
    expect(
      typedController.payload.kind,
      UnrouterMachineTypedPayloadKind.controller,
    );
    expect(typedControllerPayload.historyIndex, machine!.state.historyIndex);
    expect(typedControllerPayload.historyAction, machine!.state.historyAction);
  });

  testWidgets('emits typed controller lifecycle transitions for updates', (
    tester,
  ) async {
    UnrouterController<AppRoute>? controller;
    UnrouterMachine<AppRoute>? machine;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            controller ??= context.unrouterAs<AppRoute>();
            machine ??= context.unrouterMachineAs<AppRoute>();
            return const Text('home');
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    controller!.setHistoryStateComposer((request) => request.state);
    controller!.clearHistoryStateComposer();
    controller!.setShellBranchResolvers(
      resolveTarget: (index, {required initialLocation}) =>
          Uri(path: '/users/${index + 1}'),
      popTarget: () => Uri(path: '/'),
    );
    controller!.clearShellBranchResolvers();

    final typedTimeline = machine!.typedTimeline;
    final historyComposerEntries = typedTimeline
        .where(
          (entry) =>
              entry.event ==
              UnrouterMachineEvent.controllerHistoryStateComposerChanged,
        )
        .toList(growable: false);
    expect(historyComposerEntries, isNotEmpty);
    expect(
      historyComposerEntries
          .map(
            (entry) => (entry.payload as UnrouterMachineControllerTypedPayload)
                .enabled,
          )
          .toList(growable: false),
      containsAll(<bool?>[true, false]),
    );

    final shellResolverEntries = typedTimeline
        .where(
          (entry) =>
              entry.event ==
              UnrouterMachineEvent.controllerShellResolversChanged,
        )
        .toList(growable: false);
    expect(shellResolverEntries, isNotEmpty);
    expect(
      shellResolverEntries
          .map(
            (entry) => (entry.payload as UnrouterMachineControllerTypedPayload)
                .enabled,
          )
          .toList(growable: false),
      containsAll(<bool?>[true, false]),
    );
    expect(
      shellResolverEntries
          .map(
            (entry) => (entry.payload as UnrouterMachineControllerTypedPayload)
                .hadCustomShellResolvers,
          )
          .contains(true),
      isTrue,
    );
  });

  testWidgets('exposes route-state snapshot for matched routes', (
    tester,
  ) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            final state = context.unrouterAs<AppRoute>().state;
            return Center(
              child: TextButton(
                key: const Key('go-state-user'),
                onPressed: () {
                  context.unrouter.push(const UserRoute(id: 5));
                },
                child: Text(
                  'home:${state.resolution.name}:${state.routePath}:${state.historyIndex}',
                ),
              ),
            );
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (context, route) {
            final state = context.unrouterAs<AppRoute>().state;
            return Text(
              'state:${state.resolution.name}:${state.routePath}:${state.lastAction.name}:${state.historyIndex}:${state.route.runtimeType}:${route.id}',
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('home:matched:/:0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('go-state-user')));
    await tester.pumpAndSettle();

    expect(
      find.text('state:matched:/users/:id:push:1:UserRoute:5'),
      findsOneWidget,
    );
  });

  testWidgets('exposes route-state snapshot for error routes', (tester) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: [HistoryLocation(Uri(path: '/users/not-int'))],
      ),
      routes: [
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (_, route) => Text('user:${route.id}'),
        ),
      ],
      onError: (context, error, stackTrace) {
        final state = context.unrouterAs<AppRoute>().state;
        return Text(
          'error-state:${state.resolution.name}:${state.error.runtimeType}:${state.routePath ?? 'none'}',
        );
      },
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('error-state:error:FormatException:none'), findsOneWidget);
  });

  testWidgets('supports route-state subscription and timeline history', (
    tester,
  ) async {
    ValueListenable<UnrouterStateSnapshot<AppRoute>>? listenable;
    UnrouterController<AppRoute>? controller;
    var subscribed = false;
    var notifications = 0;
    late VoidCallback unsubscribe;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            final typed = context.unrouterAs<AppRoute>();
            controller ??= typed;
            listenable ??= typed.stateListenable;
            if (!subscribed) {
              subscribed = true;
              void listener() {
                notifications += 1;
              }

              listenable!.addListener(listener);
              unsubscribe = () => listenable!.removeListener(listener);
            }

            return Center(
              child: TextButton(
                key: const Key('go-state-timeline-user'),
                onPressed: () {
                  context.unrouter.push(const UserRoute(id: 8));
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<UserRoute>(
          path: '/users/:id',
          parse: (state) => UserRoute(id: state.pathInt('id')),
          builder: (_, route) => Text('user:${route.id}'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(listenable, isNotNull);
    expect(listenable!.value.routePath, '/');
    expect(listenable!.value.resolution, UnrouterResolutionState.matched);

    await tester.tap(find.byKey(const Key('go-state-timeline-user')));
    await tester.pumpAndSettle();

    expect(find.text('user:8'), findsOneWidget);
    expect(notifications, greaterThan(0));
    expect(listenable!.value.routePath, '/users/:id');
    expect(listenable!.value.historyIndex, 1);

    final timeline = controller!.stateTimeline;
    expect(timeline.length, greaterThanOrEqualTo(2));
    expect(timeline.last.snapshot.routePath, '/users/:id');
    expect(timeline.last.snapshot.historyIndex, 1);

    controller!.clearStateTimeline();
    final resetTimeline = controller!.stateTimeline;
    expect(resetTimeline, hasLength(1));
    expect(resetTimeline.single.snapshot.routePath, '/users/:id');

    unsubscribe();
  });

  testWidgets('keeps current route when guard blocks navigation', (
    tester,
  ) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('go-admin'),
                onPressed: () {
                  context.unrouter.push(const AdminRoute());
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<AdminRoute>(
          path: '/admin',
          parse: (_) => const AdminRoute(),
          guards: [(_) => RouteGuardResult.block()],
          builder: (_, _) => const Text('admin'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);

    await tester.tap(find.byKey(const Key('go-admin')));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('admin'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets('redirects when guard returns redirect result', (tester) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('go-private'),
                onPressed: () {
                  context.unrouter.push(const PrivateRoute());
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<PrivateRoute>(
          path: '/private',
          parse: (_) => const PrivateRoute(),
          guards: [(_) => RouteGuardResult.redirect(Uri(path: '/login'))],
          builder: (_, _) => const Text('private'),
        ),
        route<LoginRoute>(
          path: '/login',
          parse: (_) => const LoginRoute(),
          builder: (_, _) => const Text('login'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);

    await tester.tap(find.byKey(const Key('go-private')));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
    expect(find.text('private'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/login');
  });

  testWidgets('reports redirect loop error with default loop policy', (
    tester,
  ) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: [HistoryLocation(Uri(path: '/loop-a'))],
      ),
      routes: [
        route<StaticPathRoute>(
          path: '/loop-a',
          parse: (_) => const StaticPathRoute('/loop-a'),
          redirect: (_) => Uri(path: '/loop-b'),
          builder: (_, _) => const SizedBox.shrink(),
        ),
        route<StaticPathRoute>(
          path: '/loop-b',
          parse: (_) => const StaticPathRoute('/loop-b'),
          redirect: (_) => Uri(path: '/loop-a'),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
      onError: (_, error, _) => Text('error:$error'),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('Redirect loop detected'), findsOneWidget);
  });

  testWidgets('reports max redirect hops error when limit is exceeded', (
    tester,
  ) async {
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: [HistoryLocation(Uri(path: '/hop-a'))],
      ),
      maxRedirectHops: 2,
      redirectLoopPolicy: RedirectLoopPolicy.ignore,
      routes: [
        route<StaticPathRoute>(
          path: '/hop-a',
          parse: (_) => const StaticPathRoute('/hop-a'),
          redirect: (_) => Uri(path: '/hop-b'),
          builder: (_, _) => const SizedBox.shrink(),
        ),
        route<StaticPathRoute>(
          path: '/hop-b',
          parse: (_) => const StaticPathRoute('/hop-b'),
          redirect: (_) => Uri(path: '/hop-c'),
          builder: (_, _) => const SizedBox.shrink(),
        ),
        route<StaticPathRoute>(
          path: '/hop-c',
          parse: (_) => const StaticPathRoute('/hop-c'),
          redirect: (_) => Uri(path: '/hop-d'),
          builder: (_, _) => const SizedBox.shrink(),
        ),
        route<StaticPathRoute>(
          path: '/hop-d',
          parse: (_) => const StaticPathRoute('/hop-d'),
          builder: (_, _) => const Text('hop-d'),
        ),
      ],
      onError: (_, error, _) => Text('error:$error'),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.textContaining('Maximum redirect hops'), findsOneWidget);
    expect(find.text('hop-d'), findsNothing);
  });

  testWidgets('emits redirect diagnostics callback with trail details', (
    tester,
  ) async {
    final diagnostics = <RedirectDiagnostics>[];
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(
        initialEntries: [HistoryLocation(Uri(path: '/loop-a'))],
      ),
      routes: [
        route<StaticPathRoute>(
          path: '/loop-a',
          parse: (_) => const StaticPathRoute('/loop-a'),
          redirect: (_) => Uri(path: '/loop-b'),
          builder: (_, _) => const SizedBox.shrink(),
        ),
        route<StaticPathRoute>(
          path: '/loop-b',
          parse: (_) => const StaticPathRoute('/loop-b'),
          redirect: (_) => Uri(path: '/loop-a'),
          builder: (_, _) => const SizedBox.shrink(),
        ),
      ],
      onRedirectDiagnostics: diagnostics.add,
      onError: (_, error, _) => Text('error:$error'),
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(diagnostics, hasLength(1));

    final event = diagnostics.single;
    expect(event.reason, RedirectDiagnosticsReason.loopDetected);
    expect(event.currentUri, Uri(path: '/loop-b'));
    expect(event.redirectUri, Uri(path: '/loop-a'));
    expect(event.hop, 2);
    expect(event.maxHops, 8);
    expect(event.loopPolicy, RedirectLoopPolicy.error);
    expect(event.trail.map((uri) => uri.toString()).toList(), [
      '/loop-a',
      '/loop-b',
      '/loop-a',
    ]);
  });

  testWidgets('applies route transition builder when configured', (
    tester,
  ) async {
    var transitionInvoked = false;
    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('go-transition'),
                onPressed: () {
                  context.unrouter.push(const TransitionDemoRoute());
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<TransitionDemoRoute>(
          path: '/transition',
          parse: (_) => const TransitionDemoRoute(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionBuilder: (context, animation, secondary, child) {
            transitionInvoked = true;
            return FadeTransition(opacity: animation, child: child);
          },
          builder: (_, _) => const Text('transition-page'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-transition')));
    await tester.pumpAndSettle();

    expect(transitionInvoked, isTrue);
    expect(find.text('transition-page'), findsOneWidget);
  });

  testWidgets('uses custom pageBuilder when configured', (tester) async {
    String? pushedPageName;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('go-custom-page'),
                onPressed: () {
                  context.unrouter.push(const CustomPageDemoRoute());
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<CustomPageDemoRoute>(
          path: '/custom-page',
          parse: (_) => const CustomPageDemoRoute(),
          pageBuilder: (state) {
            pushedPageName = state.name;
            return MaterialPage<void>(
              key: state.key,
              name: state.name,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [const Text('custom-page-wrapper'), state.child],
              ),
            );
          },
          builder: (_, _) => const Text('custom-page-body'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-custom-page')));
    await tester.pumpAndSettle();

    expect(find.text('custom-page-wrapper'), findsOneWidget);
    expect(find.text('custom-page-body'), findsOneWidget);
    expect(pushedPageName, '/custom-page');
  });

  testWidgets('returns typed push result when popping with value', (
    tester,
  ) async {
    late Future<int?> pushResult;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('go-result'),
                onPressed: () {
                  pushResult = context.unrouter.push<int>(const ResultRoute());
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<ResultRoute>(
          path: '/result',
          parse: (_) => const ResultRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('pop-with-result'),
                onPressed: () {
                  context.unrouter.pop(42);
                },
                child: const Text('done'),
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-result')));
    await tester.pumpAndSettle();

    expect(find.text('done'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pop-with-result')));
    await tester.pumpAndSettle();

    await expectLater(pushResult, completion(42));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('returns null push result when route is closed by back', (
    tester,
  ) async {
    late Future<int?> pushResult;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('go-result-back'),
                onPressed: () {
                  pushResult = context.unrouter.push<int>(const ResultRoute());
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<ResultRoute>(
          path: '/result',
          parse: (_) => const ResultRoute(),
          builder: (_, _) => const Text('result'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-result-back')));
    await tester.pumpAndSettle();

    expect(find.text('result'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await expectLater(pushResult, completion(isNull));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('replace can complete pending push result immediately', (
    tester,
  ) async {
    late Future<int?> pushResult;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('go-result-replace-close'),
                onPressed: () {
                  pushResult = context.unrouter.push<int>(const ResultRoute());
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<ResultRoute>(
          path: '/result',
          parse: (_) => const ResultRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('replace-close-result'),
                onPressed: () {
                  context.unrouter.replace(
                    const DoneRoute(),
                    completePendingResult: true,
                    result: 9,
                  );
                },
                child: const Text('replace close'),
              ),
            );
          },
        ),
        route<DoneRoute>(
          path: '/done',
          parse: (_) => const DoneRoute(),
          builder: (_, _) => const Text('done'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-result-replace-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('replace-close-result')));
    await tester.pumpAndSettle();

    expect(find.text('done'), findsOneWidget);
    await expectLater(pushResult, completion(9));
  });

  testWidgets('replace preserves pending push result by default', (
    tester,
  ) async {
    late Future<int?> pushResult;
    var completed = false;

    final router = Unrouter<AppRoute>(
      history: MemoryHistory(),
      routes: [
        route<HomeRoute>(
          path: '/',
          parse: (_) => const HomeRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('go-result-replace-preserve'),
                onPressed: () {
                  pushResult = context.unrouter.push<int>(const ResultRoute());
                  unawaited(
                    pushResult.then((_) {
                      completed = true;
                    }),
                  );
                },
                child: const Text('home'),
              ),
            );
          },
        ),
        route<ResultRoute>(
          path: '/result',
          parse: (_) => const ResultRoute(),
          builder: (context, _) {
            return Center(
              child: TextButton(
                key: const Key('replace-preserve-result'),
                onPressed: () {
                  context.unrouter.replace(const DoneRoute());
                },
                child: const Text('replace preserve'),
              ),
            );
          },
        ),
        route<DoneRoute>(
          path: '/done',
          parse: (_) => const DoneRoute(),
          builder: (_, _) => const Text('done'),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('go-result-replace-preserve')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('replace-preserve-result')));
    await tester.pumpAndSettle();

    expect(find.text('done'), findsOneWidget);
    expect(completed, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await expectLater(pushResult, completion(isNull));
    expect(completed, isTrue);
  });
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class UserRoute extends AppRoute {
  const UserRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/users/$id');
}

final class AdminRoute extends AppRoute {
  const AdminRoute();

  @override
  Uri toUri() => Uri(path: '/admin');
}

final class PrivateRoute extends AppRoute {
  const PrivateRoute();

  @override
  Uri toUri() => Uri(path: '/private');
}

final class LoginRoute extends AppRoute {
  const LoginRoute();

  @override
  Uri toUri() => Uri(path: '/login');
}

final class ResultRoute extends AppRoute {
  const ResultRoute();

  @override
  Uri toUri() => Uri(path: '/result');
}

final class DoneRoute extends AppRoute {
  const DoneRoute();

  @override
  Uri toUri() => Uri(path: '/done');
}

final class TransitionDemoRoute extends AppRoute {
  const TransitionDemoRoute();

  @override
  Uri toUri() => Uri(path: '/transition');
}

final class CustomPageDemoRoute extends AppRoute {
  const CustomPageDemoRoute();

  @override
  Uri toUri() => Uri(path: '/custom-page');
}

final class StaticPathRoute extends AppRoute {
  const StaticPathRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri(path: path);
}
