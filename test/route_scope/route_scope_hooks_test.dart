import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unstory/unstory.dart';
import 'package:unrouter/unrouter.dart';

import '../support/fakes.dart';

RouteRecord _record({Map<String, Object?>? meta}) {
  return RouteRecord(
    views: [EmptyView.new],
    guards: const <Guard>[],
    meta: meta,
  );
}

void main() {
  group('route scope hooks', () {
    testWidgets('reads all route hooks from provider', (tester) async {
      final location = HistoryLocation(
        Uri(path: '/users/42', query: 'q=abc'),
        'state-value',
      );
      final from = HistoryLocation(Uri(path: '/list'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteScopeProvider(
            route: _record(meta: const {'role': 'admin'}),
            params: const RouteParams({'id': '42'}),
            location: location,
            query: URLSearchParams(location.query),
            fromLocation: from,
            child: Builder(
              builder: (context) {
                final meta = useRouteMeta(context);
                final params = useRouteParams(context);
                final query = useQuery(context);
                final uri = useRouteURI(context);
                final current = useLocation(context);
                final previous = useFromLocation(context);
                final state = useRouteState<String>(context);

                return Text(
                  'meta:${meta['role']};id:${params.required('id')};q:${query.get('q')};uri:${uri.path};loc:${current.path};from:${previous?.path};state:$state',
                );
              },
            ),
          ),
        ),
      );

      expect(
        find.text(
          'meta:admin;id:42;q:abc;uri:/users/42;loc:/users/42;from:/list;state:state-value',
        ),
        findsOneWidget,
      );
    });

    testWidgets('throws when used outside RouteScopeProvider', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              useQuery(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(
        error.toString(),
        contains('Unrouter query is unavailable in this BuildContext'),
      );
    });

    testWidgets('throws when route state type does not match', (tester) async {
      final location = HistoryLocation(Uri(path: '/users/42'), 42);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteScopeProvider(
            route: _record(),
            params: const RouteParams({'id': '42'}),
            location: location,
            query: URLSearchParams(location.query),
            child: Builder(
              builder: (context) {
                useRouteState<String>(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(
        error.toString(),
        contains('Unrouter state is of unexpected type'),
      );
    });

    testWidgets('returns null when route state is absent', (tester) async {
      final location = HistoryLocation(Uri(path: '/users/42'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RouteScopeProvider(
            route: _record(),
            params: const RouteParams({'id': '42'}),
            location: location,
            query: URLSearchParams(location.query),
            child: Builder(
              builder: (context) {
                final state = useRouteState<String>(context);
                return Text('state:${state ?? 'null'}');
              },
            ),
          ),
        ),
      );

      expect(find.text('state:null'), findsOneWidget);
    });

    testWidgets('updates hook values after location changes', (tester) async {
      final step = ValueNotifier(0);
      final firstLocation = HistoryLocation(Uri(path: '/a', query: 'q=1'));
      final secondLocation = HistoryLocation(Uri(path: '/b', query: 'q=2'));

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ValueListenableBuilder<int>(
            valueListenable: step,
            builder: (context, value, _) {
              final location = value == 0 ? firstLocation : secondLocation;
              final from = value == 0 ? null : firstLocation;
              return RouteScopeProvider(
                route: _record(),
                params: const RouteParams({'id': 'x'}),
                location: location,
                query: URLSearchParams(location.query),
                fromLocation: from,
                child: Builder(
                  builder: (context) {
                    final uri = useRouteURI(context);
                    final previous = useFromLocation(context);
                    final query = useQuery(context);
                    return Text(
                      'uri:${uri.path};from:${previous?.path ?? 'null'};q:${query.get('q')}',
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('uri:/a;from:null;q:1'), findsOneWidget);

      step.value = 1;
      await tester.pump();

      expect(find.text('uri:/b;from:/a;q:2'), findsOneWidget);
    });
  });
}
