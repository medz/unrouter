import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unrouter/unrouter.dart';

Future<void> pumpRouterApp(WidgetTester tester, Unrouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: createRouterConfig(router)),
  );
}
