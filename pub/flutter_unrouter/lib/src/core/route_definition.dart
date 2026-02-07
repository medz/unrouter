import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart'
    show
        RouteData,
        RouteGuardResult,
        RouteHookContext,
        RouteParserState,
        runRouteGuards;
import 'package:unstory/unstory.dart';

import '../runtime/navigation.dart';

part 'route_definition_records.dart';
part 'route_definition_shell.dart';
