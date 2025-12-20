import 'package:flutter/widgets.dart';

import 'navigation.dart';
import 'router.dart';

extension UnrouterBuildContext on BuildContext {
  Navigate get navigate => Navigate.of(this);
  Unrouter get router => Unrouter.of(this);
}
