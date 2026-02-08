import 'package:unrouter/unrouter.dart';

sealed class AppRoute implements RouteData {
  const AppRoute();
}

final class HomeRoute extends AppRoute {
  const HomeRoute(RouteState _);

  @override
  Uri toUri() => Uri(path: '/');
}

void main() async {
  final router = Unrouter<AppRoute>(
    routes: const [Route(path: '/', parse: HomeRoute.new)],
  );

  final result = await router.resolve(Uri(path: '/'));
  if (result.isMatched) {
    print('matched: ${result.route.runtimeType}');
  }
}
