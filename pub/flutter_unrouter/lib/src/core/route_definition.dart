import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:unrouter/unrouter.dart'
    as core
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
        ShellBranchDescriptor,
        ShellCoordinator,
        ShellHistoryStateRequest,
        ShellNavigationEvent;
import 'package:unstory/unstory.dart';

import '../runtime/navigation.dart';
import 'route_data.dart';

part 'route_definition_records.dart';
part 'route_definition_shell.dart';

typedef CoreRouteRecord<T extends RouteData> = core.RouteRecord<T>;
typedef _CoreRouteRecord<T extends RouteData> = core.RouteRecord<T>;
typedef _CoreRouteDefinition<T extends RouteData> = core.RouteDefinition<T>;
typedef _CoreLoadedRouteDefinition<T extends RouteData, L> =
    core.LoadedRouteDefinition<T, L>;
typedef _CoreRouteGuard<T extends RouteData> = core.RouteGuard<T>;
typedef _CoreRouteRedirect<T extends RouteData> = core.RouteRedirect<T>;
typedef _CoreRouteLoader<T extends RouteData, L> = core.RouteLoader<T, L>;
typedef _CoreRouteParser<T extends RouteData> = core.RouteParser<T>;
typedef _CoreRouteGuardResult = core.RouteGuardResult;
typedef _CoreRouteParserState = core.RouteParserState;
typedef _CoreRouteHookContext<T extends RouteData> = core.RouteHookContext<T>;
typedef _CoreShellCoordinator = core.ShellCoordinator;
typedef _CoreShellBranchDescriptor = core.ShellBranchDescriptor;
typedef _CoreShellHistoryStateRequest = core.ShellHistoryStateRequest;
typedef _CoreShellNavigationEvent = core.ShellNavigationEvent;
