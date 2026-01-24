import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

const route = RouteMeta(name: 'routeAnimation');

class RouteAnimationPage extends StatelessWidget {
  const RouteAnimationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.routeAnimation(
      duration: const Duration(milliseconds: 400),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slide,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Route Animation'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.navigate.back(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Full-page transition',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'This page uses context.routeAnimation(...) to animate '
                  'the entire route on push/pop.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome, size: 32),
                    title: const Text('Animation Controller'),
                    subtitle: Text(
                      'Duration: ${controller.duration?.inMilliseconds}ms',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.navigate(name: 'nestedAnimation'),
                  icon: const Icon(Icons.view_agenda),
                  label: const Text('See Nested Animation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
