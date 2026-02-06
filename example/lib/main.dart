import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  runApp(const UnrouterExampleApp());
}

final DemoSession _session = DemoSession();
final UnrouterRedirectDiagnosticsStore _redirectDiagnostics =
    UnrouterRedirectDiagnosticsStore();
final ValueNotifier<int?> _lastPushResult = ValueNotifier<int?>(null);

final Unrouter<AppRoute> _router = Unrouter<AppRoute>(
  stateTimelineLimit: 128,
  machineTimelineLimit: 512,
  maxRedirectHops: 6,
  redirectLoopPolicy: RedirectLoopPolicy.error,
  onRedirectDiagnostics: _redirectDiagnostics.onDiagnostics,
  loading: (_) => const _BootScreen(),
  routes: <RouteRecord<AppRoute>>[
    route<RootRoute>(
      path: '/',
      parse: (_) => const RootRoute(),
      redirect: (_) => const AppHomeRoute().toUri(),
      builder: (_, _) => const SizedBox.shrink(),
    ),
    route<LegacyRoute>(
      path: '/legacy',
      parse: (_) => const LegacyRoute(),
      redirect: (_) => const AppHomeRoute().toUri(),
      builder: (_, _) => const SizedBox.shrink(),
    ),
    route<LoginRoute>(
      path: '/login',
      parse: (state) => LoginRoute(from: state.queryOrNull('from')),
      builder: (_, route) => LoginScreen(route: route),
    ),
    route<DebugRoute>(
      path: '/debug',
      parse: (_) => const DebugRoute(),
      builder: (_, _) => const DebugCenterScreen(),
    ),
    route<ResultRoute>(
      path: '/result/:id',
      parse: (state) => ResultRoute(id: state.pathInt('id')),
      builder: (_, route) => ResultScreen(route: route),
    ),
    ...shell<AppRoute>(
      name: 'app',
      branches: <ShellBranch<AppRoute>>[
        branch<AppRoute>(
          initialLocation: const AppHomeRoute().toUri(),
          routes: <RouteRecord<AppRoute>>[
            route<AppHomeRoute>(
              path: '/app/home',
              parse: (_) => const AppHomeRoute(),
              builder: (_, _) => const HomeScreen(),
            ),
            route<PostRoute>(
              path: '/app/home/post/:id',
              parse: (state) => PostRoute(
                id: state.pathInt('id'),
                tab: state.queryEnum(
                  'tab',
                  PostTab.values,
                  fallback: PostTab.overview,
                ),
              ),
              transitionDuration: const Duration(milliseconds: 220),
              reverseTransitionDuration: const Duration(milliseconds: 180),
              transitionBuilder: (context, animation, secondary, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                final offset = Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(curved);
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(position: offset, child: child),
                );
              },
              builder: (_, route) => PostScreen(route: route),
            ),
          ],
        ),
        branch<AppRoute>(
          initialLocation: const CatalogRoute().toUri(),
          routes: <RouteRecord<AppRoute>>[
            route<CatalogRoute>(
              path: '/app/catalog',
              parse: (_) => const CatalogRoute(),
              builder: (_, _) => const CatalogScreen(),
            ),
            routeWithLoader<CatalogItemRoute, DemoCatalogItem>(
              path: '/app/catalog/items/:id',
              parse: (state) => CatalogItemRoute(
                id: state.pathInt('id'),
                ref: state.queryOrNull('ref'),
              ),
              loader: (context) async {
                await Future<void>.delayed(const Duration(milliseconds: 280));
                context.signal.throwIfCancelled();
                return DemoCatalogRepository.byId(context.route.id);
              },
              builder: (_, route, item) =>
                  CatalogItemScreen(route: route, item: item),
            ),
          ],
        ),
        branch<AppRoute>(
          initialLocation: const ProfileRoute().toUri(),
          routes: <RouteRecord<AppRoute>>[
            route<ProfileRoute>(
              path: '/app/profile',
              parse: (_) => const ProfileRoute(),
              builder: (_, _) => const ProfileScreen(),
            ),
            route<SecureProfileRoute>(
              path: '/app/profile/secure',
              parse: (_) => const SecureProfileRoute(),
              guards: <RouteGuard<SecureProfileRoute>>[
                (context) {
                  if (_session.isSignedIn) {
                    return RouteGuardResult.allow();
                  }
                  return RouteGuardResult.redirect(
                    LoginRoute(from: context.uri.toString()).toUri(),
                  );
                },
              ],
              builder: (_, _) => const SecureProfileScreen(),
            ),
          ],
        ),
      ],
      builder: (context, shell, child) {
        return AppShellScaffold(shell: shell, child: child);
      },
    ),
  ],
  unknown: (_, uri) => UnknownRouteScreen(uri: uri),
  onError: (_, error, stackTrace) {
    return RouteErrorScreen(error: error, stackTrace: stackTrace);
  },
);

class UnrouterExampleApp extends StatelessWidget {
  const UnrouterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'unrouter example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1363DF)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({super.key, required this.shell, required this.child});

  final ShellState<AppRoute> shell;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final typed = context.unrouterAs<AppRoute>();
    final state = typed.state;
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('unrouter example'),
            actions: <Widget>[
              IconButton(
                key: const Key('shell-open-debug'),
                tooltip: 'Open debug center',
                onPressed: () {
                  context.unrouter.go(const DebugRoute());
                },
                icon: const Icon(Icons.bug_report_outlined),
              ),
              TextButton(
                key: const Key('shell-auth-toggle'),
                onPressed: _session.toggle,
                child: Text(_session.isSignedIn ? 'Sign out' : 'Sign in'),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: const Color(0xFFE8F0FE),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text('branch: ${shell.activeBranchIndex}'),
                    Text('routePath: ${state.routePath ?? '-'}'),
                    Text('resolution: ${state.resolution.name}'),
                    Text('canPopBranch: ${shell.canPopBranch}'),
                    OutlinedButton(
                      key: const Key('shell-pop-branch'),
                      onPressed: shell.canPopBranch
                          ? () {
                              shell.popBranch();
                            }
                          : null,
                      child: const Text('Pop branch'),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: shell.activeBranchIndex,
            onDestinationSelected: (index) {
              shell.goBranch(index);
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                label: 'Catalog',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lastEnvelope = '-';

  Future<void> _openPostAndWaitResult(BuildContext context) async {
    final result = await context.unrouter.push<int>(const ResultRoute(id: 101));
    _lastPushResult.value = result;
  }

  void _dispatchEnvelopeDemo(BuildContext context) {
    final machine = context.unrouterMachineAs<AppRoute>();
    final envelope = machine.dispatchActionEnvelope<bool>(
      UnrouterMachineAction.switchBranch(99),
    );
    setState(() {
      _lastEnvelope =
          '${envelope.state.name}'
          '/${envelope.failure?.code.name ?? 'none'}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final typed = context.unrouterAs<AppRoute>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Home center', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('uri: ${typed.uri}'),
        Text('historyIndex: ${typed.state.historyIndex ?? '-'}'),
        Text('machineTimeline: ${typed.machine.timeline.length}'),
        ValueListenableBuilder<int?>(
          valueListenable: _lastPushResult,
          builder: (context, value, child) {
            return Text('lastPostResult: ${value ?? '-'}');
          },
        ),
        Text('lastEnvelope: $_lastEnvelope'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton(
              key: const Key('home-open-post'),
              onPressed: () {
                _openPostAndWaitResult(context);
              },
              child: const Text('Push post detail'),
            ),
            FilledButton(
              key: const Key('home-go-catalog-branch'),
              onPressed: () {
                context.unrouter.switchBranch(1);
              },
              child: const Text('Go catalog branch'),
            ),
            FilledButton(
              key: const Key('home-go-profile-branch'),
              onPressed: () {
                context.unrouter.switchBranch(2);
              },
              child: const Text('Go profile branch'),
            ),
            OutlinedButton(
              key: const Key('home-go-legacy'),
              onPressed: () {
                context.unrouter.go(const LegacyRoute());
              },
              child: const Text('Go /legacy (redirect)'),
            ),
            OutlinedButton(
              key: const Key('home-machine-envelope'),
              onPressed: () {
                _dispatchEnvelopeDemo(context);
              },
              child: const Text('Envelope demo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'href(post/7): '
          '${context.unrouter.href(const PostRoute(id: 7, tab: PostTab.overview))}',
        ),
      ],
    );
  }
}

class PostScreen extends StatelessWidget {
  const PostScreen({super.key, required this.route});

  final PostRoute route;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Post ${route.id}',
          key: const Key('post-title'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('tab: ${route.tab.name}'),
        Text('uri: ${context.unrouter.uri}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton(
              key: const Key('post-pop-result'),
              onPressed: () {
                context.unrouter.replace(
                  const AppHomeRoute(),
                  completePendingResult: true,
                  result: route.id * 10,
                );
              },
              child: const Text('Return with result'),
            ),
            OutlinedButton(
              key: const Key('post-replace-catalog'),
              onPressed: () {
                context.unrouter.replace(
                  const CatalogRoute(),
                  completePendingResult: true,
                  result: route.id * 10,
                );
              },
              child: const Text('Replace -> catalog'),
            ),
            OutlinedButton(
              key: const Key('post-back'),
              onPressed: context.unrouter.back,
              child: const Text('Back'),
            ),
          ],
        ),
      ],
    );
  }
}

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typed = context.unrouterAs<AppRoute>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('Catalog center', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('resolution: ${typed.state.resolution.name}'),
        Text('historyIndex: ${typed.state.historyIndex ?? '-'}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final item in DemoCatalogRepository.items)
              FilledButton(
                key: Key('catalog-open-item-${item.id}'),
                onPressed: () {
                  context.unrouter.push(
                    CatalogItemRoute(id: item.id, ref: 'catalog-screen'),
                  );
                },
                child: Text('Open item ${item.id}'),
              ),
            OutlinedButton(
              key: const Key('catalog-go-home-branch'),
              onPressed: () {
                context.unrouter.switchBranch(0);
              },
              child: const Text('Go home branch'),
            ),
            OutlinedButton(
              key: const Key('catalog-go-profile-branch'),
              onPressed: () {
                context.unrouter.switchBranch(2);
              },
              child: const Text('Go profile branch'),
            ),
          ],
        ),
      ],
    );
  }
}

class CatalogItemScreen extends StatelessWidget {
  const CatalogItemScreen({super.key, required this.route, required this.item});

  final CatalogItemRoute route;
  final DemoCatalogItem item;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Item #${item.id}',
          key: Key('catalog-item-title-${item.id}'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('name: ${item.name}'),
        Text('price: \$${item.price.toStringAsFixed(2)}'),
        Text('ref: ${route.ref ?? '-'}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton(
              key: const Key('catalog-item-pop'),
              onPressed: () {
                context.unrouter.pop('picked-${item.id}');
              },
              child: const Text('Pop'),
            ),
            OutlinedButton(
              key: const Key('catalog-item-back'),
              onPressed: context.unrouter.back,
              child: const Text('Back'),
            ),
            OutlinedButton(
              key: const Key('catalog-item-debug'),
              onPressed: () {
                context.unrouter.go(const DebugRoute());
              },
              child: const Text('Open debug'),
            ),
          ],
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Profile center',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('signedIn: ${_session.isSignedIn}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  key: const Key('profile-open-secure'),
                  onPressed: () {
                    context.unrouter.go(const SecureProfileRoute());
                  },
                  child: const Text('Open secure page'),
                ),
                OutlinedButton(
                  key: const Key('profile-sign-in'),
                  onPressed: _session.signIn,
                  child: const Text('Sign in'),
                ),
                OutlinedButton(
                  key: const Key('profile-sign-out'),
                  onPressed: _session.signOut,
                  child: const Text('Sign out'),
                ),
                OutlinedButton(
                  key: const Key('profile-go-home-branch'),
                  onPressed: () {
                    context.unrouter.switchBranch(0);
                  },
                  child: const Text('Go home branch'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class SecureProfileScreen extends StatelessWidget {
  const SecureProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Secure profile center',
          key: const Key('secure-profile-title'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text('This route is protected by a guard.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton(
              onPressed: () {
                context.unrouter.go(const ProfileRoute());
              },
              child: const Text('Back to profile'),
            ),
            OutlinedButton(
              onPressed: () {
                context.unrouter.go(const DebugRoute());
              },
              child: const Text('Open debug center'),
            ),
          ],
        ),
      ],
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.route});

  final LoginRoute route;

  void _signInAndContinue(BuildContext context) {
    _session.signIn();
    final target = route.from;
    if (target == null || target.isEmpty) {
      context.unrouter.go(const ProfileRoute());
      return;
    }
    context.unrouter.goUri(Uri.parse(target));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in required')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            Text('redirect target: ${route.from ?? '/app/profile'}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  key: const Key('login-sign-in-continue'),
                  onPressed: () {
                    _signInAndContinue(context);
                  },
                  child: const Text('Sign in and continue'),
                ),
                OutlinedButton(
                  key: const Key('login-go-home'),
                  onPressed: () {
                    context.unrouter.go(const AppHomeRoute());
                  },
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.route});

  final ResultRoute route;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Result demo ${route.id}',
              key: const Key('result-title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('This page is pushed as a typed result demonstration.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  key: const Key('result-pop-result'),
                  onPressed: () {
                    context.unrouter.pop(route.id * 10);
                  },
                  child: const Text('Pop with result'),
                ),
                OutlinedButton(
                  onPressed: context.unrouter.back,
                  child: const Text('Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DebugCenterScreen extends StatefulWidget {
  const DebugCenterScreen({super.key});

  @override
  State<DebugCenterScreen> createState() => _DebugCenterScreenState();
}

class _DebugCenterScreenState extends State<DebugCenterScreen> {
  UnrouterInspectorBridge<AppRoute>? _bridge;
  UnrouterInspectorPanelAdapter? _panel;
  UnrouterInspectorReplayStore? _replay;
  UnrouterInspectorReplayController? _replayController;
  UnrouterInspectorReplayStore? _baselineReplay;
  UnrouterInspectorReplaySessionDiff? _diff;
  StreamSubscription<UnrouterInspectorEmission>? _bridgeSubscription;
  bool _initialized = false;
  String _status = 'idle';
  String _exportPreview = '-';
  String? _replaySnapshot;
  UnrouterInspectorReplayCompareMode _compareMode =
      UnrouterInspectorReplayCompareMode.sequence;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initializeDebugInfra();
  }

  void _initializeDebugInfra() {
    final inspector = context.unrouterAs<AppRoute>().inspector;
    final bridge = UnrouterInspectorBridge<AppRoute>(
      inspector: inspector,
      redirectDiagnostics: _redirectDiagnostics,
      config: const UnrouterInspectorBridgeConfig(
        timelineTail: 24,
        redirectTrailTail: 12,
        machineTimelineTail: 80,
      ),
    );
    final panel = UnrouterInspectorPanelAdapter.fromBridge(
      bridge: bridge,
      config: const UnrouterInspectorPanelAdapterConfig(maxEntries: 400),
    );
    final replay = UnrouterInspectorReplayStore.fromBridge(
      bridge: bridge,
      config: const UnrouterInspectorReplayStoreConfig(maxEntries: 1200),
    );
    final replayController = UnrouterInspectorReplayController(
      store: replay,
      config: const UnrouterInspectorReplayControllerConfig(
        step: Duration(milliseconds: 90),
      ),
    );

    _bridgeSubscription = bridge.stream.listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'event=${event.reason.name} uri=${event.report['uri']}';
      });
    });

    _bridge = bridge;
    _panel = panel;
    _replay = replay;
    _replayController = replayController;
    _status = 'debug infra ready';
    _initialized = true;
  }

  void _emitManual() {
    _bridge?.emit();
    setState(() {
      _status = 'manual emit';
    });
  }

  void _clearPanel() {
    _panel?.clear();
    setState(() {
      _status = 'panel cleared';
    });
  }

  void _exportReplaySnapshot() {
    final replay = _replay;
    if (replay == null) {
      return;
    }
    _replaySnapshot = replay.exportJson(pretty: true);
    setState(() {
      _status = 'replay snapshot exported';
      _exportPreview = _truncate(_replaySnapshot!);
    });
  }

  void _importReplaySnapshot() {
    final replay = _replay;
    final snapshot = _replaySnapshot;
    if (replay == null || snapshot == null) {
      return;
    }
    replay.clear(resetCounters: true);
    replay.importJson(snapshot);
    setState(() {
      _status = 'replay snapshot re-imported';
    });
  }

  void _captureBaseline() {
    final replay = _replay;
    if (replay == null) {
      return;
    }
    final baseline = UnrouterInspectorReplayStore();
    baseline.importJson(replay.exportJson());
    _baselineReplay?.dispose();
    _baselineReplay = baseline;
    _refreshDiff();
    setState(() {
      _status = 'baseline captured';
    });
  }

  void _refreshDiff() {
    final replay = _replay;
    final baseline = _baselineReplay;
    if (replay == null || baseline == null) {
      setState(() {
        _diff = null;
        _status = 'baseline missing';
      });
      return;
    }
    final diff = replay.compareWith(baseline, mode: _compareMode, tail: 200);
    setState(() {
      _diff = diff;
      _status =
          'diff changed=${diff.changedCount} '
          'missingBaseline=${diff.missingBaselineCount} '
          'missingCurrent=${diff.missingCurrentCount}';
    });
  }

  void _validateReplay() {
    final replay = _replay;
    if (replay == null) {
      return;
    }
    final result = replay.validateCompatibility();
    setState(() {
      _status =
          'compatibility issues=${result.issues.length} '
          'errors=${result.errorCount} warnings=${result.warningCount}';
    });
  }

  Future<void> _togglePlayPauseResume() async {
    final replayController = _replayController;
    if (replayController == null) {
      return;
    }
    if (replayController.value.isPlaying) {
      replayController.pause();
      setState(() {
        _status = 'replay paused';
      });
      return;
    }
    if (replayController.value.isPaused) {
      replayController.resume();
      setState(() {
        _status = 'replay resumed';
      });
      return;
    }
    final delivered = await replayController.play();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = 'replay finished delivered=$delivered';
    });
  }

  void _stopReplay() {
    _replayController?.stop();
    setState(() {
      _status = 'replay stopped';
    });
  }

  void _onExportSelected(String payload) {
    setState(() {
      _exportPreview = _truncate(payload);
      _status = 'panel selection exported';
    });
  }

  String _truncate(String value, [int max = 260]) {
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max)}...';
  }

  @override
  void dispose() {
    unawaited(_bridgeSubscription?.cancel());
    _replayController?.dispose();
    _replay?.dispose();
    _baselineReplay?.dispose();
    _panel?.dispose();
    _bridge?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panel = _panel;
    final replay = _replay;
    final replayController = _replayController;
    if (!_initialized ||
        panel == null ||
        replay == null ||
        replayController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final inspector = context.unrouterAs<AppRoute>().inspector;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        panel,
        replay,
        replayController,
      ]),
      builder: (context, _) {
        final replayValidation = replay.validateCompatibility();
        final replayState = replay.value;
        final replayControllerState = replayController.value;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Debug Center'),
            actions: <Widget>[
              TextButton(
                key: const Key('debug-go-home'),
                onPressed: () {
                  context.unrouter.go(const AppHomeRoute());
                },
                child: const Text('Back to app'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton(
                      key: const Key('debug-manual-emit'),
                      onPressed: _emitManual,
                      child: const Text('Emit now'),
                    ),
                    OutlinedButton(
                      key: const Key('debug-clear-panel'),
                      onPressed: _clearPanel,
                      child: const Text('Clear panel'),
                    ),
                    OutlinedButton(
                      key: const Key('debug-export-replay'),
                      onPressed: _exportReplaySnapshot,
                      child: const Text('Export replay'),
                    ),
                    OutlinedButton(
                      key: const Key('debug-import-replay'),
                      onPressed: _importReplaySnapshot,
                      child: const Text('Import replay'),
                    ),
                    OutlinedButton(
                      key: const Key('debug-capture-baseline'),
                      onPressed: _captureBaseline,
                      child: const Text('Capture baseline'),
                    ),
                    OutlinedButton(
                      key: const Key('debug-run-diff'),
                      onPressed: _refreshDiff,
                      child: const Text('Run diff'),
                    ),
                    OutlinedButton(
                      key: const Key('debug-validate-replay'),
                      onPressed: _validateReplay,
                      child: const Text('Validate replay'),
                    ),
                    OutlinedButton(
                      key: const Key('debug-play-toggle'),
                      onPressed: _togglePlayPauseResume,
                      child: Text(
                        replayControllerState.isPlaying
                            ? 'Pause replay'
                            : replayControllerState.isPaused
                            ? 'Resume replay'
                            : 'Play replay',
                      ),
                    ),
                    OutlinedButton(
                      key: const Key('debug-stop-play'),
                      onPressed: _stopReplay,
                      child: const Text('Stop replay'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<UnrouterInspectorReplayCompareMode>(
                  segments:
                      const <ButtonSegment<UnrouterInspectorReplayCompareMode>>[
                        ButtonSegment<UnrouterInspectorReplayCompareMode>(
                          value: UnrouterInspectorReplayCompareMode.sequence,
                          label: Text('sequence diff'),
                        ),
                        ButtonSegment<UnrouterInspectorReplayCompareMode>(
                          value: UnrouterInspectorReplayCompareMode.path,
                          label: Text('path diff'),
                        ),
                      ],
                  selected: <UnrouterInspectorReplayCompareMode>{_compareMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _compareMode = selection.first;
                    });
                    _refreshDiff();
                  },
                ),
                const SizedBox(height: 10),
                Text('status: $_status'),
                Text(
                  'panel entries=${panel.value.entries.length} '
                  'dropped=${panel.value.droppedCount}',
                ),
                Text(
                  'replay entries=${replayState.entries.length} '
                  'phase=${replayControllerState.phase.name} '
                  'speed=${replayControllerState.speed.label} '
                  'replayed=${replayControllerState.replayedCount}',
                ),
                Text(
                  'compatibility issues=${replayValidation.issues.length} '
                  'errors=${replayValidation.errorCount} '
                  'warnings=${replayValidation.warningCount}',
                ),
                Text(
                  _diff == null
                      ? 'diff: not ready'
                      : 'diff changed=${_diff!.changedCount} '
                            'missingBaseline=${_diff!.missingBaselineCount} '
                            'missingCurrent=${_diff!.missingCurrentCount}',
                ),
                const SizedBox(height: 12),
                UnrouterInspectorWidget<AppRoute>(
                  inspector: inspector,
                  redirectDiagnostics: _redirectDiagnostics,
                  timelineTail: 6,
                  redirectTrailTail: 4,
                  machineTimelineTail: 8,
                  onExport: (payload) {
                    setState(() {
                      _exportPreview = _truncate(payload);
                      _status = 'inspector report exported';
                    });
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  key: const Key('debug-panel'),
                  height: 580,
                  child: UnrouterInspectorPanelWidget(
                    panel: panel,
                    replayController: replayController,
                    replayDiff: _diff,
                    maxVisibleEntries: 120,
                    listHeight: 220,
                    compareListHeight: 120,
                    onClear: _clearPanel,
                    onExportSelected: _onExportSelected,
                    onMachineEventGroupsChanged: (groups) {
                      _bridge?.updateMachineEventGroups(groups);
                      setState(() {
                        _status = 'machine groups synced';
                      });
                    },
                    onMachinePayloadKindsChanged: (kinds) {
                      _bridge?.updateMachinePayloadKinds(kinds);
                      setState(() {
                        _status = 'machine payload kinds synced';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'export preview:\n$_exportPreview',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key, required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unknown route')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('No route matched: $uri'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                context.unrouter.go(const AppHomeRoute());
              },
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteErrorScreen extends StatelessWidget {
  const RouteErrorScreen({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    final preview = '$error\n$stackTrace';
    return Scaffold(
      appBar: AppBar(title: const Text('Route error')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            Text('error: ${error.runtimeType}'),
            const SizedBox(height: 8),
            SelectableText(
              preview.length > 700
                  ? '${preview.substring(0, 700)}...'
                  : preview,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  onPressed: () {
                    context.unrouter.go(const AppHomeRoute());
                  },
                  child: const Text('Go home'),
                ),
                OutlinedButton(
                  onPressed: () {
                    context.unrouter.go(const DebugRoute());
                  },
                  child: const Text('Open debug center'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class DemoSession extends ChangeNotifier {
  bool _signedIn = false;

  bool get isSignedIn => _signedIn;

  void signIn() {
    if (_signedIn) {
      return;
    }
    _signedIn = true;
    notifyListeners();
  }

  void signOut() {
    if (!_signedIn) {
      return;
    }
    _signedIn = false;
    notifyListeners();
  }

  void toggle() {
    _signedIn = !_signedIn;
    notifyListeners();
  }
}

class DemoCatalogItem {
  const DemoCatalogItem({
    required this.id,
    required this.name,
    required this.price,
  });

  final int id;
  final String name;
  final double price;
}

class DemoCatalogRepository {
  const DemoCatalogRepository._();

  static const List<DemoCatalogItem> items = <DemoCatalogItem>[
    DemoCatalogItem(id: 1, name: 'Keyboard', price: 79.0),
    DemoCatalogItem(id: 2, name: 'Mouse', price: 39.0),
    DemoCatalogItem(id: 3, name: 'Display', price: 399.0),
  ];

  static DemoCatalogItem byId(int id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    throw StateError('No catalog item found for id=$id');
  }
}

sealed class AppRoute implements RouteData {
  const AppRoute();
}

enum PostTab { overview, comments }

final class RootRoute extends AppRoute {
  const RootRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

final class AppHomeRoute extends AppRoute {
  const AppHomeRoute();

  @override
  Uri toUri() => Uri(path: '/app/home');
}

final class PostRoute extends AppRoute {
  const PostRoute({required this.id, this.tab = PostTab.overview});

  final int id;
  final PostTab tab;

  @override
  Uri toUri() => Uri(
    path: '/app/home/post/$id',
    queryParameters: <String, String>{'tab': tab.name},
  );
}

final class CatalogRoute extends AppRoute {
  const CatalogRoute();

  @override
  Uri toUri() => Uri(path: '/app/catalog');
}

final class CatalogItemRoute extends AppRoute {
  const CatalogItemRoute({required this.id, this.ref});

  final int id;
  final String? ref;

  @override
  Uri toUri() => Uri(
    path: '/app/catalog/items/$id',
    queryParameters: ref == null ? null : <String, String>{'ref': ref!},
  );
}

final class ProfileRoute extends AppRoute {
  const ProfileRoute();

  @override
  Uri toUri() => Uri(path: '/app/profile');
}

final class SecureProfileRoute extends AppRoute {
  const SecureProfileRoute();

  @override
  Uri toUri() => Uri(path: '/app/profile/secure');
}

final class LoginRoute extends AppRoute {
  const LoginRoute({this.from});

  final String? from;

  @override
  Uri toUri() => Uri(
    path: '/login',
    queryParameters: from == null ? null : <String, String>{'from': from!},
  );
}

final class DebugRoute extends AppRoute {
  const DebugRoute();

  @override
  Uri toUri() => Uri(path: '/debug');
}

final class ResultRoute extends AppRoute {
  const ResultRoute({required this.id});

  final int id;

  @override
  Uri toUri() => Uri(path: '/result/$id');
}

final class LegacyRoute extends AppRoute {
  const LegacyRoute();

  @override
  Uri toUri() => Uri(path: '/legacy');
}
