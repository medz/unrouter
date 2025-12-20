import '../route_matcher.dart';

Map<String, String> resolveParamsForLevel(
  List<MatchedRoute> matchedRoutes,
  int level,
) {
  final result = <String, String>{};
  for (var i = 0; i <= level && i < matchedRoutes.length; i++) {
    result.addAll(matchedRoutes[i].params);
  }
  return result;
}
