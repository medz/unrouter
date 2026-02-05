import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

import 'route_infoirmation_provider.dart';

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
  RouteInformationProvider routeInformationProvider;

  @override
  BackButtonDispatcher? get backButtonDispatcher => throw UnimplementedError();

  @override
  RouteInformationParser<HistoryLocation>? get routeInformationParser =>
      throw UnimplementedError();

  @override
  RouterDelegate<HistoryLocation> get routerDelegate =>
      throw UnimplementedError();

  @override
  Widget build(BuildContext context) {
    return Router.withConfig(
      config: this,
      restorationScopeId: restorationScopeId,
    );
  }
}
