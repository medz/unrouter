import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';
import 'package:example/widgets/animated_panel.dart';

const route = RouteMeta(name: 'nestedAnimationReviews');

class NestedAnimationReviewsPage extends StatelessWidget {
  const NestedAnimationReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedPanel(
      icon: Icons.star,
      title: 'Reviews',
      subtitle: 'Animated panel with stacked transitions.',
      color: Colors.brown,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"Feels like Navigator transitions."'),
          SizedBox(height: 8),
          Text('"Works in nested layouts too."'),
          SizedBox(height: 8),
          Text('"No Navigator 1.0 dependency."'),
        ],
      ),
    );
  }
}
