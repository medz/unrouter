import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart' show RouteData;
import 'package:unrouter/unrouter.dart'
    as unrouter_core
    show
        LoadedRouteDefinition,
        RouteDefinition,
        RouteGuard,
        RouteGuardResult,
        RouteHookContext,
        RouteLoader,
        RouteParser,
        RouteParserState,
        RouteRecord,
        RouteRedirect,
        ShellBranch,
        ShellRuntimeBinding,
        branch;

import '../runtime/navigation.dart';

part 'route_definition_records.dart';
part 'route_definition_shell.dart';
