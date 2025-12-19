import 'package:flutter/widgets.dart';

import 'router.dart';

extension UnrouterNavigationContext on BuildContext {
  Navigate get navigate => Navigate.of(this);
  Unrouter get router => Unrouter.of(this);
}
