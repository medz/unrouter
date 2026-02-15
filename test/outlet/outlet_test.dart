import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';

void main() {
  group('outlet', () {
    testWidgets('renders nested child view by depth', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: OutletScope(
            views: [() => const Outlet(), () => const Text('Leaf View')],
            depth: 0,
            child: const Outlet(),
          ),
        ),
      );

      expect(find.text('Leaf View'), findsOneWidget);
    });

    testWidgets('returns shrink when depth exceeds views', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: OutletScope(
            views: [emptyView],
            depth: 1,
            child: const Outlet(),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.text('Leaf View'), findsNothing);
    });

    testWidgets('throws when used outside OutletScope', (tester) async {
      await tester.pumpWidget(
        const Directionality(textDirection: TextDirection.ltr, child: Outlet()),
      );

      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(
        error.toString(),
        contains('Outlet must be used inside a router view'),
      );
    });
  });
}
