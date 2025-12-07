import 'package:flutter/widgets.dart' show BuildContext;

import '_internal/scope.dart';
import 'route.dart';
import 'router.dart';

Router useRouter(BuildContext context) => RouterScope.of(context).router;

RouteSnapshot useRoute(BuildContext context) =>
    RouterScope.of(context, aspect: .route).route;

Map<String, String> useRouterParams(BuildContext context) =>
    RouterScope.of(context, aspect: .params).route.params;

Map<String, String> useQueryParams(BuildContext context) =>
    RouterScope.of(context, aspect: .query).route.query;
