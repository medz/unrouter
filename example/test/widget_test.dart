import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter_example/main.dart';

void main() {
  testWidgets('renders example home', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Unrouter Examples'), findsOneWidget);
    expect(find.text('Open Quickstart'), findsOneWidget);
    expect(find.text('Open Advanced'), findsOneWidget);
  });
}
