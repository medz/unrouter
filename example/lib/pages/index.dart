import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';
import 'package:example/widgets/legacy_details_page.dart';

GuardResult test(GuardContext context) {
  return .allow;
}

@RouteMeta(name: 'home', guards: [test])
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home, size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Unrouter Example',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Imperative Navigation (using buttons)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _buildNavButton(
                    context,
                    'About',
                    Icons.info,
                    Colors.blue,
                    () => context.navigate(name: 'about'),
                  ),
                  _buildNavButton(
                    context,
                    'Login',
                    Icons.login,
                    Colors.green,
                    () => context.navigate(name: 'login'),
                  ),
                  _buildNavButton(
                    context,
                    'Concerts: Tokyo',
                    Icons.location_city,
                    Colors.orange,
                    () => context.navigate(
                      name: 'concertCity',
                      params: {'city': 'tokyo'},
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Declarative Navigation (using Link widget)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Link(
                    path: '/concerts',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_note, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Concerts',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Link(
                    path: '/products',
                    builder: (context, location, navigate) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => navigate(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_bag, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Products (Link builder)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Route Animations',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _buildNavButton(
                    context,
                    'Full Page Transition',
                    Icons.layers,
                    Colors.deepPurple,
                    () => context.navigate(name: 'routeAnimation'),
                  ),
                  _buildNavButton(
                    context,
                    'Nested Transition',
                    Icons.view_agenda,
                    Colors.orange,
                    () => context.navigate(name: 'nestedAnimation'),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Navigator 1.0 APIs (enabled by default)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _buildNavButton(
                    context,
                    'Show Dialog',
                    Icons.chat_bubble_outline,
                    Colors.indigo,
                    () => _showLegacyDialog(context),
                  ),
                  _buildNavButton(
                    context,
                    'Show Bottom Sheet',
                    Icons.keyboard_arrow_up,
                    Colors.teal,
                    () => _showLegacyBottomSheet(context),
                  ),
                  _buildNavButton(
                    context,
                    'Show Menu',
                    Icons.more_vert,
                    Colors.brown,
                    () => _showLegacyMenu(context),
                  ),
                  _buildNavButton(
                    context,
                    'Push Page',
                    Icons.open_in_new,
                    Colors.deepPurple,
                    () => _pushLegacyPage(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(200, 50),
        ),
      ),
    );
  }

  void _showLegacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dialog'),
          content: const Text(
            'This dialog uses Navigator 1.0 APIs inside Unrouter.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLegacyBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bottom Sheet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text('This bottom sheet is Navigator 1.0 based.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLegacyMenu(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromLTRB(
      24,
      24,
      overlay.size.width - 24,
      overlay.size.height - 24,
    );
    showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem<String>(value: 'first', child: Text('Menu Item A')),
        PopupMenuItem<String>(value: 'second', child: Text('Menu Item B')),
      ],
    );
  }

  void _pushLegacyPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const LegacyDetailsPage()),
    );
  }
}
