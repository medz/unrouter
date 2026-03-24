import 'package:nocterm/nocterm.dart';
import 'package:nocterm_unrouter/nocterm_unrouter.dart';
import 'package:test/test.dart';

class NestedLayout extends StatelessComponent {
  const NestedLayout({super.key});

  @override
  Component build(BuildContext context) {
    return const Outlet();
  }
}

class ChildView extends StatelessComponent {
  const ChildView({super.key});

  @override
  Component build(BuildContext context) {
    return const Text('Child View');
  }
}

class WildcardView extends StatelessComponent {
  const WildcardView({super.key});

  @override
  Component build(BuildContext context) {
    final params = useRouteParams(context);
    return Text('wildcard:${params.required('wildcard')}');
  }
}

class RouterProbeView extends StatelessComponent {
  const RouterProbeView({required this.expectedRouter, super.key});

  final Unrouter expectedRouter;

  @override
  Component build(BuildContext context) {
    final router = useRouter(context);
    return Text('same-router:${identical(router, expectedRouter)}');
  }
}

void main() {
  test('nocterm adapter renders and exposes route scope values', () async {
    final tester = await NoctermTester.create();
    try {
      final router = createRouter(
        routes: [
          Inlet(
            path: '/',
            view: NestedLayout.new,
            children: [Inlet(path: 'child', view: ChildView.new)],
          ),
        ],
      );

      await router.push('/child');
      await tester.pumpComponent(RouterView(router: router));

      expect(tester.terminalState, containsText('Child View'));

      final wildcardRouter = createRouter(
        routes: [
          Inlet(path: '/', view: ChildView.new),
          Inlet(path: '/docs/**:wildcard', view: WildcardView.new),
        ],
      );

      await wildcardRouter.push('/docs/guide/getting-started');
      await tester.pumpComponent(RouterView(router: wildcardRouter));

      expect(
        tester.terminalState,
        containsText('wildcard:guide/getting-started'),
      );
    } finally {
      tester.dispose();
    }
  });

  test('useRouter returns the active router from route scope', () async {
    final tester = await NoctermTester.create();
    try {
      late final Unrouter router;
      router = createRouter(
        routes: [
          Inlet(
            path: '/',
            view: () => RouterProbeView(expectedRouter: router),
          ),
        ],
      );

      await tester.pumpComponent(RouterView(router: router));

      expect(tester.terminalState, containsText('same-router:true'));
    } finally {
      tester.dispose();
    }
  });

  test('useRouter throws outside the route scope', () async {
    final tester = await NoctermTester.create();
    final originalHandler = NoctermError.onError;
    final capturedErrors = <NoctermErrorDetails>[];
    try {
      NoctermError.onError = (details) {
        capturedErrors.add(details);
      };

      await tester.pumpComponent(
        Builder(
          builder: (context) {
            useRouter(context);
            return const Text('unreachable');
          },
        ),
      );

      expect(capturedErrors, hasLength(greaterThan(0)));
      expect(
        capturedErrors.any(
          (details) => details.exception.toString().contains(
            'Unrouter router is unavailable in this context.',
          ),
        ),
        isTrue,
      );
    } finally {
      NoctermError.onError = originalHandler;
      tester.dispose();
    }
  });
}
