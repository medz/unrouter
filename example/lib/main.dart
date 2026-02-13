import 'package:unrouter/unrouter.dart';

final router = Unrouter(
  routes: [
    Inlet(
      view: () => throw UnimplementedError(),
      children: [
        Inlet(view: () => throw UnimplementedError()),
        Inlet(view: () => throw UnimplementedError()),
      ],
    ),
  ],
);
