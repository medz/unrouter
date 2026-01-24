import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

const route = RouteMeta(name: 'nestedAnimation');

class NestedAnimationLayout extends StatelessWidget {
  const NestedAnimationLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nested Animation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigate.back(),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.orange.shade100,
            child: Row(
              children: [
                _buildTab(context, 'Intro', '/nested_animation'),
                _buildTab(context, 'Details', '/nested_animation/details'),
                _buildTab(context, 'Reviews', '/nested_animation/reviews'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: const Outlet(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, String path) {
    final state = context.maybeRouteState;
    final isActive = state?.location.uri.path == path;

    return Expanded(
      child: InkWell(
        onTap: () => context.navigate(path: path),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.orange : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.orange.shade900 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
