import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  Widget wrapRouter(Unrouter router) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Router.withConfig(config: router),
    );
  }

  testWidgets('static routes win over params regardless of order', (
    tester,
  ) async {
    final router = Unrouter(
      routes: RouteIndex.fromRoutes([
        Inlet(
          name: 'concerts',
          path: 'concerts',
          factory: ConcertsLayout.new,
          children: [
            Inlet(name: 'concertCity', path: ':city', factory: CityPage.new),
            Inlet(
              name: 'concertsTrending',
              path: 'trending',
              factory: TrendingPage.new,
            ),
          ],
        ),
      ]),
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrapRouter(router));
    await tester.pumpAndSettle();

    await router.navigate(path: '/concerts/trending');
    await tester.pumpAndSettle();

    final location =
        router.routerDelegate.currentConfiguration as RouteLocation;
    expect(location.name, 'concertsTrending');
    expect(find.text('Trending'), findsOneWidget);
  });

  testWidgets('param routes still match when static does not', (tester) async {
    final router = Unrouter(
      routes: RouteIndex.fromRoutes([
        Inlet(
          name: 'concerts',
          path: 'concerts',
          factory: ConcertsLayout.new,
          children: [
            Inlet(name: 'concertCity', path: ':city', factory: CityPage.new),
            Inlet(
              name: 'concertsTrending',
              path: 'trending',
              factory: TrendingPage.new,
            ),
          ],
        ),
      ]),
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrapRouter(router));
    await tester.pumpAndSettle();

    await router.navigate(path: '/concerts/berlin');
    await tester.pumpAndSettle();

    final location =
        router.routerDelegate.currentConfiguration as RouteLocation;
    expect(location.name, 'concertCity');
    expect(router.history.location.uri.path, '/concerts/berlin');
    expect(find.text('City'), findsOneWidget);
  });
}

class ConcertsLayout extends StatelessWidget {
  const ConcertsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Outlet();
  }
}

class CityPage extends StatelessWidget {
  const CityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('City');
  }
}

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Trending');
  }
}
