import 'package:flutter/widgets.dart' show BuildContext;
import '_internal/scope.dart';
import 'route.dart';
import 'router_base.dart';

Router useRouter(BuildContext context) => RouterScope.of(context).router;

RouteSnapshot useRoute(BuildContext context) => RouterScope.of(context).route;

Map<String, String> useRouterParams(BuildContext context) =>
    useRoute(context).params;

Map<String, String> useQueryParams(BuildContext context) =>
    useRoute(context).query;
