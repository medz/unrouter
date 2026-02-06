import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'inspector_bridge.dart';
import 'inspector_panel_adapter.dart';
import 'inspector_replay_compare.dart';
import 'inspector_replay_controller.dart';
import 'inspector_replay_store.dart';
import '../runtime/navigation.dart';

part 'inspector_panel_widget_state_methods.dart';

/// Rich diagnostics panel widget for inspector bridge emissions and replay data.
class UnrouterInspectorPanelWidget extends StatefulWidget {
  UnrouterInspectorPanelWidget({
    super.key,
    required this.panel,
    this.replayController,
    this.replayDiff,
    this.highlightReplayDiff = true,
    this.query,
    this.reasons,
    this.initialMachineEventGroups,
    this.onMachineEventGroupsChanged,
    this.initialMachinePayloadKinds,
    this.onMachinePayloadKindsChanged,
    this.maxVisibleEntries = 80,
    this.timelineMarkerLimit = 60,
    this.timelineZoomFactors = const <int>[1, 2, 4, 8],
    this.initialTimelineZoomIndex = 0,
    this.listHeight = 220,
    this.compareListHeight = 120,
    this.compareRowLimit = 32,
    this.enableCompareCluster = true,
    this.initialCompareCollapsed = false,
    this.initialCompareClustersCollapsed = false,
    this.initialCompareHighRiskOnly = false,
    this.initialTimelineDiffOnly = false,
    this.compactBreakpoint = 720,
    this.onClear,
    this.onExportSelected,
    this.clearLabel = 'clear',
    this.prevLabel = 'prev',
    this.nextLabel = 'next',
    this.latestLabel = 'latest',
    this.exportLabel = 'export selected',
    this.playLabel = 'play',
    this.pauseLabel = 'pause',
    this.resumeLabel = 'resume',
    this.stopLabel = 'stop',
    this.speedLabel = 'speed',
    this.bookmarkLabel = 'bookmark',
    this.zoomInLabel = 'zoom+',
    this.zoomOutLabel = 'zoom-',
    this.compareLabel = 'session-compare',
    this.compareBaselineLabel = 'baseline',
    this.compareCurrentLabel = 'current',
    this.compareCollapseLabel = 'compare-hide',
    this.compareExpandLabel = 'compare-show',
    this.compareClusterExpandLabel = 'cluster+',
    this.compareClusterCollapseLabel = 'cluster-',
    this.compareHighRiskOnlyLabel = 'risk-only',
    this.compareAllClustersLabel = 'risk-all',
    this.compareNextHighRiskLabel = 'risk-next',
    this.replayValidationNextLabel = 'replay-issue-next',
    this.timelineDiffOnlyLabel = 'timeline-diff',
    this.timelineAllLabel = 'timeline-all',
    this.padding = const EdgeInsets.all(12),
    this.backgroundColor = const Color(0xFFF6F8FA),
    this.borderColor = const Color(0xFFE1E4E8),
    this.headerTextStyle = const TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: Color(0xFF24292F),
      fontWeight: FontWeight.w600,
    ),
    this.entryTextStyle = const TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: Color(0xFF24292F),
    ),
    this.detailTextStyle = const TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: Color(0xFF24292F),
    ),
  }) : assert(
         maxVisibleEntries > 0,
         'Unrouter inspector panel maxVisibleEntries must be greater than zero.',
       ),
       assert(
         timelineMarkerLimit > 0,
         'Unrouter inspector panel timelineMarkerLimit must be greater than zero.',
       ),
       assert(
         timelineZoomFactors.isNotEmpty,
         'Unrouter inspector panel timelineZoomFactors must not be empty.',
       ),
       assert(
         timelineZoomFactors.every((value) => value > 0),
         'Unrouter inspector panel timelineZoomFactors must contain positive values.',
       ),
       assert(
         initialTimelineZoomIndex >= 0 &&
             initialTimelineZoomIndex < timelineZoomFactors.length,
         'Unrouter inspector panel initialTimelineZoomIndex is out of range.',
       ),
       assert(
         listHeight > 0,
         'Unrouter inspector panel listHeight must be greater than zero.',
       ),
       assert(
         compareListHeight > 0,
         'Unrouter inspector panel compareListHeight must be greater than zero.',
       ),
       assert(
         compareRowLimit > 0,
         'Unrouter inspector panel compareRowLimit must be greater than zero.',
       ),
       assert(
         compactBreakpoint > 0,
         'Unrouter inspector panel compactBreakpoint must be greater than zero.',
       );

  final UnrouterInspectorPanelAdapter panel;
  final UnrouterInspectorReplayController? replayController;
  final UnrouterInspectorReplaySessionDiff? replayDiff;
  final bool highlightReplayDiff;
  final String? query;
  final Set<UnrouterInspectorEmissionReason>? reasons;
  final Set<UnrouterMachineEventGroup>? initialMachineEventGroups;
  final ValueChanged<Set<UnrouterMachineEventGroup>?>?
  onMachineEventGroupsChanged;
  final Set<UnrouterMachineTypedPayloadKind>? initialMachinePayloadKinds;
  final ValueChanged<Set<UnrouterMachineTypedPayloadKind>?>?
  onMachinePayloadKindsChanged;
  final int maxVisibleEntries;
  final int timelineMarkerLimit;
  final List<int> timelineZoomFactors;
  final int initialTimelineZoomIndex;
  final double listHeight;
  final double compareListHeight;
  final int compareRowLimit;
  final bool enableCompareCluster;
  final bool initialCompareCollapsed;
  final bool initialCompareClustersCollapsed;
  final bool initialCompareHighRiskOnly;
  final bool initialTimelineDiffOnly;
  final double compactBreakpoint;
  final VoidCallback? onClear;
  final ValueChanged<String>? onExportSelected;
  final String clearLabel;
  final String prevLabel;
  final String nextLabel;
  final String latestLabel;
  final String exportLabel;
  final String playLabel;
  final String pauseLabel;
  final String resumeLabel;
  final String stopLabel;
  final String speedLabel;
  final String bookmarkLabel;
  final String zoomInLabel;
  final String zoomOutLabel;
  final String compareLabel;
  final String compareBaselineLabel;
  final String compareCurrentLabel;
  final String compareCollapseLabel;
  final String compareExpandLabel;
  final String compareClusterExpandLabel;
  final String compareClusterCollapseLabel;
  final String compareHighRiskOnlyLabel;
  final String compareAllClustersLabel;
  final String compareNextHighRiskLabel;
  final String replayValidationNextLabel;
  final String timelineDiffOnlyLabel;
  final String timelineAllLabel;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final TextStyle headerTextStyle;
  final TextStyle entryTextStyle;
  final TextStyle detailTextStyle;

  @override
  State<UnrouterInspectorPanelWidget> createState() =>
      _UnrouterInspectorPanelWidgetState();
}

class _UnrouterInspectorPanelWidgetState
    extends State<UnrouterInspectorPanelWidget> {
  late int _timelineZoomIndex = widget.initialTimelineZoomIndex;
  late bool _compareCollapsed = widget.initialCompareCollapsed;
  late bool _compareHighRiskOnly = widget.initialCompareHighRiskOnly;
  late bool _timelineDiffOnly = widget.initialTimelineDiffOnly;
  late Set<UnrouterMachineEventGroup> _machineEventGroups =
      _copyMachineEventGroupFilter(widget.initialMachineEventGroups);
  late Set<UnrouterMachineTypedPayloadKind> _machinePayloadKinds =
      _copyMachinePayloadKindFilter(widget.initialMachinePayloadKinds);
  Set<UnrouterInspectorReplayValidationSeverity> _replayValidationSeverities =
      <UnrouterInspectorReplayValidationSeverity>{};
  Set<UnrouterInspectorReplayValidationIssueCode> _replayValidationCodes =
      <UnrouterInspectorReplayValidationIssueCode>{};
  final Set<int> _collapsedCompareClusters = <int>{};
  bool _compareClusterStateInitialized = false;

  int get _timelineStride => widget.timelineZoomFactors[_timelineZoomIndex];

  void _setState(VoidCallback callback) {
    setState(callback);
  }

  @override
  void didUpdateWidget(UnrouterInspectorPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timelineZoomFactors != widget.timelineZoomFactors) {
      if (_timelineZoomIndex >= widget.timelineZoomFactors.length) {
        _timelineZoomIndex = widget.timelineZoomFactors.length - 1;
      }
      if (_timelineZoomIndex < 0) {
        _timelineZoomIndex = 0;
      }
    }
    if (oldWidget.initialCompareClustersCollapsed !=
        widget.initialCompareClustersCollapsed) {
      _compareClusterStateInitialized = false;
      _collapsedCompareClusters.clear();
    }
    if (oldWidget.initialCompareHighRiskOnly !=
        widget.initialCompareHighRiskOnly) {
      _compareHighRiskOnly = widget.initialCompareHighRiskOnly;
    }
    if (!_sameMachineEventGroupSet(
      oldWidget.initialMachineEventGroups,
      widget.initialMachineEventGroups,
    )) {
      _machineEventGroups = _copyMachineEventGroupFilter(
        widget.initialMachineEventGroups,
      );
    }
    if (!_sameMachinePayloadKindSet(
      oldWidget.initialMachinePayloadKinds,
      widget.initialMachinePayloadKinds,
    )) {
      _machinePayloadKinds = _copyMachinePayloadKindFilter(
        widget.initialMachinePayloadKinds,
      );
    }
    if (!widget.enableCompareCluster) {
      _collapsedCompareClusters.clear();
      _compareClusterStateInitialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final replay = widget.replayController;
    final animation = replay == null
        ? widget.panel
        : Listenable.merge(<Listenable>[widget.panel, replay]);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final filtered = _filterEntries(widget.panel.value.entries);
        final visible = filtered.length > widget.maxVisibleEntries
            ? filtered.sublist(filtered.length - widget.maxVisibleEntries)
            : filtered;
        final selected = widget.panel.value.selectedEntry;
        final replayState = replay?.value;
        final replayValidation = replay?.store.validateCompatibility();
        final replayValidationIssues = replayValidation == null
            ? const <UnrouterInspectorReplayValidationIssue>[]
            : _filterReplayValidationIssues(replayValidation.issues);
        final replayValidationErrorCount = replayValidationIssues
            .where(
              (issue) =>
                  issue.severity ==
                  UnrouterInspectorReplayValidationSeverity.error,
            )
            .length;
        final replayValidationWarningCount = replayValidationIssues
            .where(
              (issue) =>
                  issue.severity ==
                  UnrouterInspectorReplayValidationSeverity.warning,
            )
            .length;
        final replayValidationCodeCounts = _countReplayValidationIssuesByCode(
          replayValidationIssues,
        );
        final replayDiff = widget.highlightReplayDiff
            ? widget.replayDiff
            : null;
        final compareClusters = replayDiff == null
            ? const <_CompareDiffCluster>[]
            : _buildCompareClustersForDiff(replayDiff);
        final diffBySequence = _buildDiffBySequence(replayDiff);
        final diffByPath = _buildDiffByPath(replayDiff);
        final timelineEntries = _resolveTimelineEntries(
          visible,
          diffBySequence: diffBySequence,
          diffByPath: diffByPath,
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: widget.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: widget.padding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < widget.compactBreakpoint;
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'entries=${widget.panel.value.entries.length}/${widget.panel.value.maxEntries} '
                        'emitted=${widget.panel.value.emittedCount} '
                        'dropped=${widget.panel.value.droppedCount} '
                        'visible=${visible.length}',
                        style: widget.headerTextStyle,
                      ),
                      Text(
                        'timelineZoom=${_timelineStride}x '
                        'markers=${_resolveMarkerCount(timelineEntries.length)} '
                        'filter=${_timelineDiffOnly ? 'diff' : 'all'}',
                        style: widget.headerTextStyle,
                      ),
                      Text(
                        'machineGroups=${_describeMachineEventGroupFilter()}',
                        style: widget.headerTextStyle,
                      ),
                      Text(
                        'machineKinds=${_describeMachinePayloadKindFilter()}',
                        style: widget.headerTextStyle,
                      ),
                      if (replayValidation != null)
                        Text(
                          'replayValidation issues=${replayValidation.issues.length} '
                          'errors=${replayValidation.errorCount} '
                          'warnings=${replayValidation.warningCount}',
                          style: widget.headerTextStyle,
                        ),
                      if (replayValidation != null)
                        Text(
                          'replayValidationSelected issues=${replayValidationIssues.length} '
                          'errors=$replayValidationErrorCount '
                          'warnings=$replayValidationWarningCount '
                          'severities=${_describeReplayValidationSeverityFilter()} '
                          'codes=${_describeReplayValidationCodeFilter()}',
                          style: widget.headerTextStyle,
                        ),
                      if (replayValidation != null)
                        Text(
                          'replayValidationCodes '
                          'machineTimelineMalformed=${replayValidationCodeCounts[UnrouterInspectorReplayValidationIssueCode.machineTimelineMalformed] ?? 0} '
                          'actionEnvelopeSchemaIncompatible=${replayValidationCodeCounts[UnrouterInspectorReplayValidationIssueCode.actionEnvelopeSchemaIncompatible] ?? 0} '
                          'actionEnvelopeEventIncompatible=${replayValidationCodeCounts[UnrouterInspectorReplayValidationIssueCode.actionEnvelopeEventIncompatible] ?? 0} '
                          'actionEnvelopeFailureMissing=${replayValidationCodeCounts[UnrouterInspectorReplayValidationIssueCode.actionEnvelopeFailureMissing] ?? 0} '
                          'controllerLifecycleCoverageMissing=${replayValidationCodeCounts[UnrouterInspectorReplayValidationIssueCode.controllerLifecycleCoverageMissing] ?? 0}',
                          style: widget.headerTextStyle,
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildAction(
                            key: const Key('unrouter-panel-machine-group-all'),
                            label: _machineEventGroups.isEmpty
                                ? 'machine:all*'
                                : 'machine:all',
                            onTap: _clearMachineEventGroupFilter,
                          ),
                          ...UnrouterMachineEventGroup.values.map(
                            (group) => _buildAction(
                              key: Key(
                                'unrouter-panel-machine-group-${group.name}',
                              ),
                              label: _formatMachineEventGroupLabel(group),
                              onTap: () => _toggleMachineEventGroup(group),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildAction(
                            key: const Key('unrouter-panel-machine-kind-all'),
                            label: _machinePayloadKinds.isEmpty
                                ? 'payload:all*'
                                : 'payload:all',
                            onTap: _clearMachinePayloadKindFilter,
                          ),
                          ...UnrouterMachineTypedPayloadKind.values.map(
                            (kind) => _buildAction(
                              key: Key(
                                'unrouter-panel-machine-kind-${kind.name}',
                              ),
                              label: _formatMachinePayloadKindLabel(kind),
                              onTap: () => _toggleMachinePayloadKind(kind),
                            ),
                          ),
                        ],
                      ),
                      if (replayValidation != null &&
                          replayValidation.hasIssues) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildAction(
                              key: const Key(
                                'unrouter-panel-replay-validation-severity-all',
                              ),
                              label: _replayValidationSeverities.isEmpty
                                  ? 'validationSeverity:all*'
                                  : 'validationSeverity:all',
                              onTap: _clearReplayValidationSeverityFilter,
                            ),
                            ...UnrouterInspectorReplayValidationSeverity.values.map(
                              (severity) => _buildAction(
                                key: Key(
                                  'unrouter-panel-replay-validation-severity-${severity.name}',
                                ),
                                label: _formatReplayValidationSeverityLabel(
                                  severity,
                                ),
                                onTap: () =>
                                    _toggleReplayValidationSeverity(severity),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildAction(
                              key: const Key(
                                'unrouter-panel-replay-validation-code-all',
                              ),
                              label: _replayValidationCodes.isEmpty
                                  ? 'validationCode:all*'
                                  : 'validationCode:all',
                              onTap: _clearReplayValidationCodeFilter,
                            ),
                            ...UnrouterInspectorReplayValidationIssueCode.values
                                .map(
                                  (code) => _buildAction(
                                    key: Key(
                                      'unrouter-panel-replay-validation-code-${code.name}',
                                    ),
                                    label: _formatReplayValidationCodeLabel(
                                      code,
                                    ),
                                    onTap: () =>
                                        _toggleReplayValidationCode(code),
                                  ),
                                ),
                          ],
                        ),
                      ],
                      if (replayDiff != null)
                        Text(
                          'diff mode=${replayDiff.mode.name} '
                          'changed=${replayDiff.changedCount} '
                          'missingBase=${replayDiff.missingBaselineCount} '
                          'missingCurrent=${replayDiff.missingCurrentCount}',
                          style: widget.headerTextStyle,
                        ),
                      if (replayDiff != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildAction(
                              key: const Key('unrouter-panel-compare-toggle'),
                              label: _compareCollapsed
                                  ? widget.compareExpandLabel
                                  : widget.compareCollapseLabel,
                              onTap: _toggleCompareCollapsed,
                            ),
                            _buildAction(
                              key: const Key(
                                'unrouter-panel-timeline-diff-toggle',
                              ),
                              label: _timelineDiffOnly
                                  ? widget.timelineAllLabel
                                  : widget.timelineDiffOnlyLabel,
                              onTap: _toggleTimelineDiffOnly,
                            ),
                            _buildAction(
                              key: const Key(
                                'unrouter-panel-compare-high-risk-toggle',
                              ),
                              label: _compareHighRiskOnly
                                  ? widget.compareAllClustersLabel
                                  : widget.compareHighRiskOnlyLabel,
                              onTap: _toggleCompareHighRiskOnly,
                            ),
                            _buildAction(
                              key: const Key(
                                'unrouter-panel-compare-high-risk-next',
                              ),
                              label: widget.compareNextHighRiskLabel,
                              onTap: () =>
                                  _focusNextHighRiskCluster(compareClusters),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildReplayCompareView(replayDiff),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildAction(
                            key: const Key('unrouter-panel-prev'),
                            label: widget.prevLabel,
                            onTap: widget.panel.selectPrevious,
                          ),
                          _buildAction(
                            key: const Key('unrouter-panel-next'),
                            label: widget.nextLabel,
                            onTap: widget.panel.selectNext,
                          ),
                          _buildAction(
                            key: const Key('unrouter-panel-latest'),
                            label: widget.latestLabel,
                            onTap: widget.panel.selectLatest,
                          ),
                          _buildAction(
                            key: const Key('unrouter-panel-clear'),
                            label: widget.clearLabel,
                            onTap: () {
                              widget.panel.clear();
                              widget.onClear?.call();
                              return true;
                            },
                          ),
                          _buildAction(
                            key: const Key('unrouter-panel-timeline-zoom-out'),
                            label: widget.zoomOutLabel,
                            onTap: _zoomOut,
                          ),
                          _buildAction(
                            key: const Key('unrouter-panel-timeline-zoom-in'),
                            label: widget.zoomInLabel,
                            onTap: _zoomIn,
                          ),
                          if (widget.onExportSelected != null)
                            _buildAction(
                              key: const Key('unrouter-panel-export-selected'),
                              label: widget.exportLabel,
                              onTap: () {
                                final entry = widget.panel.value.selectedEntry;
                                if (entry == null) {
                                  return false;
                                }
                                widget.onExportSelected!(
                                  jsonEncode(entry.toJson()),
                                );
                                return true;
                              },
                            ),
                          if (replay != null && replayState != null)
                            _buildAction(
                              key: const Key('unrouter-panel-replay-primary'),
                              label: replayState.isPaused
                                  ? widget.resumeLabel
                                  : replayState.isPlaying
                                  ? widget.pauseLabel
                                  : widget.playLabel,
                              onTap: () {
                                if (replayState.isPaused) {
                                  return replay.resume();
                                }
                                if (replayState.isPlaying) {
                                  return replay.pause();
                                }
                                unawaited(
                                  replay.play(
                                    onStep: (entry) {
                                      widget.panel.select(entry.sequence);
                                    },
                                  ),
                                );
                                return true;
                              },
                            ),
                          if (replay != null && replayState != null)
                            _buildAction(
                              key: const Key('unrouter-panel-replay-stop'),
                              label: widget.stopLabel,
                              onTap: () {
                                replay.stop();
                                return true;
                              },
                            ),
                          if (replay != null && replayState != null)
                            _buildAction(
                              key: const Key('unrouter-panel-replay-speed'),
                              label:
                                  '${widget.speedLabel}:${replayState.speed.label}',
                              onTap: () {
                                replay.cycleSpeedPreset();
                                return true;
                              },
                            ),
                          if (replay != null && replayState != null)
                            _buildAction(
                              key: const Key('unrouter-panel-replay-bookmark'),
                              label: widget.bookmarkLabel,
                              onTap: () {
                                try {
                                  replay.addBookmark();
                                  return true;
                                } on StateError {
                                  return false;
                                }
                              },
                            ),
                          if (replay != null &&
                              replayValidation != null &&
                              replayValidationIssues.isNotEmpty)
                            _buildAction(
                              key: const Key(
                                'unrouter-panel-replay-validation-next',
                              ),
                              label: widget.replayValidationNextLabel,
                              onTap: () => _focusNextReplayValidationIssue(
                                replayValidationIssues,
                              ),
                            ),
                        ],
                      ),
                      if (replayState != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'replay=${replayState.phase.name} '
                          'cursor=${replayState.cursorSequence ?? '-'} '
                          'range=${replayState.rangeStart ?? '-'}..${replayState.rangeEnd ?? '-'} '
                          'count=${replayState.replayedCount} '
                          'bookmarks=${replayState.bookmarks.length}',
                          style: widget.headerTextStyle,
                        ),
                        const SizedBox(height: 6),
                        _buildTimelineStrip(
                          timelineEntries,
                          replayState,
                          diffBySequence: diffBySequence,
                          diffByPath: diffByPath,
                        ),
                        if (replayState.bookmarks.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          ..._buildBookmarkGroups(replayState),
                        ],
                      ],
                      const SizedBox(height: 8),
                      if (compact) ...[
                        _buildEntriesList(
                          visible,
                          diffBySequence: diffBySequence,
                          diffByPath: diffByPath,
                        ),
                        const SizedBox(height: 8),
                        _buildSelectedDetails(selected),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildEntriesList(
                                visible,
                                diffBySequence: diffBySequence,
                                diffByPath: diffByPath,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _buildSelectedDetails(selected)),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CompareDiffCluster {
  static const int highRiskScore = 3;

  const _CompareDiffCluster({
    required this.index,
    required this.startRowIndex,
    required this.entries,
    required this.maxRiskScore,
  });

  final int index;
  final int startRowIndex;
  final List<UnrouterInspectorReplayDiffEntry> entries;
  final int maxRiskScore;

  bool get isHighRisk => maxRiskScore >= highRiskScore;
}

class _CompareClusterStats {
  const _CompareClusterStats({
    required this.clusterCount,
    required this.rowCount,
    required this.highRiskClusters,
    required this.highRiskRows,
  });

  final int clusterCount;
  final int rowCount;
  final int highRiskClusters;
  final int highRiskRows;
}
