import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter_example/main.dart';

void main() {
  setUp(() async {
    await exampleRouter.replace('/');
  });

  testWidgets('renders example home', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Unrouter Examples'), findsOneWidget);
    expect(find.text('Open Quickstart'), findsOneWidget);
    expect(find.text('Open Advanced'), findsOneWidget);
  });

  testWidgets('opens advanced example without route mismatch error', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    await tester.tap(find.text('Open Advanced'));
    await tester.pumpAndSettle();

    expect(find.text('Advanced - Sign In'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
