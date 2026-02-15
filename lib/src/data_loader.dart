import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

/// Computes reactive async data for a widget [BuildContext].
typedef DataLoader<T> = AsyncData<T> Function(BuildContext context);

/// Fetches a value that can be returned immediately or asynchronously.
typedef DataFetcher<T> = FutureOr<T> Function(BuildContext context);

/// Wraps a [DataFetcher] into a reusable [DataLoader].
///
/// The returned loader is context-aware and automatically disposes internal
/// subscriptions when the hosting widget is unmounted.
DataLoader<T> defineDataLoader<T>(
  /// Callback used to retrieve data for the current [BuildContext].
  DataFetcher<T> fetcher, {

  /// Optional defaults that are exposed before the first fetch completes.
  ValueGetter<T?>? defaults,
}) {
  return (context) {
    final data = useAsyncData(
      context,
      () => fetcher(context),
      defaults: defaults,
    );

    onUnmounted(context, data.dispose);
    return data;
  };
}
