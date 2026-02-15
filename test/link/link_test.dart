import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';
import '../support/test_app.dart';

class _DisabledLinkView extends StatelessWidget {
  const _DisabledLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(
      to: '/next',
      enabled: false,
      child: Text('Disabled Link'),
    );
  }
}

class _ReplaceLinkView extends StatelessWidget {
  const _ReplaceLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(to: '/next', replace: true, child: Text('Replace Link'));
  }
}

class _TapLinkView extends StatelessWidget {
  const _TapLinkView({super.key});

  static VoidCallback? onTap;

  static void reset() {
    onTap = null;
  }

  @override
  Widget build(BuildContext context) {
    return Link(to: '/next', onTap: onTap, child: const Text('Tap Link'));
  }
}

class _ProfileLinkView extends StatelessWidget {
  const _ProfileLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Link(
      to: 'profile',
      params: const {'id': '42'},
      query: URLSearchParams({'q': 'hello'}),
      state: 'link-state',
      child: const Text('Profile Link'),
    );
  }
}

class _RapidLinkView extends StatelessWidget {
  const _RapidLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Link(to: '/next', child: Text('Rapid Link'));
  }
}

class _NextView extends StatelessWidget {
  const _NextView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Next View');
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final params = useRouteParams(context);
    final query = useQuery(context);
    final state = useRouteState<String>(context);
    return Text('id:${params.required('id')};q:${query.get('q')};state:$state');
  }
}

void main() {
  group('link', () {
    testWidgets('does not navigate when enabled is false', (tester) async {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: _DisabledLinkView.new),
          Inlet(path: '/next', view: _NextView.new),
        ],
      );

      await pumpRouterApp(tester, router);
      await tester.tap(find.text('Disabled Link'));
      await tester.pump();

      expect(router.history.location.path, '/');
      expect(find.text('Disabled Link'), findsOneWidget);
    });

    testWidgets('uses replace semantics when replace=true', (tester) async {
      final history = createMemoryHistory(['/']);
      final router = createRouter(
        history: history,
        routes: [
          Inlet(path: '/', view: _ReplaceLinkView.new),
          Inlet(path: '/next', view: _NextView.new),
        ],
      );

      await pumpRouterApp(tester, router);
      await tester.tap(find.text('Replace Link'));
      await tester.pump();
      await tester.pump();

      expect(router.history.location.path, '/next');
      expect(router.history.index, 0);
    });

    testWidgets('invokes onTap callback', (tester) async {
      var tapped = 0;
      _TapLinkView.onTap = () => tapped += 1;
      addTearDown(_TapLinkView.reset);

      final router = createRouter(
        routes: [
          Inlet(path: '/', view: _TapLinkView.new),
          Inlet(path: '/next', view: _NextView.new),
        ],
      );

      await pumpRouterApp(tester, router);
      await tester.tap(find.text('Tap Link'));
      await tester.pump();
      await tester.pump();

      expect(tapped, 1);
      expect(router.history.location.path, '/next');
    });

    testWidgets('passes params query and state', (tester) async {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: _ProfileLinkView.new),
          Inlet(name: 'profile', path: '/users/:id', view: _ProfileView.new),
        ],
      );

      await pumpRouterApp(tester, router);
      await tester.tap(find.text('Profile Link'));
      await tester.pump();
      await tester.pump();

      expect(find.text('id:42;q:hello;state:link-state'), findsOneWidget);
    });

    testWidgets('handles rapid clicks without exceptions', (tester) async {
      final router = createRouter(
        routes: [
          Inlet(path: '/', view: _RapidLinkView.new),
          Inlet(path: '/next', view: _NextView.new),
        ],
      );

      await pumpRouterApp(tester, router);
      final finder = find.text('Rapid Link');

      for (var i = 0; i < 5; i++) {
        await tester.tap(finder);
      }

      await tester.pump();
      await tester.pump();

      expect(router.history.location.path, '/next');
      expect(router.history.index, greaterThanOrEqualTo(1));
      expect(tester.takeException(), isNull);
    });
  });
}
