import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter_example/main.dart';

void main() {
  testWidgets('push detail returns typed result to home', (tester) async {
    await tester.pumpWidget(UnrouterExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-go-user')));
    await tester.pumpAndSettle();

    expect(find.text('User 42'), findsOneWidget);

    await tester.tap(find.byKey(const Key('user-pop-result')));
    await tester.pumpAndSettle();

    expect(find.text('lastUserResult: 420'), findsOneWidget);
  });

  testWidgets('guard redirects to login and continues after sign in', (
    tester,
  ) async {
    await tester.pumpWidget(UnrouterExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-go-secure')));
    await tester.pumpAndSettle();

    expect(find.text('Sign in required'), findsOneWidget);
    expect(find.byKey(const Key('login-sign-in-continue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('login-sign-in-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('secure-title')), findsOneWidget);
  });

  testWidgets('machine envelope state is shown on home', (tester) async {
    await tester.pumpWidget(UnrouterExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-machine-back')));
    await tester.pumpAndSettle();

    expect(find.text('machineBack: rejected'), findsOneWidget);
  });
}
