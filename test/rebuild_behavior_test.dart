import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

void main() {
  group('Rebuild Behavior', () {
    testWidgets('parent widget rebuilds when navigating between child routes',
        (tester) async {
      var parentBuildCount = 0;
      var childBBuildCount = 0;
      var childCBuildCount = 0;

      // Parent widget that tracks builds
      Widget createParent() {
        return Builder(
          builder: (context) {
            parentBuildCount++;
            return Column(
              children: [
                Text('Parent (built $parentBuildCount times)'),
                Routes([
                  Unroute(path: 'b', factory: () {
                    return Builder(
                      builder: (context) {
                        childBBuildCount++;
                        return Text('Child B (built $childBBuildCount times)');
                      },
                    );
                  }),
                  Unroute(path: 'c', factory: () {
                    return Builder(
                      builder: (context) {
                        childCBuildCount++;
                        return Text('Child C (built $childCBuildCount times)');
                      },
                    );
                  }),
                ]),
              ],
            );
          },
        );
      }

      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: 'a', factory: createParent),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/a/b',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Router.withConfig(config: router),
        ),
      );

      // Initial state: /a/b
      expect(parentBuildCount, 1, reason: 'Parent built once initially');
      expect(childBBuildCount, 1, reason: 'Child B built once initially');
      expect(childCBuildCount, 0, reason: 'Child C not built yet');

      // Navigate to /a/c
      router.push('/a/c');
      await tester.pumpAndSettle();

      // After navigation: /a/c
      print('Parent build count: $parentBuildCount');
      print('Child B build count: $childBBuildCount');
      print('Child C build count: $childCBuildCount');

      expect(find.text('Child C (built 1 times)'), findsOneWidget);
    });

    testWidgets(
        'StatefulWidget parent preserves state when NOT using RouterStateProvider',
        (tester) async {
      var parentInitStateCount = 0;
      var parentBuildCount = 0;

      // StatefulWidget parent
      Widget createParent() {
        return _StatefulParent(
          onInitState: () => parentInitStateCount++,
          onBuild: () => parentBuildCount++,
        );
      }

      late Unrouter router;

      router = Unrouter(
        Routes([
          Unroute(path: 'a', factory: createParent),
        ]),
        mode: HistoryMode.memory,
        initialLocation: '/a/b',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Router.withConfig(config: router),
        ),
      );

      // Initial state
      expect(parentInitStateCount, 1);
      expect(parentBuildCount, 1);

      // Navigate to /a/c
      router.push('/a/c');
      await tester.pumpAndSettle();

      print('Parent initState count: $parentInitStateCount');
      print('Parent build count: $parentBuildCount');

      // What happens? Does State get recreated?
    });
  });
}

class _StatefulParent extends StatefulWidget {
  const _StatefulParent({
    required this.onInitState,
    required this.onBuild,
  });

  final VoidCallback onInitState;
  final VoidCallback onBuild;

  @override
  State<_StatefulParent> createState() => _StatefulParentState();
}

class _StatefulParentState extends State<_StatefulParent> {
  late int counter;

  @override
  void initState() {
    super.initState();
    counter = 0;
    widget.onInitState();
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return Column(
      children: [
        Text('Parent counter: $counter'),
        Routes([
          Unroute(
              path: 'b', factory: () => Text('Child B (counter: $counter)')),
          Unroute(
              path: 'c', factory: () => Text('Child C (counter: $counter)')),
        ]),
      ],
    );
  }
}
