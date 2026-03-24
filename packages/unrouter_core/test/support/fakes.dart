import 'package:test/test.dart';

Object emptyView() => Object();

Object altEmptyView() => Object();

Future<void> flushAsyncQueue({
  Duration delay = const Duration(milliseconds: 20),
}) async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(delay);
  await Future<void>.delayed(Duration.zero);
}

Matcher throwsStateErrorContaining(String text) {
  return throwsA(
    isA<StateError>().having(
      (error) => error.toString(),
      'toString',
      contains(text),
    ),
  );
}

Matcher throwsArgumentErrorContaining(String text) {
  return throwsA(
    isA<ArgumentError>().having(
      (error) => error.toString(),
      'toString',
      contains(text),
    ),
  );
}
