import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

class ExampleHomeView extends StatelessWidget {
  const ExampleHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Unrouter Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose a runnable example',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Both examples use constructor tear-offs for route views (XxxView.new) '
            'and run in a single shared router.',
          ),
          const SizedBox(height: 20),
          _ExampleCard(
            title: 'Quickstart',
            description:
                'Minimal createRouter + createRouterConfig + MaterialApp.router '
                'with static and dynamic routes.',
            actionLabel: 'Open Quickstart',
            onTap: () {
              router.push('/quickstart');
            },
          ),
          const SizedBox(height: 12),
          _ExampleCard(
            title: 'Advanced',
            description:
                'Guards (allow/block/redirect), named/path navigation, '
                'query override, state, Link options, nested layouts, and DataLoader.',
            actionLabel: 'Open Advanced',
            onTap: () {
              router.push('/advanced');
            },
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 12),
            FilledButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
