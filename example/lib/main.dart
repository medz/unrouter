import 'package:flutter/material.dart' hide Route;
import 'package:unrouter/unrouter.dart';

void main() {
  runApp(const DemoApp());
}

final router = createRouter(
  // Optional: switch to hash for web deployments.
  strategy: .path,
  routes: [
    Route(
      path: '/',
      builder: (_) => const AppShell(),
      children: [
        Route(
          path: '',
          builder: (_) => const DashboardPage(),
          name: 'dashboard',
        ),
        Route(
          path: 'projects',
          builder: (_) => const ProjectsLayout(),
          name: 'projects',
          children: [
            Route(
              path: '',
              builder: (_) => const ProjectListPage(),
              name: 'projects.list',
            ),
            Route(
              path: ':id',
              builder: (_) => const ProjectDetailsPage(),
              name: 'projects.detail',
            ),
          ],
        ),
        Route(
          path: 'account',
          builder: (_) => const AccountLayout(),
          name: 'account',
          children: [
            Route(
              path: '',
              builder: (_) => const AccountOverviewPage(),
              name: 'account.overview',
            ),
            Route(
              path: 'settings',
              builder: (_) => const AccountSettingsPage(),
              name: 'account.settings',
            ),
          ],
        ),
      ],
    ),
    Route(path: '**', builder: (_) => const NotFoundPage()),
  ],
);

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Unrouter Workspace',
      routerDelegate: router.delegate,
      routeInformationParser: router.informationParser,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final route = useRoute(context);

    bool isProjects = (route.name ?? '').startsWith('projects');
    bool isAccount = (route.name ?? '').startsWith('account');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unrouter Workspace'),
        actions: [
          IconButton(
            tooltip: 'Dashboard',
            onPressed: () => router.replace(const .name('dashboard')),
            icon: const Icon(Icons.dashboard_outlined),
          ),
          IconButton(
            tooltip: 'Projects',
            onPressed: () => router.replace(const .name('projects')),
            icon: const Icon(Icons.folder_open),
          ),
          IconButton(
            tooltip: 'Account',
            onPressed: () => router.replace(const .name('account')),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.6),
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              children: [
                const Text(
                  'Navigation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _NavButton(
                  label: 'Dashboard',
                  icon: Icons.home_outlined,
                  selected: route.name == 'dashboard',
                  onTap: () => router.replace(const .name('dashboard')),
                ),
                _NavButton(
                  label: 'Projects',
                  icon: Icons.view_kanban_outlined,
                  selected: isProjects,
                  onTap: () => router.replace(const .name('projects')),
                ),
                _NavButton(
                  label: 'Account',
                  icon: Icons.person_outline,
                  selected: isAccount,
                  onTap: () => router.replace(const .name('account')),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Padding(padding: EdgeInsets.all(16), child: RouterView()),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = useQueryParams(context);
    return ListView(
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text('Welcome back! query=${query.isEmpty ? "{}" : query}'),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _StatCard(title: 'Active Projects', value: '6'),
            _StatCard(title: 'Pending Reviews', value: '3'),
            _StatCard(title: 'Unread Messages', value: '14'),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

class ProjectsLayout extends StatelessWidget {
  const ProjectsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final route = useRoute(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Projects',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Chip(label: Text(route.name ?? '')),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: const [
              Flexible(flex: 2, child: ProjectListPage()),
              SizedBox(width: 12),
              Flexible(flex: 3, child: RouterView()),
            ],
          ),
        ),
      ],
    );
  }
}

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = useRouter(context);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: projects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final project = projects[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).colorScheme.surface,
            title: Text(
              project.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${project.status} · Owner: ${project.owner}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => appRouter.push(
              RouteLocation.name('projects.detail', params: {'id': project.id}),
            ),
          );
        },
      ),
    );
  }
}

class ProjectDetailsPage extends StatelessWidget {
  const ProjectDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final params = useRouterParams(context);
    final id = params['id'] ?? '';
    final project = _findProject(id);

    if (project == null) {
      return const Center(child: Text('Select a project to view details'));
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(project.summary),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Status: ${project.status}')),
                Chip(label: Text('Owner: ${project.owner}')),
                Chip(label: Text('ID: ${project.id}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AccountLayout extends StatelessWidget {
  const AccountLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = useRouter(context);
    final route = useRoute(context);
    final isSettings = route.name == 'account.settings';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Overview'),
              selected: !isSettings,
              onSelected: (_) =>
                  appRouter.replace(const .name('account.overview')),
            ),
            FilterChip(
              label: const Text('Settings'),
              selected: isSettings,
              onSelected: (_) =>
                  appRouter.replace(const .name('account.settings')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Expanded(child: RouterView()),
      ],
    );
  }
}

class AccountOverviewPage extends StatelessWidget {
  const AccountOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('Name: Alex Chen'),
            Text('Role: Product Manager'),
            Text('Timezone: UTC+8'),
          ],
        ),
      ),
    );
  }
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Email notifications'),
            ),
            SwitchListTile(
              value: false,
              onChanged: (_) {},
              title: const Text('Weekly summaries'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final route = useRoute(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('404 - Page not found', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text('Path ${route.path} is missing'),
        ],
      ),
    );
  }
}

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.owner,
    required this.status,
    required this.summary,
  });

  final String id;
  final String title;
  final String owner;
  final String status;
  final String summary;
}

const projects = <Project>[
  Project(
    id: 'alpha',
    title: 'Alpha Launch',
    owner: 'Mia',
    status: 'In progress',
    summary: 'Coordinate beta users and land the 1.0 announcement.',
  ),
  Project(
    id: 'beta',
    title: 'Beta Migration',
    owner: 'Jamal',
    status: 'Blocked',
    summary: 'Waiting on auth team to finalize SSO callbacks.',
  ),
  Project(
    id: 'gamma',
    title: 'Gamma Design System',
    owner: 'Priya',
    status: 'Review',
    summary: 'Audit component usage and ship new tokens.',
  ),
];

Project? _findProject(String id) {
  for (final project in projects) {
    if (project.id == id) return project;
  }
  return null;
}
