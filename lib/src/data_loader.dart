import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:oref/oref.dart';

typedef DataLoader<T> = AsyncData<T> Function(BuildContext context);
typedef DataFetcher<T> = FutureOr<T> Function(BuildContext context);

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
