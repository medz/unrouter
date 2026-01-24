import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  Widget wrap(Unrouter router) {
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('routeAnimation animates on push and pop', (tester) async {
    late AnimationController homeController;
    late AnimationController detailsController;

    Widget home() {
      return Builder(
        builder: (context) {
          homeController = context.routeAnimation(
            duration: const Duration(milliseconds: 100),
          );
          return const Text('Home');
        },
      );
    }

    Widget details() {
      return Builder(
        builder: (context) {
          detailsController = context.routeAnimation(
            duration: const Duration(milliseconds: 100),
          );
          return const Text('Details');
        },
      );
    }

    final router = Unrouter(
      routes: [
        Inlet(factory: home),
        Inlet(path: 'details', factory: details),
      ],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));
    expect(homeController.value, 1.0);

    router.navigate(path: '/details');
    await tester.pump();
    await tester.pump();

    expect(detailsController.status, AnimationStatus.forward);
    expect(homeController.status, AnimationStatus.reverse);

    await tester.pump(const Duration(milliseconds: 100));
    expect(detailsController.value, 1.0);
    expect(homeController.value, 0.0);

    await router.navigate.back();
    await tester.pump();
    await tester.pump();

    expect(homeController.status, AnimationStatus.forward);
    expect(detailsController.status, AnimationStatus.reverse);

    await tester.pump(const Duration(milliseconds: 100));
    expect(homeController.value, 1.0);
    expect(detailsController.value, 0.0);
  });

  testWidgets('routeAnimation animates on replace', (tester) async {
    late AnimationController detailsController;
    late AnimationController loginController;

    Widget details() {
      return Builder(
        builder: (context) {
          detailsController = context.routeAnimation(
            duration: const Duration(milliseconds: 100),
          );
          return const Text('Details');
        },
      );
    }

    Widget login() {
      return Builder(
        builder: (context) {
          loginController = context.routeAnimation(
            duration: const Duration(milliseconds: 100),
          );
          return const Text('Login');
        },
      );
    }

    final router = Unrouter(
      routes: [
        Inlet(factory: () => const Text('Home')),
        Inlet(path: 'details', factory: details),
        Inlet(path: 'login', factory: login),
      ],
      history: MemoryHistory(
        initialEntries: [RouteInformation(uri: Uri.parse('/details'))],
      ),
    );

    await tester.pumpWidget(wrap(router));

    router.navigate(path: '/login', replace: true);
    await tester.pump();
    await tester.pump();

    expect(detailsController.status, AnimationStatus.reverse);
    expect(loginController.status, AnimationStatus.forward);
  });
}
