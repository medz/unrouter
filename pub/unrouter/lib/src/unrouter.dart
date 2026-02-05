import 'package:flutter/widgets.dart';
import 'package:unrouter/src/router_delegate.dart';
import 'package:unstory/unstory.dart';

import 'route_information_parser.dart';
import 'route_information_provider.dart';

class Unrouter extends StatelessWidget
    implements RouterConfig<HistoryLocation> {
  Unrouter({
    super.key,
    this.restorationScopeId,
    History? history,
    String? base,
    HistoryStrategy strategy = .browser,
  }) : routeInformationProvider = UnrouterRouteInformationProvider(
         history ?? createHistory(base: base, strategy: strategy),
       );

  final String? restorationScopeId;

  @override
  final RouteInformationProvider routeInformationProvider;

  @override
  late final routerDelegate = UnrouterDelegate(this);

  @override
  BackButtonDispatcher? get backButtonDispatcher => throw UnimplementedError();

  @override
  get routeInformationParser => const UnrouterRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return Router.withConfig(
      config: this,
      restorationScopeId: restorationScopeId,
    );
  }
}
