import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';
import 'package:example/widgets/animated_panel.dart';

const route = RouteMeta(name: 'nestedAnimationIntro');

class NestedAnimationIntroPage extends StatelessWidget {
  const NestedAnimationIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedPanel(
      icon: Icons.animation,
      title: 'Nested transitions',
      subtitle:
          'Only this panel animates while the layout header stays in place.',
      color: Colors.deepOrange,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('- Switch tabs to see push/replace/pop transitions.'),
          SizedBox(height: 8),
          Text('- The Outlet region animates independently.'),
        ],
      ),
    );
  }
}
