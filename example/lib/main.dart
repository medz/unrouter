import 'package:flutter/material.dart' hide Router;
import 'package:unrouter/unrouter.dart';

final _traceMiddleware = defineMiddleware((context, next) async {
  final location = useLocation(context);
  debugPrint('[middleware:trace] ${location.uri}');
  return next();
});

final _searchLatencyMiddleware = defineMiddleware((context, next) async {
  await Future<void>.delayed(const Duration(milliseconds: 250));
  return next();
});

final _adminGuardMiddleware = defineMiddleware((context, next) async {
  final token = useQuery(context).get('token');
  if (token != 'open-sesame') {
    return const _GuardBlockedView();
  }
  return next();
});

final router = createRouter(
  middleware: [_traceMiddleware],
  routes: [
    Inlet(
      path: '/',
      view: _rootView,
      meta: const {'title': 'Unrouter Demo'},
      children: [
        Inlet(
          name: 'home',
          path: '',
          view: _homeView,
          meta: const {'title': 'Home'},
        ),
        Inlet(
          name: 'profile',
          path: 'users/:id',
          view: _profileView,
          meta: const {'title': 'Profile'},
        ),
        Inlet(
          name: 'search',
          path: 'search',
          view: _searchView,
          middleware: [_searchLatencyMiddleware],
          meta: const {'title': 'Search'},
        ),
        Inlet(
          name: 'docs',
          path: 'docs/*',
          view: _docsView,
          meta: const {'title': 'Docs'},
        ),
        Inlet(
          name: 'admin',
          path: 'admin',
          view: _adminView,
          middleware: [_adminGuardMiddleware],
          meta: const {'title': 'Admin'},
        ),
        Inlet(
          name: 'notFound',
          path: '*',
          view: _notFoundView,
          meta: const {'title': 'Not Found'},
        ),
      ],
    ),
  ],
);

void main() {
  runApp(const _DemoApp());
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: createRouterConfig(router),
    );
  }
}

Widget _rootView() => const _ShellView();

class _ShellView extends StatelessWidget {
  const _ShellView();

  @override
  Widget build(BuildContext context) {
    final meta = useRouteMeta(context);
    return Scaffold(
      appBar: AppBar(title: Text(meta['title']?.toString() ?? 'Unrouter')),
      body: const Row(
        children: [
          SizedBox(width: 360, child: _WorkbenchPanel()),
          VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Outlet(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchPanel extends StatefulWidget {
  const _WorkbenchPanel();

  @override
  State<_WorkbenchPanel> createState() => _WorkbenchPanelState();
}

class _WorkbenchPanelState extends State<_WorkbenchPanel> {
  late final TextEditingController _idController;
  late final TextEditingController _searchController;
  late final TextEditingController _docsController;
  late final TextEditingController _stateController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: '42');
    _searchController = TextEditingController(text: 'flutter');
    _docsController = TextEditingController(text: 'guide/getting-started');
    _stateController = TextEditingController(text: 'from-workbench');
  }

  @override
  void dispose() {
    _idController.dispose();
    _searchController.dispose();
    _docsController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final location = useLocation(context);
    final from = useFromLocation(context);
    final params = useRouteParams(context);
    final query = useQuery(context);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Navigation Workbench'),
        const SizedBox(height: 12),
        TextField(
          controller: _idController,
          decoration: const InputDecoration(labelText: 'profile id'),
        ),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(labelText: 'search query'),
        ),
        TextField(
          controller: _docsController,
          decoration: const InputDecoration(labelText: 'docs wildcard'),
        ),
        TextField(
          controller: _stateController,
          decoration: const InputDecoration(labelText: 'state'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: () => _run(
                () => router.push('home', state: _makeState()),
              ),
              child: const Text('push home'),
            ),
            FilledButton(
              onPressed: () => _run(
                () => router.push(
                  'profile',
                  params: {'id': _idController.text.trim()},
                  query: URLSearchParams(const {'tab': 'posts'}),
                  state: _makeState(),
                ),
              ),
              child: const Text('push profile'),
            ),
            FilledButton(
              onPressed: () => _run(
                () => router.push(
                  'search',
                  query: URLSearchParams({
                    'q': _searchController.text.trim(),
                    'page': '1',
                  }),
                  state: _makeState(),
                ),
              ),
              child: const Text('push search'),
            ),
            FilledButton(
              onPressed: () => _run(
                () => router.push(
                  'docs',
                  params: {'wildcard': _docsController.text.trim()},
                  state: _makeState(),
                ),
              ),
              child: const Text('push docs/*'),
            ),
            FilledButton(
              onPressed: () => _run(
                () => router.push(
                  'admin',
                  query: URLSearchParams(const {'token': 'open-sesame'}),
                  state: _makeState(),
                ),
              ),
              child: const Text('push admin(ok)'),
            ),
            FilledButton(
              onPressed: () => _run(() => router.push('admin', state: _makeState())),
              child: const Text('push admin(denied)'),
            ),
            FilledButton(
              onPressed: () => _run(
                () => router.replace(
                  'search',
                  query: URLSearchParams({
                    'q': _searchController.text.trim(),
                    'mode': 'replace',
                  }),
                  state: _makeState(),
                ),
              ),
              child: const Text('replace search'),
            ),
            FilledButton(
              onPressed: () => _run(() => router.push('/unknown/path')),
              child: const Text('push unknown'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: router.back,
              child: const Text('back'),
            ),
            OutlinedButton(
              onPressed: router.forward,
              child: const Text('forward'),
            ),
            OutlinedButton(
              onPressed: () => router.go(-2),
              child: const Text('go(-2)'),
            ),
            OutlinedButton(
              onPressed: () => router.go(1),
              child: const Text('go(1)'),
            ),
          ],
        ),
        if (_error case final error?) ...[
          const SizedBox(height: 8),
          Text(
            'error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ],
        const Divider(height: 24),
        Text('path: ${location.path}'),
        Text('query: ${query.toString()}'),
        Text('params: ${params.toString()}'),
        Text('state: ${location.state}'),
        Text('from: ${from?.uri.toString() ?? '-'}'),
        Text('history index: ${router.history.index}'),
        Text('last action: ${router.history.action.name}'),
        const SizedBox(height: 16),
        _NavigationJournal(router: router),
      ],
    );
  }

  Map<String, String> _makeState() {
    return {
      'source': _stateController.text.trim(),
      'at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() {
      _error = null;
    });
    try {
      await task();
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    }
  }
}

class _NavigationJournal extends StatefulWidget {
  const _NavigationJournal({required this.router});

  final Router router;

  @override
  State<_NavigationJournal> createState() => _NavigationJournalState();
}

class _NavigationJournalState extends State<_NavigationJournal> {
  final _logs = <String>[];

  @override
  void initState() {
    super.initState();
    widget.router.addListener(_record);
    _record();
  }

  @override
  void didUpdateWidget(covariant _NavigationJournal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router == widget.router) {
      return;
    }

    oldWidget.router.removeListener(_record);
    widget.router.addListener(_record);
    _record();
  }

  @override
  void dispose() {
    widget.router.removeListener(_record);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('journal'),
        const SizedBox(height: 8),
        for (final item in _logs.take(10))
          Text(
            item,
            style: const TextStyle(fontSize: 12),
          ),
      ],
    );
  }

  void _record() {
    if (!mounted) {
      return;
    }

    final history = widget.router.history;
    final snapshot =
        '${history.action.name.toUpperCase()} '
        'idx=${history.index} '
        'uri=${history.location.uri}';
    setState(() {
      _logs.insert(0, snapshot);
      if (_logs.length > 40) {
        _logs.removeRange(40, _logs.length);
      }
    });
  }
}

Widget _homeView() {
  final location = useLocation;
  return Builder(
    builder: (context) {
      return _PageScaffold(
        title: 'Home',
        child: Text('location: ${location(context).uri}'),
      );
    },
  );
}

Widget _profileView() {
  return Builder(
    builder: (context) {
      final params = useRouteParams(context);
      final query = useQuery(context);
      final location = useLocation(context);
      return _PageScaffold(
        title: 'Profile',
        child: Text(
          'id=${params['id']}, tab=${query.get('tab')}, state=${location.state}',
        ),
      );
    },
  );
}

Widget _searchView() {
  return Builder(
    builder: (context) {
      final query = useQuery(context);
      final location = useLocation(context);
      return _PageScaffold(
        title: 'Search',
        child: Text('q=${query.get('q')}, uri=${location.uri}'),
      );
    },
  );
}

Widget _docsView() {
  return Builder(
    builder: (context) {
      final params = useRouteParams(context);
      return _PageScaffold(
        title: 'Docs',
        child: Text('wildcard=${params['wildcard']}'),
      );
    },
  );
}

Widget _adminView() {
  return Builder(
    builder: (context) {
      final location = useLocation(context);
      return _PageScaffold(
        title: 'Admin',
        child: Text('state=${location.state}'),
      );
    },
  );
}

Widget _notFoundView() {
  return Builder(
    builder: (context) {
      final location = useLocation(context);
      final router = useRouter(context);
      return _PageScaffold(
        title: 'Not Found',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No route matched: ${location.path}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                router.replace('home');
              },
              child: const Text('go home'),
            ),
          ],
        ),
      );
    },
  );
}

class _GuardBlockedView extends StatelessWidget {
  const _GuardBlockedView();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    return _PageScaffold(
      title: 'Admin Guard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Blocked by middleware: missing token=open-sesame'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              router.replace(
                'admin',
                query: URLSearchParams(const {'token': 'open-sesame'}),
              );
            },
            child: const Text('retry with token'),
          ),
        ],
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
