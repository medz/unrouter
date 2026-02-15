import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

final DataLoader<String> _messageLoader = defineDataLoader<String>((
  context,
) async {
  final query = useQuery(context);
  await Future<void>.delayed(const Duration(milliseconds: 700));
  if (query.get('fail') == '1') {
    throw StateError('Simulated request failure');
  }
  final stamp = DateTime.now().toIso8601String();
  return 'Loaded at $stamp';
}, defaults: () => 'Waiting for first fetch');

class DataLoaderDemoView extends StatelessWidget {
  const DataLoaderDemoView({super.key});

  @override
  Widget build(BuildContext context) {
    final router = useRouter(context);
    final query = useQuery(context);
    final data = _messageLoader(context);

    final statusText = data.when<String>(
      context: context,
      idle: (value) => 'idle: $value',
      pending: (value) => 'pending: $value',
      success: (value) => 'success: $value',
      error: (error) => 'error: ${error?.error}',
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('DataLoader demo'),
        const SizedBox(height: 8),
        Text('status: $statusText'),
        const SizedBox(height: 8),
        Text('fail mode: ${query.get('fail') == '1'}'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            data.refresh();
          },
          child: const Text('Refresh loader'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () {
            router.replace('loader', query: URLSearchParams('auth=1'));
          },
          child: const Text('Normal mode (auth=1)'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () {
            router.replace('loader', query: URLSearchParams('auth=1&fail=1'));
          },
          child: const Text('Failure mode (auth=1&fail=1)'),
        ),
      ],
    );
  }
}
