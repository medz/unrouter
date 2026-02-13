import 'package:flutter/widgets.dart';

import 'middleware.dart';

typedef ViewBuilder = ValueGetter<Widget>;

class Inlet<T> {
  const Inlet({
    required this.view,
    this.name,
    this.meta,
    this.path = '/',
    this.children = const {},
    this.middleware = const [],
  });

  final String? name;
  final String path;
  final T? meta;
  final ViewBuilder view;
  final Iterable<Inlet> children;
  final Iterable<Middleware> middleware;
}
