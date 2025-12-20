import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/history.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  Widget wrap(Unrouter router) {
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('showDialog works with default navigator 1 support', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [Inlet(factory: () => const _DialogPage(label: 'Home'))],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));

    expect(find.text('Open'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Dialog'), findsOneWidget);
  });

  testWidgets('showModalBottomSheet works with navigator 1 support', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [Inlet(factory: () => const _BottomSheetPage(label: 'Home'))],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));

    expect(find.text('Open Sheet'), findsOneWidget);
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Sheet'), findsOneWidget);
    await tester.tap(find.text('Close Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Sheet'), findsNothing);
  });

  testWidgets('Navigator.push and pop work with navigator 1 support', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [Inlet(factory: () => const _PushPage(label: 'Home'))],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));

    expect(find.text('Push'), findsOneWidget);
    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    expect(find.text('Pushed'), findsOneWidget);
    await tester.tap(find.text('Pop'));
    await tester.pumpAndSettle();

    expect(find.text('Pushed'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('showGeneralDialog works with navigator 1 support', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [Inlet(factory: () => const _GeneralDialogPage(label: 'Home'))],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));

    await tester.tap(find.text('Open General'));
    await tester.pumpAndSettle();

    expect(find.text('General Dialog'), findsOneWidget);
    await tester.tap(find.text('Close General'));
    await tester.pumpAndSettle();

    expect(find.text('General Dialog'), findsNothing);
  });

  testWidgets('showMenu works with navigator 1 support', (tester) async {
    final router = Unrouter(
      routes: [Inlet(factory: () => const _MenuPage(label: 'Home'))],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));

    await tester.tap(find.text('Open Menu'));
    await tester.pumpAndSettle();

    expect(find.text('Menu Item'), findsOneWidget);
    await tester.tap(find.text('Menu Item'));
    await tester.pumpAndSettle();

    expect(find.text('Menu Item'), findsNothing);
  });

  testWidgets('popRoute closes dialog before history navigation', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const _DialogPage(label: 'Home')),
        Inlet(
          path: 'about',
          factory: () => const _DialogPage(label: 'About'),
        ),
      ],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));

    router.navigate(.parse('/about'));
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsOneWidget);

    await router.routerDelegate.popRoute();
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsNothing);
    expect(find.text('About'), findsOneWidget);

    await router.routerDelegate.popRoute();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('popRoute closes pushed route before history navigation', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [
        Inlet(factory: () => const _PushPage(label: 'Home')),
        Inlet(
          path: 'about',
          factory: () => const _PushPage(label: 'About'),
        ),
      ],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));

    router.navigate(.parse('/about'));
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();
    expect(find.text('Pushed'), findsOneWidget);

    await router.routerDelegate.popRoute();
    await tester.pumpAndSettle();
    expect(find.text('Pushed'), findsNothing);
    expect(find.text('About'), findsOneWidget);

    await router.routerDelegate.popRoute();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Navigator.popUntil pops to first', (tester) async {
    final router = Unrouter(
      routes: [Inlet(factory: () => const _PushPage(label: 'Home'))],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));

    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();
    expect(find.text('Pushed'), findsOneWidget);

    await tester.tap(find.text('Push Deeper'));
    await tester.pumpAndSettle();
    expect(find.text('Pushed Deep'), findsOneWidget);

    await tester.tap(find.text('Pop Until Root'));
    await tester.pumpAndSettle();

    expect(find.text('Pushed Deep'), findsNothing);
    expect(find.text('Pushed'), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('nested Navigator uses inner stack independently', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [Inlet(factory: () => const _NestedNavigatorPage(label: 'Home'))],
      history: MemoryHistory(),
    );

    await tester.pumpWidget(wrap(router));

    expect(find.text('Inner Home'), findsOneWidget);
    await tester.tap(find.text('Inner Push'));
    await tester.pumpAndSettle();

    expect(find.text('Inner Pushed'), findsOneWidget);
    await tester.tap(find.text('Inner Pop'));
    await tester.pumpAndSettle();

    expect(find.text('Inner Pushed'), findsNothing);
    expect(find.text('Inner Home'), findsOneWidget);
  });

  testWidgets('disable navigator 1 support keeps previous behavior', (
    tester,
  ) async {
    final router = Unrouter(
      routes: [Inlet(factory: () => const _DialogPage(label: 'Home'))],
      history: MemoryHistory(),
      enableNavigator1: false,
    );

    await tester.pumpWidget(wrap(router));

    await tester.tap(find.text('Open'));
    await tester.pump();

    final exception = tester.takeException();
    expect(exception, isA<FlutterError>());
  });
}

class _DialogPage extends StatelessWidget {
  const _DialogPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return const AlertDialog(content: Text('Dialog'));
                },
              );
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetPage extends StatelessWidget {
  const _BottomSheetPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) {
                    return SizedBox(
                      height: 200,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Sheet'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close Sheet'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const Text('Open Sheet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PushPage extends StatelessWidget {
  const _PushPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const _PushedPage(),
                  ),
                );
              },
              child: const Text('Push'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PushedPage extends StatelessWidget {
  const _PushedPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pushed'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const _PushedDeepPage(),
                  ),
                );
              },
              child: const Text('Push Deeper'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Pop Until Root'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Pop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PushedDeepPage extends StatelessWidget {
  const _PushedDeepPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pushed Deep'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Pop Until Root'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Pop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralDialogPage extends StatelessWidget {
  const _GeneralDialogPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                showGeneralDialog<void>(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'General',
                  transitionDuration: const Duration(milliseconds: 1),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return Center(
                      child: Material(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('General Dialog'),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close General'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: const Text('Open General'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuPage extends StatelessWidget {
  const _MenuPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                showMenu<void>(
                  context: context,
                  position: const RelativeRect.fromLTRB(20, 20, 20, 20),
                  items: const [
                    PopupMenuItem<void>(value: null, child: Text('Menu Item')),
                  ],
                );
              },
              child: const Text('Open Menu'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NestedNavigatorPage extends StatelessWidget {
  const _NestedNavigatorPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute<void>(
                  builder: (context) => const _InnerHomePage(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InnerHomePage extends StatelessWidget {
  const _InnerHomePage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Inner Home'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const _InnerPushedPage(),
                ),
              );
            },
            child: const Text('Inner Push'),
          ),
        ],
      ),
    );
  }
}

class _InnerPushedPage extends StatelessWidget {
  const _InnerPushedPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Inner Pushed'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Inner Pop'),
          ),
        ],
      ),
    );
  }
}
