import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter_example/main.dart';

void main() {
  testWidgets('push detail returns typed result to home', (tester) async {
    await tester.pumpWidget(const UnrouterExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-open-post')));
    await tester.pumpAndSettle();

    expect(find.text('Result demo 101'), findsOneWidget);

    await tester.tap(find.byKey(const Key('result-pop-result')));
    await tester.pumpAndSettle();

    expect(find.text('lastPostResult: 1010'), findsOneWidget);
  });

  testWidgets('guard redirects to login and continues after sign in', (
    tester,
  ) async {
    await tester.pumpWidget(const UnrouterExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-go-profile-branch')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profile-open-secure')));
    await tester.pumpAndSettle();

    expect(find.text('Sign in required'), findsOneWidget);
    expect(find.byKey(const Key('login-sign-in-continue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-sign-in-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('secure-profile-title')), findsOneWidget);
  });

  testWidgets('debug center opens and panel renders', (tester) async {
    await tester.pumpWidget(const UnrouterExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('shell-open-debug')));
    await tester.pumpAndSettle();

    expect(find.text('Debug Center'), findsOneWidget);
    expect(find.byKey(const Key('debug-panel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('debug-manual-emit')));
    await tester.pump();

    expect(find.textContaining('status:'), findsOneWidget);
  });
}
