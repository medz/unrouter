import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

const route = RouteMeta(name: 'concertsHome');

class ConcertsHomePage extends StatelessWidget {
  const ConcertsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildConcertCard(
          'Summer Music Festival',
          'Various Artists',
          'July 15-17, 2025',
          Icons.festival,
          Colors.purple,
        ),
        _buildConcertCard(
          'Rock Legends Live',
          'Classic Rock Band',
          'August 5, 2025',
          Icons.music_note,
          Colors.red,
        ),
        _buildConcertCard(
          'Jazz Night',
          'Jazz Ensemble',
          'September 12, 2025',
          Icons.piano,
          Colors.blue,
        ),
        _buildConcertCard(
          'Electronic Dreams',
          'DJ Mix',
          'October 20, 2025',
          Icons.headphones,
          Colors.cyan,
        ),
      ],
    );
  }

  Widget _buildConcertCard(
    String title,
    String artist,
    String date,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$artist\n$date'),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
