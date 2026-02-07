import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart'
    show RouteGuardResult, RouteHookContext, RouteParserState, runRouteGuards;
import 'package:unrouter/unrouter.dart' as core show RouteRecord;
import 'package:unstory/unstory.dart';

import '../runtime/navigation.dart';
import 'route_data.dart';

part 'route_definition_records.dart';
part 'route_definition_shell.dart';

typedef _CoreRouteRecord<T extends RouteData> = core.RouteRecord<T>;
