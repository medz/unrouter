import 'package:flutter/widgets.dart';

import 'middleware.dart';

class Inlet {
  const Inlet({
    required this.view,
    this.name,
    this.path = '/',
    this.children = const {},
    this.middleware = const [],
  });

  final String? name;
  final String path;
  final ValueGetter<Widget> view;
  final Iterable<Inlet> children;
  final Iterable<Middleware> middleware;
}
