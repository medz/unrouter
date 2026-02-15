import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/oref.dart';
import 'package:unrouter/unrouter.dart';

class _LoaderProbe<T> extends StatelessWidget {
  const _LoaderProbe({required this.loader, required this.onData});

  final DataLoader<T> loader;
  final void Function(AsyncData<T> data) onData;

  @override
  Widget build(BuildContext context) {
    final data = loader(context);
    onData(data);

    final label = data.when<String>(
      context: context,
      idle: (value) => 'idle:$value',
      pending: (value) => 'pending:$value',
      success: (value) => 'success:$value',
      error: (error) => 'error:${error?.error}',
    );

    return Text(label);
  }
}

void main() {
  group('defineDataLoader', () {
    testWidgets('starts with defaults and resolves to success', (tester) async {
      AsyncData<int>? latest;
      final statuses = <AsyncStatus>[];

      final loader = defineDataLoader<int>((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return 42;
      }, defaults: () => 10);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _LoaderProbe<int>(
            loader: loader,
            onData: (data) {
              latest = data;
              statuses.add(data.status);
            },
          ),
        ),
      );

      expect(latest, isNotNull);
      expect(latest!.status, anyOf([AsyncStatus.idle, AsyncStatus.pending]));
      expect(latest!.data, 10);

      await tester.pump(const Duration(milliseconds: 30));

      expect(latest!.status, AsyncStatus.success);
      expect(latest!.data, 42);
      expect(statuses, contains(AsyncStatus.idle));
      expect(statuses, contains(AsyncStatus.success));
    });

    testWidgets('handles error state', (tester) async {
      AsyncData<int>? latest;

      final loader = defineDataLoader<int>((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw StateError('fetch failed');
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _LoaderProbe<int>(
            loader: loader,
            onData: (data) => latest = data,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 30));

      expect(latest, isNotNull);
      expect(latest!.status, AsyncStatus.error);
      expect(latest!.error, isNotNull);
      expect(latest!.error!.error.toString(), contains('fetch failed'));
    });

    testWidgets('refresh triggers a new fetch', (tester) async {
      AsyncData<int>? latest;
      var count = 0;

      final loader = defineDataLoader<int>((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        count += 1;
        return count;
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _LoaderProbe<int>(
            loader: loader,
            onData: (data) => latest = data,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 20));
      expect(latest!.data, 1);

      final refreshTask = latest!.refresh();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final refreshed = await refreshTask.timeout(
        const Duration(milliseconds: 500),
      );
      expect(latest!.status, AsyncStatus.success);
      expect(latest!.data, 2);
      expect(refreshed, 2);
    });

    testWidgets('disposes subscriptions after unmount', (tester) async {
      AsyncData<int>? latest;
      var count = 0;
      final trigger = signal(null, 0);

      final loader = defineDataLoader<int>((_) async {
        trigger();
        count += 1;
        await Future<void>.delayed(const Duration(milliseconds: 1));
        return count;
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _LoaderProbe<int>(
            loader: loader,
            onData: (data) => latest = data,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 20));
      expect(count, 1);
      expect(latest!.data, 1);

      trigger.set(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(count, 2);
      expect(latest!.data, 2);

      await tester.pumpWidget(const SizedBox.shrink());
      trigger.set(2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(count, 2);
    });
  });
}
