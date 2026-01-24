// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

const route = RouteMeta(name: 'concertCity');

class CityPage extends StatelessWidget {
  const CityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final city = state.params['city'] ?? 'Unknown';
    final displayCity = city
        .replaceAll('-', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_city, size: 80, color: Colors.orange),
          const SizedBox(height: 24),
          Text(
            'Concerts in $displayCity',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Route param: $city',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Showing all concerts happening in this city.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
