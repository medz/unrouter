import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

Widget emptyView() => const SizedBox.shrink();
Widget altEmptyView() => const SizedBox();
Widget textView(String value) => Text(value, textDirection: TextDirection.ltr);

Future<void> flushAsyncQueue({
  Duration delay = const Duration(milliseconds: 20),
}) async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(delay);
  await Future<void>.delayed(Duration.zero);
}

MemoryHistory createMemoryHistory(List<String> paths, {int? initialIndex}) {
  return MemoryHistory(
    initialEntries: paths
        .map((path) => HistoryLocation(Uri(path: path)))
        .toList(growable: false),
    initialIndex: initialIndex,
  );
}
