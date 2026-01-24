import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  runApp(const App());
}

// Router configuration - demonstrates hybrid routing (declarative + widget-scoped)
// Declarative routes can use Routes widget internally for progressive routing
final router = Unrouter(
  strategy: .browser,
  enableNavigator1: true,
  routes: const [
    Inlet(name: 'home', factory: Home.new),
    Inlet(name: 'about', path: 'about', factory: About.new),
    Inlet(
      name: 'routeAnimation',
      path: 'route-animation',
      factory: RouteAnimationDemo.new,
    ),

    // Layout route - wraps children without adding path segment
    Inlet(
      factory: AuthLayout.new,
      children: [
        Inlet(name: 'login', path: 'login', factory: Login.new),
        Inlet(name: 'register', path: 'register', factory: Register.new),
      ],
    ),

    // Nested route - has path segment + children
    Inlet(
      name: 'concerts',
      path: 'concerts',
      factory: ConcertsLayout.new,
      children: [
        Inlet(name: 'concertsHome', factory: ConcertsHome.new),
        Inlet(name: 'concertCity', path: ':city', factory: CityPage.new),
        Inlet(
          name: 'concertsTrending',
          path: 'trending',
          factory: TrendingPage.new,
        ),
      ],
    ),

    // Nested animation demo
    Inlet(
      name: 'nestedAnimation',
      path: 'nested-animation',
      factory: NestedAnimationLayout.new,
      children: [
        Inlet(name: 'nestedAnimationIntro', factory: NestedAnimationIntro.new),
        Inlet(
          name: 'nestedAnimationDetails',
          path: 'details',
          factory: NestedAnimationDetails.new,
        ),
        Inlet(
          name: 'nestedAnimationReviews',
          path: 'reviews',
          factory: NestedAnimationReviews.new,
        ),
      ],
    ),

    // Hybrid routing: declarative route that uses Routes widget internally
    // This demonstrates partial matching - /products matches this declarative route,
    // then ProductsPage uses Routes widget (widget-scoped) to match remaining segments like /123
    Inlet(name: 'products', path: 'products', factory: ProductsPage.new),
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Unrouter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

// Home Page (Index Route)
class Home extends StatelessWidget {
  const Home({super.key});

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
                    () => context.navigate.route('about'),
                  ),
                  _buildNavButton(
                    context,
                    'Login',
                    Icons.login,
                    Colors.green,
                    () => router.navigate.route('login'),
                  ),
                  _buildNavButton(
                    context,
                    'Concerts: Tokyo',
                    Icons.location_city,
                    Colors.orange,
                    () => context.navigate.route(
                      'concertCity',
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
                    to: Uri.parse('/concerts'),
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
                    to: Uri.parse('/products'),
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
                    () => context.navigate.route('routeAnimation'),
                  ),
                  _buildNavButton(
                    context,
                    'Nested Transition',
                    Icons.view_agenda,
                    Colors.orange,
                    () => context.navigate.route('nestedAnimation'),
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

// About Page
class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigate.back(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'About Unrouter',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'A declarative routing library for Flutter with static route configuration.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.navigate.route('home'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class RouteAnimationDemo extends StatelessWidget {
  const RouteAnimationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.routeAnimation(
      duration: const Duration(milliseconds: 400),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(animation);

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: slide,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Route Animation'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.navigate.back(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Full-page transition',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'This page uses context.routeAnimation(...) to animate '
                  'the entire route on push/pop.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome, size: 32),
                    title: const Text('Animation Controller'),
                    subtitle: Text(
                      'Duration: ${controller.duration?.inMilliseconds}ms',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.navigate.route('nestedAnimation'),
                  icon: const Icon(Icons.view_agenda),
                  label: const Text('See Nested Animation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
                _buildTab(context, 'Intro', '/nested-animation'),
                _buildTab(context, 'Details', '/nested-animation/details'),
                _buildTab(context, 'Reviews', '/nested-animation/reviews'),
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
        onTap: () => context.navigate(.parse(path)),
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

class NestedAnimationIntro extends StatelessWidget {
  const NestedAnimationIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return _AnimatedPanel(
      icon: Icons.animation,
      title: 'Nested transitions',
      subtitle:
          'Only this panel animates while the layout header stays in place.',
      color: Colors.deepOrange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('• Switch tabs to see push/replace/pop transitions.'),
          SizedBox(height: 8),
          Text('• The Outlet region animates independently.'),
        ],
      ),
    );
  }
}

class NestedAnimationDetails extends StatelessWidget {
  const NestedAnimationDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return _AnimatedPanel(
      icon: Icons.settings,
      title: 'Details',
      subtitle: 'Route animation can be customized per nested page.',
      color: Colors.orange.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('• Fade + slide driven by routeAnimation.'),
          SizedBox(height: 8),
          Text('• Duration can be tuned per route.'),
          SizedBox(height: 8),
          Text('• Works for leaf routes inside layouts.'),
        ],
      ),
    );
  }
}

class NestedAnimationReviews extends StatelessWidget {
  const NestedAnimationReviews({super.key});

  @override
  Widget build(BuildContext context) {
    return _AnimatedPanel(
      icon: Icons.star,
      title: 'Reviews',
      subtitle: 'Animated panel with stacked transitions.',
      color: Colors.brown,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('“Feels like Navigator transitions.”'),
          SizedBox(height: 8),
          Text('“Works in nested layouts too.”'),
          SizedBox(height: 8),
          Text('“No Navigator 1.0 dependency.”'),
        ],
      ),
    );
  }
}

class _AnimatedPanel extends StatelessWidget {
  const _AnimatedPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = context.routeAnimation(
      duration: const Duration(milliseconds: 260),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color,
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

// Auth Layout (Layout Route - no path segment)
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    print('Auth');
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade300, Colors.green.shade700],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.navigate.back(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Authentication',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Child routes render here
              const Expanded(child: Outlet()),
            ],
          ),
        ),
      ),
    );
  }
}

// Login Page
class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    print('Login');
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.login, size: 64, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Login',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.navigate.route('register'),
                child: const Text('Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Register Page
class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    print('Register');
    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add, size: 64, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Register',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.navigate.route('login'),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Concerts Layout (Nested Route)
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
          // Navigation tabs
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
          // Child routes render here
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
        onTap: () => router.navigate(.parse(path)),
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

// Concerts Home (Index Route)
class ConcertsHome extends StatelessWidget {
  const ConcertsHome({super.key});

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

// City Page (Dynamic Route)
class CityPage extends StatelessWidget {
  const CityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final city = state.params['city'] ?? 'Unknown';
    final displayCity = city
        .replaceAll('-', ' ')
        .split(' ')
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

// Trending Page
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
            '🔥 Trending Now',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        _buildTrendingCard('The Weeknd World Tour', '1.2M interested', 1),
        _buildTrendingCard('Taylor Swift Eras Tour', '980K interested', 2),
        _buildTrendingCard('Coldplay Concert', '850K interested', 3),
        _buildTrendingCard('Billie Eilish Live', '720K interested', 4),
        _buildTrendingCard('Ed Sheeran +–=÷× Tour', '690K interested', 5),
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

// Products Page - demonstrates widget-scoped routing with Routes widget
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigate.back(),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This page uses Routes widget for widget-scoped routing',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Widget-scoped routes defined with Routes widget
          Expanded(
            child: Routes(const [
              Inlet(factory: ProductsList.new),
              Inlet(path: ':id', factory: ProductDetail.new),
            ]),
          ),
        ],
      ),
    );
  }
}

class ProductsList extends StatelessWidget {
  const ProductsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'All Products',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        _buildProductCard(context, '1', 'Laptop', '\$999', Icons.laptop),
        _buildProductCard(context, '2', 'Phone', '\$699', Icons.phone_android),
        _buildProductCard(context, '3', 'Tablet', '\$499', Icons.tablet),
        _buildProductCard(
          context,
          '4',
          'Headphones',
          '\$199',
          Icons.headphones,
        ),
        _buildProductCard(context, '5', 'Watch', '\$299', Icons.watch),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    String id,
    String name,
    String price,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(price),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => router.navigate(.parse('/products/$id')),
      ),
    );
  }
}

class ProductDetail extends StatelessWidget {
  const ProductDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.routeState;
    final productId = state.params['id'] ?? 'unknown';

    final products = {
      '1': ('Laptop', '\$999', Icons.laptop),
      '2': ('Phone', '\$699', Icons.phone_android),
      '3': ('Tablet', '\$499', Icons.tablet),
      '4': ('Headphones', '\$199', Icons.headphones),
      '5': ('Watch', '\$299', Icons.watch),
    };

    final product = products[productId];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.purple,
              child: Icon(
                product?.$3 ?? Icons.shopping_cart,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              product?.$1 ?? 'Unknown Product',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              product?.$2 ?? '\$0',
              style: TextStyle(
                fontSize: 24,
                color: Colors.purple.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Chip(
              label: Text('Product ID: $productId'),
              backgroundColor: Colors.purple.shade50,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.navigate.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
