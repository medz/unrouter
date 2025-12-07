import 'package:flutter/widgets.dart' show BuildContext, Widget;
import 'package:zenrouter/zenrouter.dart';

import 'router.dart';
import 'router_view.dart';
import 'route.dart';
import '_internal/scope.dart';

class RoutePage extends RouteTarget with RouteUnique {
  RoutePage({
    required this.uri,
    required List<RouteMatch> matches,
    required this.router,
  }) : matches = List.unmodifiable(matches);

  final Uri uri;
  final List<RouteMatch> matches;
  final Router router;

  @override
  List<Object?> get props => [uri.toString()];

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    final snapshot = RouteSnapshot(uri: uri, matches: matches);
    return RouterScope(
      router: router,
      route: snapshot,
      child: const RouterView(),
    );
  }

  @override
  Uri toUri() => uri;
}
