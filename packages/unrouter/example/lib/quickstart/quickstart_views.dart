import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

class QuickstartLayoutView extends StatelessWidget {
  const QuickstartLayoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quickstart'),
        actions: [
          IconButton(
            onPressed: () => router.replace('/'),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: const Outlet(),
    );
  }
}

class QuickstartHomeView extends StatelessWidget {
  const QuickstartHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final location = useLocation(context);
    final router = useRouter(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Current location: ${location.uri}'),
        const SizedBox(height: 12),
        const Text(
          'This page demonstrates Link navigation and imperative push().',
        ),
        const SizedBox(height: 16),
        Link(
          to: 'about',
          behavior: HitTestBehavior.opaque,
          child: IgnorePointer(
            child: FilledButton(
              onPressed: () {},
              child: const Text('Open static view with Link'),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonal(
          onPressed: () {
            router.push('profile', params: const {'id': '42'});
          },
          child: const Text('Push dynamic profile (id=42)'),
        ),
      ],
    );
  }
}

class QuickstartAboutView extends StatelessWidget {
  const QuickstartAboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final location = useLocation(context);
    final router = useRouter(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Static child view.'),
        const SizedBox(height: 8),
        Text('Current location: ${location.uri}'),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey<String>('quickstart-about-back'),
          onPressed: () => router.back(),
          child: const Text('Back'),
        ),
      ],
    );
  }
}

class QuickstartProfileView extends StatelessWidget {
  const QuickstartProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final params = useRouteParams(context);
    final location = useLocation(context);
    final router = useRouter(context);
    final id = params.required('id');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Profile id from params: $id'),
        const SizedBox(height: 8),
        Text('Current location: ${location.uri}'),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey<String>('quickstart-profile-back'),
          onPressed: () => router.back(),
          child: const Text('Back'),
        ),
      ],
    );
  }
}
