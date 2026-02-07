import 'package:unrouter/unrouter.dart';

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute();

  @override
  Uri toUri() => Uri(path: '/');
}

void main() async {
  final router = Unrouter<AppRoute>(
    routes: [
      route<HomeRoute>(path: '/', parse: (_) => const HomeRoute()),
    ],
  );

  final result = await router.resolve(Uri(path: '/'));
  if (result.isMatched) {
    print('matched: ${result.route.runtimeType}');
  }
}
