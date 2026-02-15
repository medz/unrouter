import 'package:flutter/material.dart' hide Router;
import 'package:unrouter/unrouter.dart';

final _session = ValueNotifier<_Session>(const _Session.guest());

const _projects = <_Project>[
  _Project(
    id: 'p-100',
    name: 'Checkout Revamp',
    owner: 'Mia',
    status: 'active',
    summary: 'Improve conversion with a two-step checkout.',
  ),
  _Project(
    id: 'p-101',
    name: 'Search Quality',
    owner: 'Leo',
    status: 'active',
    summary: 'Tune ranking and synonym expansion for product search.',
  ),
  _Project(
    id: 'p-102',
    name: 'Billing Migration',
    owner: 'Ava',
    status: 'blocked',
    summary: 'Move legacy subscriptions to the new billing provider.',
  ),
  _Project(
    id: 'p-103',
    name: 'Observability Kit',
    owner: 'Noah',
    status: 'done',
    summary: 'Standardize logs, traces, and service dashboards.',
  ),
];

final _traceMiddleware = defineMiddleware((context, next) async {
  final location = useLocation(context);
  debugPrint('[unrouter][trace] ${location.uri}');
  return next();
});

final _authMiddleware = defineMiddleware((context, next) async {
  if (_session.value.loggedIn) {
    return next();
  }
  return const _AuthRequiredPage();
});

final _adminMiddleware = defineMiddleware((context, next) async {
  if (_session.value.isAdmin) {
    return next();
  }
  return const _ForbiddenPage();
});

final _searchLatencyMiddleware = defineMiddleware((context, next) async {
  await Future<void>.delayed(const Duration(milliseconds: 180));
  return next();
});

final router = createRouter(
  middleware: [_traceMiddleware],
  routes: [
    Inlet(
      name: 'landing',
      path: '/',
      view: _LandingPage.new,
      meta: const {'title': 'Acme Studio'},
    ),
    Inlet(
      name: 'login',
      path: '/login',
      view: _LoginPage.new,
      meta: const {'title': 'Sign In'},
    ),
    Inlet(
      path: '/workspace',
      view: _WorkspaceShellPage.new,
      middleware: [_authMiddleware],
      meta: const {'title': 'Workspace'},
      children: [
        Inlet(
          name: 'workspaceHome',
          path: '',
          view: _WorkspaceHomePage.new,
          meta: const {'title': 'Dashboard'},
        ),
        Inlet(
          name: 'projects',
          path: 'projects',
          view: _ProjectListPage.new,
          meta: const {'title': 'Projects'},
        ),
        Inlet(
          name: 'projectDetail',
          path: 'projects/:id',
          view: _ProjectDetailPage.new,
          meta: const {'title': 'Project'},
        ),
        Inlet(
          name: 'search',
          path: 'search',
          view: _SearchPage.new,
          middleware: [_searchLatencyMiddleware],
          meta: const {'title': 'Search'},
        ),
        Inlet(
          name: 'settings',
          path: 'settings',
          view: _SettingsPage.new,
          meta: const {'title': 'Settings'},
        ),
        Inlet(
          name: 'admin',
          path: 'admin',
          view: _AdminPage.new,
          middleware: [_adminMiddleware],
          meta: const {'title': 'Admin'},
        ),
      ],
    ),
    Inlet(
      name: 'docs',
      path: '/docs/*',
      view: _DocsPage.new,
      meta: const {'title': 'Docs'},
    ),
    Inlet(
      name: 'notFound',
      path: '*',
      view: _NotFoundPage.new,
      meta: const {'title': 'Not Found'},
    ),
  ],
);

void main() {
  runApp(const _ExampleApp());
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0E7490),
        useMaterial3: true,
      ),
      routerConfig: createRouterConfig(router),
    );
  }
}

class _Session {
  const _Session({
    required this.loggedIn,
    required this.userName,
    required this.role,
  });

  const _Session.guest() : loggedIn = false, userName = 'Guest', role = 'guest';

  factory _Session.member(String userName) {
    return _Session(loggedIn: true, userName: userName, role: 'member');
  }

  factory _Session.admin(String userName) {
    return _Session(loggedIn: true, userName: userName, role: 'admin');
  }

  final bool loggedIn;
  final String userName;
  final String role;

  bool get isAdmin => role == 'admin';
}

class _Project {
  const _Project({
    required this.id,
    required this.name,
    required this.owner,
    required this.status,
    required this.summary,
  });

  final String id;
  final String name;
  final String owner;
  final String status;
  final String summary;
}

_Project? _findProject(String id) {
  for (final project in _projects) {
    if (project.id == id) {
      return project;
    }
  }
  return null;
}

class _LandingPage extends StatelessWidget {
  const _LandingPage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Acme Studio')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unrouter Example App',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Auth, nested routes, params/query, middleware, and history behavior.',
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<_Session>(
                  valueListenable: _session,
                  builder: (context, session, _) {
                    final text = session.loggedIn
                        ? 'Current user: ${session.userName} (${session.role})'
                        : 'Current user: not signed in';
                    return Text(text);
                  },
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        router.push(
                          'workspaceHome',
                          state: {
                            'from': 'landing',
                            'at': DateTime.now().toIso8601String(),
                          },
                        );
                      },
                      icon: const Icon(Icons.work_outline),
                      label: const Text('Open workspace'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        router.push(
                          'login',
                          query: URLSearchParams(const {
                            'redirect': '/workspace',
                          }),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Go to sign in'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        router.push(
                          'docs',
                          params: const {'wildcard': 'guide/getting-started'},
                        );
                      },
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Open docs'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPage extends StatefulWidget {
  const _LoginPage();

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  late final TextEditingController _nameController;
  String _role = 'member';
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'seven');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final query = useQuery(context);
    final redirect = query.get('redirect') ?? '/workspace';

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign in to workspace',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text('After sign in, you will be redirected to: $redirect'),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text('member')),
                    DropdownMenuItem(value: 'admin', child: Text('admin')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _role = value;
                    });
                  },
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  Text(error, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) {
                          setState(() {
                            _error = 'Username cannot be empty';
                          });
                          return;
                        }

                        _session.value = _role == 'admin'
                            ? _Session.admin(name)
                            : _Session.member(name);

                        setState(() {
                          _error = null;
                        });

                        await router.replace(
                          redirect,
                          state: {'from': 'login', 'role': _role, 'user': name},
                        );
                      },
                      child: const Text('Sign in and continue'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        router.replace('/');
                      },
                      child: const Text('Back to home'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceShellPage extends StatelessWidget {
  const _WorkspaceShellPage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final location = useLocation(context);
    final meta = useRouteMeta(context);
    final title = meta['title']?.toString() ?? 'Workspace';

    return Scaffold(
      appBar: AppBar(
        title: Text('Acme Workspace · $title'),
        actions: [
          ValueListenableBuilder<_Session>(
            valueListenable: _session,
            builder: (context, session, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text('${session.userName} (${session.role})'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Back',
            onPressed: router.back,
            icon: const Icon(Icons.arrow_back),
          ),
          IconButton(
            tooltip: 'Forward',
            onPressed: router.forward,
            icon: const Icon(Icons.arrow_forward),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              _session.value = const _Session.guest();
              await router.replace('/');
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _workspaceNavIndex(location.path),
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  router.push('workspaceHome');
                case 1:
                  router.push('projects');
                case 2:
                  router.push(
                    'search',
                    query: URLSearchParams(const {'q': 'search'}),
                  );
                case 3:
                  router.push('settings');
                case 4:
                  router.push('admin');
              }
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_copy_outlined),
                selectedIcon: Icon(Icons.folder_copy),
                label: Text('Projects'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: Text('Search'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings),
                label: Text('Admin'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: ColoredBox(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Card(
                  child: Padding(padding: EdgeInsets.all(20), child: Outlet()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _workspaceNavIndex(String path) {
    if (path.startsWith('/workspace/projects')) {
      return 1;
    }
    if (path.startsWith('/workspace/search')) {
      return 2;
    }
    if (path.startsWith('/workspace/settings')) {
      return 3;
    }
    if (path.startsWith('/workspace/admin')) {
      return 4;
    }
    return 0;
  }
}

class _WorkspaceHomePage extends StatelessWidget {
  const _WorkspaceHomePage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final location = useLocation(context);
    final from = useFromLocation(context);

    final activeCount = _projects
        .where((entry) => entry.status == 'active')
        .length;
    final blockedCount = _projects
        .where((entry) => entry.status == 'blocked')
        .length;
    final doneCount = _projects.where((entry) => entry.status == 'done').length;

    return _PageFrame(
      title: 'Dashboard',
      subtitle: 'Team progress overview and quick actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(label: 'Active', value: activeCount),
              _MetricCard(label: 'Blocked', value: blockedCount),
              _MetricCard(label: 'Done', value: doneCount),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () {
                  router.push(
                    'projects',
                    query: URLSearchParams(const {'status': 'active'}),
                  );
                },
                child: const Text('View active projects'),
              ),
              OutlinedButton(
                onPressed: () {
                  router.push(
                    'search',
                    query: URLSearchParams(const {'q': 'billing'}),
                  );
                },
                child: const Text('Search billing'),
              ),
              OutlinedButton(
                onPressed: () {
                  router.push(
                    'docs',
                    params: const {'wildcard': 'workspace/navigation'},
                  );
                },
                child: const Text('Open docs'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('from: ${from?.uri.toString() ?? '-'}'),
          Text('state: ${location.state ?? '-'}'),
          Text('current: ${location.uri}'),
        ],
      ),
    );
  }
}

class _ProjectListPage extends StatelessWidget {
  const _ProjectListPage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final query = useQuery(context);
    final status = query.get('status') ?? 'all';

    final filtered = status == 'all'
        ? _projects
        : _projects.where((entry) => entry.status == status).toList();

    return _PageFrame(
      title: 'Projects',
      subtitle: 'Filter by status and open project details',
      scroll: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const ['all', 'active', 'blocked', 'done'])
                ChoiceChip(
                  selected: status == item,
                  label: Text(item),
                  onSelected: (_) {
                    if (item == 'all') {
                      router.replace('projects');
                      return;
                    }
                    router.replace(
                      'projects',
                      query: URLSearchParams({'status': item}),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final project = filtered[index];
                return Card(
                  child: ListTile(
                    title: Text(project.name),
                    subtitle: Text('${project.owner} · ${project.status}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      router.push(
                        'projectDetail',
                        params: {'id': project.id},
                        query: URLSearchParams(const {'tab': 'overview'}),
                        state: {'from': 'projects', 'selected': project.id},
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectDetailPage extends StatelessWidget {
  const _ProjectDetailPage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final params = useRouteParams(context);
    final query = useQuery(context);
    final location = useLocation(context);

    final id = params.required('id');
    final tab = query.get('tab') ?? 'overview';
    final project = _findProject(id);

    if (project == null) {
      return _PageFrame(
        title: 'Project Not Found',
        subtitle: 'Project $id was not found',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Go back to the project list and choose again.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                router.replace('projects');
              },
              child: const Text('Back to list'),
            ),
          ],
        ),
      );
    }

    return _PageFrame(
      title: project.name,
      subtitle: 'ID: ${project.id} · Owner: ${project.owner}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const ['overview', 'activity', 'settings'])
                ChoiceChip(
                  selected: tab == item,
                  label: Text(item),
                  onSelected: (_) {
                    router.replace(
                      'projectDetail',
                      params: {'id': id},
                      query: URLSearchParams({'tab': item}),
                      state: location.state,
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('status: ${project.status}'),
          const SizedBox(height: 8),
          Text(project.summary),
          const SizedBox(height: 12),
          Text('tab: $tab'),
          Text('state: ${location.state ?? '-'}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () {
                  router.push(
                    'search',
                    query: URLSearchParams({
                      'q': project.name.split(' ').first,
                    }),
                  );
                },
                child: const Text('Search by project name'),
              ),
              OutlinedButton(
                onPressed: () {
                  router.back();
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage();

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = useQuery(context).get('q') ?? '';
    if (_controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final query = useQuery(context).get('q')?.trim() ?? '';
    final results = query.isEmpty
        ? <_Project>[]
        : _projects
              .where(
                (entry) =>
                    entry.name.toLowerCase().contains(query.toLowerCase()) ||
                    entry.summary.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

    return _PageFrame(
      title: 'Search',
      subtitle: 'Driven by URL query; state restores on refresh.',
      scroll: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Enter keyword',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _runSearch(router, _controller.text);
                },
              ),
            ),
            onSubmitted: (value) {
              _runSearch(router, value);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final keyword in const ['checkout', 'search', 'billing'])
                ActionChip(
                  label: Text(keyword),
                  onPressed: () {
                    _runSearch(router, keyword);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty
                          ? 'Enter a keyword to start searching.'
                          : 'No results for "$query".',
                    ),
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final project = results[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: Theme.of(context).colorScheme.surface,
                        title: Text(project.name),
                        subtitle: Text(project.summary),
                        onTap: () {
                          router.push(
                            'projectDetail',
                            params: {'id': project.id},
                            query: URLSearchParams(const {'tab': 'overview'}),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _runSearch(Unrouter router, String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      router.replace('search');
      return;
    }
    router.replace('search', query: URLSearchParams({'q': value}));
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);

    return _PageFrame(
      title: 'Settings',
      subtitle: 'Session and permission demo',
      child: ValueListenableBuilder<_Session>(
        valueListenable: _session,
        builder: (context, session, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('current user: ${session.userName}'),
              Text('role: ${session.role}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () async {
                      _session.value = _Session.admin(session.userName);
                      await router.replace('admin');
                    },
                    child: const Text('Promote to admin'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      _session.value = _Session.member(session.userName);
                      await router.replace('workspaceHome');
                    },
                    child: const Text('Downgrade to member'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      _session.value = const _Session.guest();
                      await router.replace('/');
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminPage extends StatelessWidget {
  const _AdminPage();

  @override
  Widget build(BuildContext context) {
    final location = useLocation(context);

    return _PageFrame(
      title: 'Admin Console',
      subtitle: 'This page is protected by admin middleware.',
      child: ValueListenableBuilder<_Session>(
        valueListenable: _session,
        builder: (context, session, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('welcome, ${session.userName} (${session.role})'),
              const SizedBox(height: 8),
              Text('uri: ${location.uri}'),
              Text('state: ${location.state ?? '-'}'),
              const SizedBox(height: 12),
              const Text(
                'Switch roles in Settings to verify middleware behavior.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DocsPage extends StatelessWidget {
  const _DocsPage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final params = useRouteParams(context);
    final path = params['wildcard'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Docs')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Docs path: /docs/$path'),
            const SizedBox(height: 12),
            const Text('`docs/*` demonstrates wildcard params.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () {
                    router.push(
                      'docs',
                      params: const {'wildcard': 'guide/middleware'},
                    );
                  },
                  child: const Text('Open middleware docs'),
                ),
                OutlinedButton(
                  onPressed: () {
                    router.replace('/');
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

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final location = useLocation(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unmatched path: ${location.path}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                router.replace('/');
              },
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthRequiredPage extends StatelessWidget {
  const _AuthRequiredPage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final location = useLocation(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in required')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('This route is protected. Please sign in first.'),
                  const SizedBox(height: 8),
                  Text('Target: ${location.uri}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      router.replace(
                        'login',
                        query: URLSearchParams({
                          'redirect': location.uri.toString(),
                        }),
                      );
                    },
                    child: const Text('Go to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForbiddenPage extends StatelessWidget {
  const _ForbiddenPage();

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Insufficient permissions')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin page is only accessible to admin users.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      router.replace('settings');
                    },
                    child: const Text('Go to settings to switch role'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 6),
              Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.title,
    required this.child,
    this.subtitle,
    this.scroll = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (scroll) {
      content = SingleChildScrollView(child: child);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (subtitle case final text?) ...[
          const SizedBox(height: 4),
          Text(text),
        ],
        const SizedBox(height: 16),
        Expanded(child: content),
      ],
    );
  }
}
