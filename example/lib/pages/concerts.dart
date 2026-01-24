import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

const route = RouteMeta(name: 'concerts');

class ConcertsLayout extends StatelessWidget {
  const ConcertsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Concerts'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
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
                _buildTab(context, 'All', '/concerts'),
                _buildTab(context, 'Trending', '/concerts/trending'),
                _buildTab(context, 'Tokyo', '/concerts/tokyo'),
                _buildTab(context, 'NYC', '/concerts/new-york'),
              ],
            ),
          ),
          const Expanded(child: Outlet()),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
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
