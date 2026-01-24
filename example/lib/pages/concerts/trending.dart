import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

const route = RouteMeta(name: 'concertsTrending');

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Trending Now',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        _buildTrendingCard('The Weeknd World Tour', '1.2M interested', 1),
        _buildTrendingCard('Taylor Swift Eras Tour', '980K interested', 2),
        _buildTrendingCard('Coldplay Concert', '850K interested', 3),
        _buildTrendingCard('Billie Eilish Live', '720K interested', 4),
        _buildTrendingCard('Ed Sheeran Tour', '690K interested', 5),
      ],
    );
  }

  Widget _buildTrendingCard(String title, String interest, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rank <= 3 ? Colors.orange : Colors.grey,
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(interest),
        trailing: const Icon(Icons.trending_up, color: Colors.orange),
      ),
    );
  }
}
