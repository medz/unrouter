import 'package:flutter/material.dart';

class LegacyDetailsPage extends StatelessWidget {
  const LegacyDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigator 1.0 Page')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text(
              'Pushed with Navigator.of(context).push',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Pop'),
            ),
          ],
        ),
      ),
    );
  }
}
