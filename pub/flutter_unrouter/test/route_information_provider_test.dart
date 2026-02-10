import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/src/platform/route_information_provider.dart';
import 'package:unstory/unstory.dart';

void main() {
  test('push, replace and pop keep provider state in sync', () {
    final provider = UnrouterRouteInformationProvider(
      MemoryHistory(
        initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/home'))],
        initialIndex: 0,
      ),
    );
    addTearDown(provider.dispose);

    expect(provider.value.uri.path, '/home');
    expect(provider.lastAction, HistoryAction.pop);
    expect(provider.historyIndex, 0);
    expect(provider.canGoBack, isFalse);

    provider.push(Uri(path: '/profile'), state: const {'p': 1});
    expect(provider.value.uri.path, '/profile');
    expect(provider.value.state, const {'p': 1});
    expect(provider.lastAction, HistoryAction.push);
    expect(provider.lastDelta, isNull);
    expect(provider.historyIndex, 1);
    expect(provider.canGoBack, isTrue);

    provider.replace(Uri(path: '/profile/edit'), state: const {'edit': true});
    expect(provider.value.uri.path, '/profile/edit');
    expect(provider.value.state, const {'edit': true});
    expect(provider.lastAction, HistoryAction.replace);
    expect(provider.historyIndex, 1);

    provider.back();
    expect(provider.value.uri.path, '/home');
    expect(provider.lastAction, HistoryAction.pop);
    expect(provider.lastDelta, -1);
    expect(provider.historyIndex, 0);
  });

  test('routerReportsNewRouteInformation handles navigate/neglect/none', () {
    final provider = UnrouterRouteInformationProvider(
      MemoryHistory(
        initialEntries: <HistoryLocation>[HistoryLocation(Uri(path: '/a'))],
        initialIndex: 0,
      ),
    );
    addTearDown(provider.dispose);

    provider.routerReportsNewRouteInformation(
      RouteInformation(
        uri: Uri(path: '/b'),
        state: const {'n': 1},
      ),
      type: RouteInformationReportingType.navigate,
    );
    expect(provider.value.uri.path, '/b');
    expect(provider.value.state, const {'n': 1});
    expect(provider.lastAction, HistoryAction.push);
    expect(provider.historyIndex, 1);

    provider.routerReportsNewRouteInformation(
      RouteInformation(
        uri: Uri(path: '/c'),
        state: const {'r': 2},
      ),
      type: RouteInformationReportingType.neglect,
    );
    expect(provider.value.uri.path, '/c');
    expect(provider.value.state, const {'r': 2});
    expect(provider.lastAction, HistoryAction.replace);
    expect(provider.historyIndex, 1);

    provider.routerReportsNewRouteInformation(
      RouteInformation(
        uri: Uri(path: '/memory-only'),
        state: const {'x': 9},
      ),
      type: RouteInformationReportingType.none,
    );
    expect(provider.value.uri.path, '/memory-only');
    expect(provider.value.state, const {'x': 9});
    expect(provider.history.location.uri.path, '/c');
  });
}
