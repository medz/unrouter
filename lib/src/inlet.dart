import 'package:flutter/widgets.dart';

import 'guard.dart';

typedef ViewBuilder = ValueGetter<Widget>;

class Inlet {
  const Inlet({
    required this.view,
    this.name,
    this.meta,
    this.path = '/',
    this.children = const [],
    this.guards = const [],
  });

  final String? name;
  final String path;
  final Map<String, Object?>? meta;
  final ViewBuilder view;
  final Iterable<Inlet> children;
  final Iterable<Guard> guards;
}
