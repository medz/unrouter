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
      await tester.pumpComponent(UnrouterHost(router: router));

      expect(tester.terminalState, containsText('Child View'));

      final wildcardRouter = createRouter(
        routes: [
          Inlet(path: '/', view: ChildView.new),
          Inlet(path: '/docs/**:wildcard', view: WildcardView.new),
        ],
      );

      await wildcardRouter.push('/docs/guide/getting-started');
      await tester.pumpComponent(UnrouterHost(router: wildcardRouter));

      expect(
        tester.terminalState,
        containsText('wildcard:guide/getting-started'),
      );
    } finally {
      tester.dispose();
    }
  });
}
