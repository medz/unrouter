import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

final ValueNotifier<int> linkTapCount = ValueNotifier<int>(0);

class AdvancedSignInView extends StatelessWidget {
  const AdvancedSignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final query = useQuery(context);
    final router = useRouter(context);
    final from = query.get('from') ?? '/advanced/app';

    return Scaffold(
      appBar: AppBar(title: const Text('Advanced - Sign In')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Global guard redirects here when auth=1 is missing in the target URI.',
          ),
          const SizedBox(height: 8),
          Text('from: $from'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final separator = from.contains('?') ? '&' : '?';
              router.replace('$from${separator}auth=1');
            },
            child: const Text('Sign in and continue'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {
              router.replace('dashboard', query: URLSearchParams('auth=1'));
            },
            child: const Text('Go to dashboard (named route)'),
          ),
        ],
      ),
    );
  }
}

class AdvancedRootLayoutView extends StatelessWidget {
  const AdvancedRootLayoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Example'),
        actions: [
          IconButton(
            onPressed: () => router.replace('/'),
            icon: const Icon(Icons.close),
          ),
          TextButton(
            onPressed: () => router.replace('signin'),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _NavLink(label: 'Dashboard', to: 'dashboard'),
                _NavLink(label: 'Reports', to: 'reports'),
                _NavLink(label: 'Search', to: 'search'),
                _NavLink(label: 'Loader', to: 'loader'),
                _NavLink(
                  label: 'Profile/7',
                  to: 'profileDetail',
                  params: const {'id': '7'},
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: Outlet()),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.to, this.params});

  final String label;
  final String to;
  final Map<String, String>? params;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Link(
        to: to,
        params: params,
        query: URLSearchParams('auth=1'),
        behavior: HitTestBehavior.opaque,
        child: IgnorePointer(
          child: FilledButton.tonal(onPressed: () {}, child: Text(label)),
        ),
      ),
    );
  }
}

class AdvancedDashboardView extends StatelessWidget {
  const AdvancedDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final location = useLocation(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Current location: ${location.uri}'),
        const SizedBox(height: 12),
        const Text('Guard demos'),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            router.push('/advanced/app');
          },
          child: const Text('Try protected path without auth (redirect)'),
        ),
        const SizedBox(height: 8),
        Link(
          to: 'reports',
          query: URLSearchParams('auth=1&blocked=1'),
          behavior: HitTestBehavior.opaque,
          child: IgnorePointer(
            child: FilledButton.tonal(
              onPressed: () {},
              child: const Text('Try reports with blocked=1 (block)'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Link(
          to: 'admin',
          query: URLSearchParams('auth=1'),
          behavior: HitTestBehavior.opaque,
          child: IgnorePointer(
            child: FilledButton.tonal(
              onPressed: () {},
              child: const Text(
                'Try admin without role (redirect by route guard)',
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Link(
          to: 'admin',
          query: URLSearchParams('auth=1&role=admin'),
          behavior: HitTestBehavior.opaque,
          child: IgnorePointer(
            child: FilledButton.tonal(
              onPressed: () {},
              child: const Text('Open admin with role=admin (allow)'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Navigation + Link demos'),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            router.push(
              '/advanced/app/search?q=old&page=1&auth=1',
              query: URLSearchParams({'q': 'flutter'}),
            );
          },
          child: const Text('Path + explicit query override (q=flutter)'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () {
            router.push(
              'profileDetail',
              params: const {'id': '42'},
              query: URLSearchParams('auth=1'),
              state: const {'source': 'dashboard', 'mode': 'imperative'},
            );
          },
          child: const Text('Named route + params + state (profile/42)'),
        ),
        const SizedBox(height: 8),
        Link(
          to: '/advanced/app/search?q=old&page=1&auth=1',
          query: URLSearchParams({'q': 'from-link'}),
          replace: true,
          onTap: () => linkTapCount.value += 1,
          behavior: HitTestBehavior.opaque,
          child: IgnorePointer(
            child: FilledButton.tonal(
              onPressed: () {},
              child: const Text('Link replace + onTap + query override'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Link(
          to: 'reports',
          enabled: false,
          query: URLSearchParams('auth=1'),
          child: IgnorePointer(
            child: FilledButton.tonal(
              onPressed: () {},
              child: const Text('Disabled Link(enabled: false)'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: linkTapCount,
          builder: (context, value, _) {
            return Text('Link onTap count: $value');
          },
        ),
      ],
    );
  }
}

class AdvancedReportsView extends StatelessWidget {
  const AdvancedReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final location = useLocation(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Reports view'),
        const SizedBox(height: 8),
        Text('Current location: ${location.uri}'),
      ],
    );
  }
}

class AdvancedAdminView extends StatelessWidget {
  const AdvancedAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final query = useQuery(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Admin view (allowed by route-level guard).'),
        const SizedBox(height: 8),
        Text('role=${query.get('role') ?? 'none'}'),
      ],
    );
  }
}

class AdvancedProfileLayoutView extends StatelessWidget {
  const AdvancedProfileLayoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile layout (nested Outlet)'),
          SizedBox(height: 12),
          Expanded(child: Outlet()),
        ],
      ),
    );
  }
}

class AdvancedProfileDetailView extends StatelessWidget {
  const AdvancedProfileDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final params = useRouteParams(context);
    final id = params.required('id');

    final state = useRouteState<Map<String, Object?>>(context);

    return ListView(
      children: [
        Text('Profile id: $id'),
        const SizedBox(height: 8),
        Text('Typed state: ${state ?? '<none>'}'),
      ],
    );
  }
}

class AdvancedSearchView extends StatelessWidget {
  const AdvancedSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final query = useQuery(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Search view (query merge/override target).'),
        const SizedBox(height: 8),
        Text('q=${query.get('q') ?? ''}'),
        Text('page=${query.get('page') ?? ''}'),
        Text('auth=${query.get('auth') ?? ''}'),
      ],
    );
  }
}
