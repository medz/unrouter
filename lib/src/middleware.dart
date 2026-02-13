import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef Next = AsyncValueGetter<Widget>;
typedef Middleware = FutureOr<Widget> Function(BuildContext context, Next next);

Middleware defineMiddleware(Middleware middleware) => middleware;
