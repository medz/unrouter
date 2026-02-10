import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';
import 'package:unrouter/unrouter.dart' as core;

void main() {
  testWidgets('UnrouterScope provides controller through context helpers', (
    tester,
  ) async {
    final controller = core.UnrouterController<AppRoute>(
      router: core.Unrouter<AppRoute>(
        routes: <core.RouteRecord<AppRoute>>[
          core.route<AppRoute>(
            path: '/home',
            parse: (_) => const AppRoute('/home'),
          ),
        ],
      ),
      resolveInitialRoute: false,
    );
    addTearDown(controller.dispose);
    final scopeController = controller.cast<core.RouteData>();

    core.UnrouterController<core.RouteData>? untyped;
    core.UnrouterController<AppRoute>? typed;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: UnrouterScope(
          controller: scopeController,
          child: Builder(
            builder: (context) {
              untyped = context.unrouter;
              typed = context.unrouterAs<AppRoute>();
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(untyped, isNotNull);
    expect(typed, isNotNull);
    expect(untyped, same(scopeController));
    expect(untyped?.href(const AppRoute('/home')), '/home');
    expect(typed?.href(const AppRoute('/home')), '/home');
  });

  testWidgets('UnrouterScope.of throws when scope is missing', (tester) async {
    Object? error;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            try {
              context.unrouter;
            } catch (caught) {
              error = caught;
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(error, isA<FlutterError>());
    expect('$error', contains('UnrouterScope was not found in context.'));
  });
}

final class AppRoute implements core.RouteData {
  const AppRoute(this.path);

  final String path;

  @override
  Uri toUri() => Uri(path: path);
}
