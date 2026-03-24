import 'package:nocterm/nocterm.dart';
import 'package:nocterm_example/nocterm_example.dart';
import 'package:test/test.dart';
import 'package:unrouter/nocterm.dart';

Future<void> pumpNavigation(NoctermTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump();
}

void main() {
  test('navigates between home docs and profile screens', () async {
    final tester = await NoctermTester.create();
    try {
      final router = buildExampleRouter();

      await tester.pumpComponent(ExampleApp(router: router));
      expect(tester.terminalState, containsText('Home'));

      await router.push('/docs/intro');
      await pumpNavigation(tester);
      expect(tester.terminalState, containsText('Docs Intro'));

      await router.push(
        'profile',
        params: {'id': '42'},
        query: URLSearchParams({'tab': 'activity'}),
        state: 'opened-from-shell',
      );
      await pumpNavigation(tester);
      expect(tester.terminalState, containsText('id:42'));
      expect(tester.terminalState, containsText('tab:activity'));
      expect(tester.terminalState, containsText('state:opened-from-shell'));

      await router.pop();
      await pumpNavigation(tester);
      expect(tester.terminalState, containsText('Docs Intro'));

      await router.replace('/');
      await pumpNavigation(tester);
      expect(tester.terminalState, containsText('Home'));
    } finally {
      tester.dispose();
    }
  });
}
