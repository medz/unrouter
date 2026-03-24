import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_unrouter/flutter_unrouter.dart';

Future<void> pumpRouterApp(WidgetTester tester, Unrouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: createRouterConfig(router)),
  );
}
