import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';
import 'package:example/widgets/animated_panel.dart';

const route = RouteMeta(name: 'nestedAnimationDetails');

class NestedAnimationDetailsPage extends StatelessWidget {
  const NestedAnimationDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedPanel(
      icon: Icons.settings,
      title: 'Details',
      subtitle: 'Route animation can be customized per nested page.',
      color: Colors.orange.shade700,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('- Fade + slide driven by routeAnimation.'),
          SizedBox(height: 8),
          Text('- Duration can be tuned per route.'),
          SizedBox(height: 8),
          Text('- Works for leaf routes inside layouts.'),
        ],
      ),
    );
  }
}
