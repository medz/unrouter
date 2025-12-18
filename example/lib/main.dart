import 'package:flutter/material.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  runApp(const App());
}

// Router configuration
final router = Unrouter(
  strategy: .browser,
  routes: const [
    Inlet(factory: Home.new),
    Inlet(path: 'about', factory: About.new),

    // Layout route - wraps children without adding path segment
    Inlet(
      factory: AuthLayout.new,
      children: [
        Inlet(path: 'login', factory: Login.new),
        Inlet(path: 'register', factory: Register.new),
      ],
    ),

    // Nested route - has path segment + children
    Inlet(
      path: 'concerts',
      factory: ConcertsLayout.new,
      children: [
        Inlet(factory: ConcertsHome.new),
        Inlet(path: ':city', factory: CityPage.new),
        Inlet(path: 'trending', factory: TrendingPage.new),
      ],
    ),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Unrouter Example',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            _buildNavButton(
              context,
              'About',
              Icons.info,
              Colors.blue,
              () => router.push('/about'),
            ),
            _buildNavButton(
              context,
              'Login',
              Icons.login,
              Colors.green,
              () => router.push('/login'),
            ),
            _buildNavButton(
              context,
              'Concerts',
              Icons.music_note,
              Colors.orange,
              () => router.push('/concerts'),
            ),
          ],
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
          onPressed: () => router.back(),
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
              onPressed: () => router.push('/'),
              child: const Text('Back to Home'),
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
                      onPressed: () => router.back(),
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
                onPressed: () => router.push('/register'),
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
                onPressed: () => router.push('/login'),
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
          onPressed: () => router.back(),
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
    final state = RouterStateProvider.maybeOf(context);
    final isActive = state?.info.uri.path == path;

    return Expanded(
      child: InkWell(
        onTap: () => router.push(path),
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
    final state = RouterStateProvider.of(context);
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
