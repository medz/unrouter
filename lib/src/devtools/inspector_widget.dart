import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:unstory/unstory.dart';

import '../runtime/navigation.dart';
import '../core/redirect_diagnostics.dart';
import '../core/route_data.dart';

class UnrouterRedirectDiagnosticsStore
    extends ValueNotifier<List<RedirectDiagnostics>> {
  UnrouterRedirectDiagnosticsStore() : super(const <RedirectDiagnostics>[]);

  void add(RedirectDiagnostics diagnostics) {
    value = List<RedirectDiagnostics>.unmodifiable(<RedirectDiagnostics>[
      ...value,
      diagnostics,
    ]);
  }

  void onDiagnostics(RedirectDiagnostics diagnostics) {
    add(diagnostics);
  }

  void clear() {
    if (value.isEmpty) {
      return;
    }
    value = const <RedirectDiagnostics>[];
  }
}

class UnrouterInspectorWidget<R extends RouteData> extends StatefulWidget {
  const UnrouterInspectorWidget({
    super.key,
    required this.inspector,
    this.redirectDiagnostics,
    this.timelineTail = 10,
    this.redirectTrailTail = 5,
    this.machineTimelineTail = 10,
    this.timelineQuery,
    this.timelineResolutions,
    this.timelineActions,
    this.timelineErrorsOnly = false,
    this.redirectQuery,
    this.redirectReasons,
    this.onExport,
    this.exportLabel = 'export report',
    this.exportTimelineTail = 25,
    this.exportRedirectTrailTail = 20,
    this.exportMachineTimelineTail = 20,
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor = const Color(0xFFF6F8FA),
    this.borderColor = const Color(0xFFE1E4E8),
    this.textStyle = const TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: Color(0xFF24292F),
    ),
  }) : assert(
         timelineTail > 0,
         'Unrouter inspector timelineTail must be greater than zero.',
       ),
       assert(
         redirectTrailTail > 0,
         'Unrouter inspector redirectTrailTail must be greater than zero.',
       ),
       assert(
         machineTimelineTail > 0,
         'Unrouter inspector machineTimelineTail must be greater than zero.',
       ),
       assert(
         exportTimelineTail > 0,
         'Unrouter inspector exportTimelineTail must be greater than zero.',
       ),
       assert(
         exportRedirectTrailTail > 0,
         'Unrouter inspector exportRedirectTrailTail must be greater than zero.',
       ),
       assert(
         exportMachineTimelineTail > 0,
         'Unrouter inspector exportMachineTimelineTail must be greater than zero.',
       );

  final UnrouterInspector<R> inspector;
  final ValueListenable<List<RedirectDiagnostics>>? redirectDiagnostics;
  final int timelineTail;
  final int redirectTrailTail;
  final int machineTimelineTail;
  final String? timelineQuery;
  final Set<UnrouterResolutionState>? timelineResolutions;
  final Set<HistoryAction>? timelineActions;
  final bool timelineErrorsOnly;
  final String? redirectQuery;
  final Set<RedirectDiagnosticsReason>? redirectReasons;
  final ValueChanged<String>? onExport;
  final String exportLabel;
  final int exportTimelineTail;
  final int exportRedirectTrailTail;
  final int exportMachineTimelineTail;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final TextStyle textStyle;

  @override
  State<UnrouterInspectorWidget<R>> createState() =>
      _UnrouterInspectorWidgetState<R>();
}

class _UnrouterInspectorWidgetState<R extends RouteData>
    extends State<UnrouterInspectorWidget<R>> {
  late Listenable _listenable = _createListenable();

  @override
  void didUpdateWidget(UnrouterInspectorWidget<R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inspector != widget.inspector ||
        oldWidget.redirectDiagnostics != widget.redirectDiagnostics) {
      _listenable = _createListenable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _listenable,
      builder: (context, child) {
        final redirectDiagnostics =
            widget.redirectDiagnostics?.value ?? const <RedirectDiagnostics>[];
        final report = widget.inspector.debugReport(
          timelineTail: widget.timelineTail,
          redirectDiagnostics: redirectDiagnostics,
          redirectTrailTail: widget.redirectTrailTail,
          machineTimelineTail: widget.machineTimelineTail,
          query: widget.timelineQuery,
          resolutions: widget.timelineResolutions,
          actions: widget.timelineActions,
          includeErrorsOnly: widget.timelineErrorsOnly,
          redirectQuery: widget.redirectQuery,
          redirectReasons: widget.redirectReasons,
        );
        final timelineTail =
            (report['timelineTail'] as List<Object?>?) ?? const <Object?>[];
        final redirectTrail =
            (report['redirectTrailTail'] as List<Object?>?) ??
            const <Object?>[];
        final machineTimeline =
            (report['machineTimelineTail'] as List<Object?>?) ??
            const <Object?>[];

        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: widget.padding,
            child: DefaultTextStyle(
              style: widget.textStyle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'state=${report['resolution']} '
                    'path=${report['routePath'] ?? '-'} '
                    'uri=${report['uri']}',
                  ),
                  Text(
                    'action=${report['lastAction']} '
                    'delta=${report['lastDelta'] ?? '-'} '
                    'index=${report['historyIndex'] ?? '-'} '
                    'type=${report['routeType'] ?? '-'}',
                  ),
                  if (widget.onExport != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      key: const Key('unrouter-inspector-export'),
                      onTap: () {
                        final payload = widget.inspector.exportDebugReportJson(
                          timelineTail: widget.exportTimelineTail,
                          redirectDiagnostics: redirectDiagnostics,
                          redirectTrailTail: widget.exportRedirectTrailTail,
                          machineTimelineTail: widget.exportMachineTimelineTail,
                          query: widget.timelineQuery,
                          resolutions: widget.timelineResolutions,
                          actions: widget.timelineActions,
                          includeErrorsOnly: widget.timelineErrorsOnly,
                          redirectQuery: widget.redirectQuery,
                          redirectReasons: widget.redirectReasons,
                        );
                        widget.onExport!(payload);
                      },
                      child: Text(widget.exportLabel),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'timeline tail ${timelineTail.length}/${report['timelineLength']}',
                  ),
                  ...timelineTail.map((item) => _buildTimelineLine(item)),
                  const SizedBox(height: 8),
                  Text(
                    'redirect trail tail ${redirectTrail.length}/${report['redirectTrailLength']}',
                  ),
                  ...redirectTrail.map(_buildRedirectLine),
                  const SizedBox(height: 8),
                  Text(
                    'machine tail ${machineTimeline.length}/${report['machineTimelineLength']}',
                  ),
                  ...machineTimeline.map(_buildMachineLine),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Listenable _createListenable() {
    final redirect = widget.redirectDiagnostics;
    if (redirect == null) {
      return widget.inspector.stateListenable;
    }
    return Listenable.merge(<Listenable>[
      widget.inspector.stateListenable,
      redirect,
    ]);
  }

  Widget _buildTimelineLine(Object? item) {
    if (item is! Map<String, Object?>) {
      return const Text('-');
    }
    return Text(
      '#${item['sequence']} ${item['resolution']} ${item['uri']} '
      '[${item['lastAction']}/${item['historyIndex'] ?? '-'}]',
    );
  }

  Widget _buildRedirectLine(Object? item) {
    if (item is! Map<String, Object?>) {
      return const Text('-');
    }
    final trailValues = item['trail'];
    final trail = trailValues is List<Object?>
        ? trailValues.join(' -> ')
        : '${trailValues ?? '-'}';
    return Text(
      '${item['reason']} ${item['hop']}/${item['maxHops']} '
      '${item['currentUri']} => ${item['redirectUri']} [$trail]',
    );
  }

  Widget _buildMachineLine(Object? item) {
    if (item is! Map<String, Object?>) {
      return const Text('-');
    }
    final from = item['from'];
    final to = item['to'];
    final fromResolution = from is Map<String, Object?>
        ? from['resolution']
        : '-';
    final toResolution = to is Map<String, Object?> ? to['resolution'] : '-';
    final payload = item['payload'];
    return Text(
      '#${item['sequence']} ${item['source']}:${item['event']} '
      '${item['fromUri'] ?? '-'} => ${item['toUri'] ?? '-'} '
      '[$fromResolution->$toResolution] '
      'payload=${payload ?? '-'}',
    );
  }
}
