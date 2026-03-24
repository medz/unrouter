import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class AltEmptyView extends StatelessWidget {
  const AltEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

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
