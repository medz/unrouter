import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';

class _OutletLayout extends StatelessWidget {
  const _OutletLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Outlet();
  }
}

class _LeafView extends StatelessWidget {
  const _LeafView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Leaf View');
  }
}

void main() {
  group('outlet', () {
    testWidgets('renders nested child view by depth', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: OutletScope(
            views: [_OutletLayout.new, _LeafView.new],
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
            views: [EmptyView.new],
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
        const Directionality(
          textDirection: TextDirection.ltr,
          child: const Outlet(),
        ),
      );

      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(
        error.toString(),
        contains('Outlet must be used inside a routed view'),
      );
    });
  });
}
