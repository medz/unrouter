import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

/// A context-aware async data producer used by Unrouter widgets.
///
/// A data loader is usually created once and called from a widget tree to
/// obtain an [AsyncData] snapshot for the current [BuildContext].
typedef DataLoader<T> = AsyncData<T> Function(BuildContext context);

/// Computes a value for a [BuildContext], synchronously or asynchronously.
///
/// The callback can return either `T` or `Future<T>`.
typedef DataFetcher<T> = FutureOr<T> Function(BuildContext context);

/// Creates a reusable [DataLoader] from a [DataFetcher].
///
/// The returned loader tracks the lifecycle of the calling widget:
/// it subscribes while mounted and disposes internal resources on unmount.
///
/// The optional [defaults] callback provides an initial value that is exposed
/// before the first fetch completes.
///
/// Errors thrown by [fetcher] are captured by [AsyncData] and can be surfaced
/// by the consumer.
///
/// Example:
/// ```dart
/// final userLoader = defineDataLoader<String>(
///   (context) => fetchUserName(context),
///   defaults: () => 'Guest',
/// );
/// ```
DataLoader<T> defineDataLoader<T>(
  DataFetcher<T> fetcher, {
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
