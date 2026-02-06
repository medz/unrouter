import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'inspector_bridge.dart';
import 'inspector_panel_adapter.dart';
import 'inspector_replay_compare.dart';
import 'inspector_replay_controller.dart';
import 'inspector_replay_store.dart';
import 'navigation.dart';

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

  bool _zoomIn() {
    if (_timelineZoomIndex >= widget.timelineZoomFactors.length - 1) {
      return false;
    }
    setState(() {
      _timelineZoomIndex += 1;
    });
    return true;
  }

  bool _zoomOut() {
    if (_timelineZoomIndex <= 0) {
      return false;
    }
    setState(() {
      _timelineZoomIndex -= 1;
    });
    return true;
  }

  bool _toggleCompareCollapsed() {
    setState(() {
      _compareCollapsed = !_compareCollapsed;
    });
    return true;
  }

  bool _toggleCompareHighRiskOnly() {
    setState(() {
      _compareHighRiskOnly = !_compareHighRiskOnly;
    });
    return true;
  }

  bool _toggleTimelineDiffOnly() {
    setState(() {
      _timelineDiffOnly = !_timelineDiffOnly;
    });
    return true;
  }

  bool _toggleCompareCluster(int clusterIndex) {
    setState(() {
      if (_collapsedCompareClusters.contains(clusterIndex)) {
        _collapsedCompareClusters.remove(clusterIndex);
      } else {
        _collapsedCompareClusters.add(clusterIndex);
      }
    });
    return true;
  }

  bool _focusNextReplayValidationIssue(
    List<UnrouterInspectorReplayValidationIssue> issues,
  ) {
    final sequences = _validationIssueSequences(issues);
    if (sequences.isEmpty) {
      return false;
    }
    final replay = widget.replayController;
    final current =
        widget.panel.value.selectedSequence ?? replay?.value.cursorSequence;
    final target = _nextIssueSequence(sequences, currentSequence: current);
    final selected = widget.panel.select(target);
    final scrubbed = replay?.scrubTo(target, selectNearest: false) ?? false;
    return selected || scrubbed;
  }

  List<int> _validationIssueSequences(
    List<UnrouterInspectorReplayValidationIssue> issues,
  ) {
    final values =
        issues.map((issue) => issue.sequence).toSet().toList(growable: false)
          ..sort();
    return values;
  }

  List<UnrouterInspectorReplayValidationIssue> _filterReplayValidationIssues(
    List<UnrouterInspectorReplayValidationIssue> issues,
  ) {
    return issues
        .where((issue) {
          if (_replayValidationSeverities.isNotEmpty &&
              !_replayValidationSeverities.contains(issue.severity)) {
            return false;
          }
          if (_replayValidationCodes.isNotEmpty &&
              !_replayValidationCodes.contains(issue.code)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Map<UnrouterInspectorReplayValidationIssueCode, int>
  _countReplayValidationIssuesByCode(
    List<UnrouterInspectorReplayValidationIssue> issues,
  ) {
    final counts = <UnrouterInspectorReplayValidationIssueCode, int>{};
    for (final code in UnrouterInspectorReplayValidationIssueCode.values) {
      counts[code] = 0;
    }
    for (final issue in issues) {
      counts[issue.code] = (counts[issue.code] ?? 0) + 1;
    }
    return counts;
  }

  int _nextIssueSequence(List<int> sequences, {required int? currentSequence}) {
    if (sequences.isEmpty) {
      throw StateError('Validation issue sequence list must not be empty.');
    }
    final current = currentSequence;
    if (current == null) {
      return sequences.first;
    }
    for (final sequence in sequences) {
      if (sequence > current) {
        return sequence;
      }
    }
    return sequences.first;
  }

  int _resolveMarkerCount(int visibleLength) {
    final capped = visibleLength > widget.timelineMarkerLimit
        ? widget.timelineMarkerLimit
        : visibleLength;
    if (capped <= 0) {
      return 0;
    }
    if (_timelineStride <= 1) {
      return capped;
    }
    final count = (capped / _timelineStride).ceil();
    return count > 0 ? count : 1;
  }

  List<UnrouterInspectorPanelEntry> _resolveTimelineEntries(
    List<UnrouterInspectorPanelEntry> entries, {
    required Map<int, UnrouterInspectorReplayDiffEntry> diffBySequence,
    required Map<String, UnrouterInspectorReplayDiffEntry> diffByPath,
  }) {
    final capped = entries.length > widget.timelineMarkerLimit
        ? entries.sublist(entries.length - widget.timelineMarkerLimit)
        : entries;
    if (!_timelineDiffOnly) {
      return capped;
    }
    return capped
        .where(
          (entry) => _isEntryDiff(
            entry,
            diffBySequence: diffBySequence,
            diffByPath: diffByPath,
          ),
        )
        .toList(growable: false);
  }

  Widget _buildAction({
    required Key key,
    required String label,
    required bool Function() onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Text(label, style: widget.detailTextStyle),
    );
  }

  Widget _buildEntriesList(
    List<UnrouterInspectorPanelEntry> entries, {
    required Map<int, UnrouterInspectorReplayDiffEntry> diffBySequence,
    required Map<String, UnrouterInspectorReplayDiffEntry> diffByPath,
  }) {
    final ordered = entries.reversed.toList(growable: false);
    return SizedBox(
      height: widget.listHeight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('events', style: widget.headerTextStyle),
            const SizedBox(height: 4),
            if (ordered.isEmpty) Text('-', style: widget.entryTextStyle),
            ...ordered.map(
              (entry) => _buildEntryLine(
                entry,
                diffBySequence: diffBySequence,
                diffByPath: diffByPath,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryLine(
    UnrouterInspectorPanelEntry entry, {
    required Map<int, UnrouterInspectorReplayDiffEntry> diffBySequence,
    required Map<String, UnrouterInspectorReplayDiffEntry> diffByPath,
  }) {
    final selected = widget.panel.value.selectedSequence == entry.sequence;
    final isDiff = _isEntryDiff(
      entry,
      diffBySequence: diffBySequence,
      diffByPath: diffByPath,
    );
    final marker = isDiff ? 'diff' : 'ok';
    return GestureDetector(
      key: Key('unrouter-panel-entry-${entry.sequence}'),
      onTap: () {
        widget.panel.select(entry.sequence);
        widget.replayController?.scrubTo(entry.sequence);
      },
      child: Text(
        '#${entry.sequence} ${entry.reason.name} '
        '${entry.routePath ?? '-'} ${entry.uri ?? '-'} '
        '[${selected ? 'selected' : 'idle'}|$marker]',
        style: widget.entryTextStyle,
      ),
    );
  }

  Widget _buildTimelineStrip(
    List<UnrouterInspectorPanelEntry> entries,
    UnrouterInspectorReplayControllerState replayState, {
    required Map<int, UnrouterInspectorReplayDiffEntry> diffBySequence,
    required Map<String, UnrouterInspectorReplayDiffEntry> diffByPath,
  }) {
    final markers = _sampleTimelineMarkers(entries, _timelineStride);
    return SizedBox(
      height: 22,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: markers
              .map((entry) {
                final isCursor = replayState.cursorSequence == entry.sequence;
                final isDiff = _isEntryDiff(
                  entry,
                  diffBySequence: diffBySequence,
                  diffByPath: diffByPath,
                );
                final label = isCursor
                    ? '[${entry.sequence}]'
                    : '${entry.sequence}';
                return GestureDetector(
                  key: Key('unrouter-panel-timeline-${entry.sequence}'),
                  onTap: () {
                    widget.replayController?.scrubTo(entry.sequence);
                    widget.panel.select(entry.sequence);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      isDiff ? '!$label' : label,
                      style: widget.entryTextStyle,
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }

  List<_CompareDiffCluster> _buildCompareClustersForDiff(
    UnrouterInspectorReplaySessionDiff diff,
  ) {
    final changedEntries = diff.changedEntries;
    if (changedEntries.isEmpty) {
      return const <_CompareDiffCluster>[];
    }
    final visibleEntries = changedEntries.length > widget.compareRowLimit
        ? changedEntries.sublist(0, widget.compareRowLimit)
        : changedEntries;
    return _buildCompareClusters(visibleEntries);
  }

  Widget _buildReplayCompareView(UnrouterInspectorReplaySessionDiff diff) {
    final changedEntries = diff.changedEntries;
    if (changedEntries.isEmpty) {
      return Text(
        '${widget.compareLabel}: no-diff',
        style: widget.headerTextStyle,
      );
    }
    if (_compareCollapsed) {
      return Text(
        '${widget.compareLabel}: collapsed rows=${changedEntries.length}',
        style: widget.headerTextStyle,
      );
    }

    final visibleEntries = changedEntries.length > widget.compareRowLimit
        ? changedEntries.sublist(0, widget.compareRowLimit)
        : changedEntries;
    final clusters = _buildCompareClusters(visibleEntries);
    final clusterStats = _buildCompareClusterStats(clusters);
    final visibleClusters = _compareHighRiskOnly
        ? clusters
              .where((cluster) => cluster.isHighRisk)
              .toList(growable: false)
        : clusters;
    _syncCompareClusterState(visibleClusters);
    final rows = _buildCompareRowsByCluster(visibleClusters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.compareLabel} rows=${visibleEntries.length}/${changedEntries.length} '
          'clusters=${visibleClusters.length}/${clusters.length}',
          style: widget.headerTextStyle,
        ),
        Text(
          key: const Key('unrouter-panel-compare-risk-summary'),
          'risk high=${clusterStats.highRiskClusters}/${clusterStats.clusterCount} '
          'rows=${clusterStats.highRiskRows}/${clusterStats.rowCount} '
          'filter=${_compareHighRiskOnly ? 'high' : 'all'}',
          style: widget.headerTextStyle,
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Text('type', style: widget.headerTextStyle),
            ),
            Expanded(
              child: Text(
                widget.compareBaselineLabel,
                style: widget.headerTextStyle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.compareCurrentLabel,
                style: widget.headerTextStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: widget.compareListHeight,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows,
            ),
          ),
        ),
        if (visibleEntries.length < changedEntries.length)
          Text(
            '... truncated ${changedEntries.length - visibleEntries.length} rows',
            style: widget.detailTextStyle,
          ),
      ],
    );
  }

  List<Widget> _buildCompareRowsByCluster(List<_CompareDiffCluster> clusters) {
    final rows = <Widget>[];
    for (final cluster in clusters) {
      if (widget.enableCompareCluster) {
        final collapsed = _collapsedCompareClusters.contains(cluster.index);
        rows.add(
          GestureDetector(
            key: Key('unrouter-panel-compare-cluster-${cluster.index}'),
            onTap: () {
              _toggleCompareCluster(cluster.index);
            },
            child: Text(
              _formatCompareClusterLabel(cluster, collapsed: collapsed),
              style: widget.headerTextStyle,
            ),
          ),
        );
        if (collapsed) {
          continue;
        }
      }
      for (var local = 0; local < cluster.entries.length; local++) {
        final globalIndex = cluster.startRowIndex + local;
        rows.add(
          _buildReplayCompareRow(cluster.entries[local], index: globalIndex),
        );
      }
    }
    return rows;
  }

  String _formatCompareClusterLabel(
    _CompareDiffCluster cluster, {
    required bool collapsed,
  }) {
    final firstSequence = _clusterSequence(cluster.entries.first);
    final lastSequence = _clusterSequence(cluster.entries.last);
    final sequenceLabel = firstSequence == null || lastSequence == null
        ? 'seq:-'
        : firstSequence == lastSequence
        ? 'seq:$firstSequence'
        : 'seq:$firstSequence..$lastSequence';
    final toggleLabel = collapsed
        ? widget.compareClusterExpandLabel
        : widget.compareClusterCollapseLabel;
    final riskLabel = cluster.isHighRisk ? 'risk=high' : 'risk=normal';
    return '$toggleLabel cluster=${cluster.index} '
        'rows=${cluster.entries.length} '
        '$riskLabel '
        '$sequenceLabel';
  }

  List<_CompareDiffCluster> _buildCompareClusters(
    List<UnrouterInspectorReplayDiffEntry> entries,
  ) {
    if (entries.isEmpty) {
      return const <_CompareDiffCluster>[];
    }

    final clusters = <_CompareDiffCluster>[];
    var start = 0;
    while (start < entries.length) {
      var end = start + 1;
      while (end < entries.length &&
          _isSameCompareCluster(entries[end - 1], entries[end])) {
        end += 1;
      }
      clusters.add(
        _CompareDiffCluster(
          index: clusters.length,
          startRowIndex: start,
          entries: List<UnrouterInspectorReplayDiffEntry>.unmodifiable(
            entries.sublist(start, end),
          ),
          maxRiskScore: _resolveClusterRisk(entries.sublist(start, end)),
        ),
      );
      start = end;
    }
    return clusters;
  }

  _CompareClusterStats _buildCompareClusterStats(
    List<_CompareDiffCluster> clusters,
  ) {
    if (clusters.isEmpty) {
      return const _CompareClusterStats(
        clusterCount: 0,
        rowCount: 0,
        highRiskClusters: 0,
        highRiskRows: 0,
      );
    }
    var rowCount = 0;
    var highRiskClusters = 0;
    var highRiskRows = 0;
    for (final cluster in clusters) {
      final clusterRows = cluster.entries.length;
      rowCount += clusterRows;
      if (cluster.isHighRisk) {
        highRiskClusters += 1;
        highRiskRows += clusterRows;
      }
    }
    return _CompareClusterStats(
      clusterCount: clusters.length,
      rowCount: rowCount,
      highRiskClusters: highRiskClusters,
      highRiskRows: highRiskRows,
    );
  }

  int _resolveClusterRisk(List<UnrouterInspectorReplayDiffEntry> entries) {
    var maxScore = 0;
    for (final entry in entries) {
      final score = _diffRiskScore(entry);
      if (score > maxScore) {
        maxScore = score;
      }
    }
    return maxScore;
  }

  int _diffRiskScore(UnrouterInspectorReplayDiffEntry entry) {
    switch (entry.type) {
      case UnrouterInspectorReplayDiffType.unchanged:
        return 0;
      case UnrouterInspectorReplayDiffType.changed:
        if (entry.reasonChanged || entry.uriChanged) {
          return 3;
        }
        if (entry.pathChanged) {
          return 2;
        }
        return 1;
      case UnrouterInspectorReplayDiffType.missingBaseline:
        return 2;
      case UnrouterInspectorReplayDiffType.missingCurrent:
        return 3;
    }
  }

  bool _isSameCompareCluster(
    UnrouterInspectorReplayDiffEntry previous,
    UnrouterInspectorReplayDiffEntry next,
  ) {
    final previousSequence = _clusterSequence(previous);
    final nextSequence = _clusterSequence(next);
    if (previousSequence == null || nextSequence == null) {
      return false;
    }
    return nextSequence == previousSequence + 1;
  }

  int? _clusterSequence(UnrouterInspectorReplayDiffEntry entry) {
    return entry.currentSequence ?? entry.baselineSequence;
  }

  bool _focusNextHighRiskCluster(List<_CompareDiffCluster> clusters) {
    final highRisk = clusters
        .where((cluster) => cluster.isHighRisk)
        .toList(growable: false);
    if (highRisk.isEmpty) {
      return false;
    }

    final selected = widget.panel.value.selectedSequence;
    var target = highRisk.first;
    if (selected != null) {
      for (final cluster in highRisk) {
        final firstSequence = _clusterSequence(cluster.entries.first);
        if (firstSequence != null && firstSequence > selected) {
          target = cluster;
          break;
        }
      }
    }

    final riskyEntry = target.entries
        .where((entry) {
          return _diffRiskScore(entry) >= _CompareDiffCluster.highRiskScore;
        })
        .toList(growable: false);
    final targetEntry = riskyEntry.isEmpty
        ? target.entries.first
        : riskyEntry.first;
    final targetSequence = _clusterSequence(targetEntry);
    if (targetSequence == null) {
      return false;
    }

    setState(() {
      _collapsedCompareClusters.remove(target.index);
    });
    widget.panel.select(targetSequence);
    widget.replayController?.scrubTo(targetSequence);
    return true;
  }

  void _syncCompareClusterState(List<_CompareDiffCluster> clusters) {
    final validIndexes = clusters.map((cluster) => cluster.index).toSet();
    _collapsedCompareClusters.removeWhere(
      (clusterIndex) => !validIndexes.contains(clusterIndex),
    );
    if (_compareClusterStateInitialized) {
      return;
    }
    _compareClusterStateInitialized = true;
    if (!widget.enableCompareCluster ||
        !widget.initialCompareClustersCollapsed) {
      return;
    }
    _collapsedCompareClusters.addAll(validIndexes);
  }

  Widget _buildReplayCompareRow(
    UnrouterInspectorReplayDiffEntry diff, {
    required int index,
  }) {
    final currentSequence = diff.currentSequence;
    return GestureDetector(
      key: Key('unrouter-panel-compare-row-$index'),
      onTap: currentSequence == null
          ? null
          : () {
              widget.panel.select(currentSequence);
              widget.replayController?.scrubTo(currentSequence);
            },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              _diffTypeLabel(diff.type),
              style: widget.detailTextStyle,
            ),
          ),
          Expanded(
            child: Text(
              _formatCompareCell(
                sequence: diff.baselineSequence,
                reason: diff.baselineReason,
                path: diff.baselinePath,
                uri: diff.baselineUri,
              ),
              overflow: TextOverflow.ellipsis,
              style: widget.detailTextStyle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatCompareCell(
                sequence: diff.currentSequence,
                reason: diff.currentReason,
                path: diff.currentPath,
                uri: diff.currentUri,
              ),
              overflow: TextOverflow.ellipsis,
              style: widget.detailTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompareCell({
    required int? sequence,
    required String? reason,
    required String? path,
    required String? uri,
  }) {
    if (sequence == null) {
      return '-';
    }
    final target = path ?? uri ?? '-';
    final resolvedReason = reason ?? '-';
    return '#$sequence $resolvedReason $target';
  }

  String _diffTypeLabel(UnrouterInspectorReplayDiffType type) {
    switch (type) {
      case UnrouterInspectorReplayDiffType.unchanged:
        return '=';
      case UnrouterInspectorReplayDiffType.changed:
        return 'chg';
      case UnrouterInspectorReplayDiffType.missingBaseline:
        return '+';
      case UnrouterInspectorReplayDiffType.missingCurrent:
        return '-';
    }
  }

  List<Widget> _buildBookmarkGroups(
    UnrouterInspectorReplayControllerState replayState,
  ) {
    final replay = widget.replayController;
    if (replay == null) {
      return const <Widget>[];
    }
    final groups = replayState.bookmarksByGroup.entries.toList();
    return groups
        .map((entry) {
          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Text('group:${entry.key}', style: widget.headerTextStyle),
              ...entry.value.map((bookmark) {
                return _buildAction(
                  key: Key('unrouter-panel-bookmark-${bookmark.id}'),
                  label: '${bookmark.label}@${bookmark.sequence}',
                  onTap: () {
                    final jumped = replay.jumpToBookmark(bookmark.id);
                    if (jumped) {
                      widget.panel.select(bookmark.sequence);
                    }
                    return jumped;
                  },
                );
              }),
            ],
          );
        })
        .toList(growable: false);
  }

  List<UnrouterInspectorPanelEntry> _sampleTimelineMarkers(
    List<UnrouterInspectorPanelEntry> entries,
    int stride,
  ) {
    if (entries.isEmpty || stride <= 1) {
      return entries;
    }
    final sampled = <UnrouterInspectorPanelEntry>[];
    for (var index = 0; index < entries.length; index += stride) {
      sampled.add(entries[index]);
    }
    final last = entries.last;
    if (sampled.isEmpty || sampled.last.sequence != last.sequence) {
      sampled.add(last);
    }
    return sampled;
  }

  Widget _buildSelectedDetails(UnrouterInspectorPanelEntry? selected) {
    if (selected == null) {
      return SizedBox(
        height: widget.listHeight,
        child: Text('selected: -', style: widget.detailTextStyle),
      );
    }
    final keys = selected.report.keys.toList()..sort();
    return SizedBox(
      height: widget.listHeight,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'selected=#${selected.sequence} ${selected.reason.name}',
              style: widget.headerTextStyle,
            ),
            const SizedBox(height: 4),
            ...keys.map(
              (key) => Text(
                '$key: ${selected.report[key]}',
                style: widget.detailTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<UnrouterInspectorPanelEntry> _filterEntries(
    List<UnrouterInspectorPanelEntry> entries,
  ) {
    final normalizedQuery = _normalizeQuery(widget.query);
    return entries
        .where((entry) {
          if (widget.reasons != null &&
              widget.reasons!.isNotEmpty &&
              !widget.reasons!.contains(entry.reason)) {
            return false;
          }
          if (_machineEventGroups.isNotEmpty &&
              !_entryMatchesMachineEventGroups(entry, _machineEventGroups)) {
            return false;
          }
          if (_machinePayloadKinds.isNotEmpty &&
              !_entryMatchesMachinePayloadKinds(entry, _machinePayloadKinds)) {
            return false;
          }
          if (normalizedQuery != null &&
              !_entryMatchesQuery(entry, normalizedQuery)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  bool _entryMatchesQuery(UnrouterInspectorPanelEntry entry, String query) {
    if (_containsQuery(entry.reason.name, query) ||
        _containsQuery(entry.routePath, query) ||
        _containsQuery(entry.uri, query) ||
        _containsQuery(entry.resolution, query) ||
        _containsQuery(entry.sequence, query) ||
        _machineEventGroupsForEntry(
          entry,
        ).any((group) => _containsQuery(group.name, query))) {
      return true;
    }
    if (_machinePayloadKindsForEntry(
      entry,
    ).any((kind) => _containsQuery(kind.name, query))) {
      return true;
    }
    for (final value in entry.report.values) {
      if (_containsQuery(value, query)) {
        return true;
      }
    }
    return false;
  }

  Map<int, UnrouterInspectorReplayDiffEntry> _buildDiffBySequence(
    UnrouterInspectorReplaySessionDiff? diff,
  ) {
    if (diff == null) {
      return const <int, UnrouterInspectorReplayDiffEntry>{};
    }
    final map = <int, UnrouterInspectorReplayDiffEntry>{};
    for (final item in diff.changedEntries) {
      final sequence = item.currentSequence;
      if (sequence != null) {
        map[sequence] = item;
      }
    }
    return map;
  }

  Map<String, UnrouterInspectorReplayDiffEntry> _buildDiffByPath(
    UnrouterInspectorReplaySessionDiff? diff,
  ) {
    if (diff == null) {
      return const <String, UnrouterInspectorReplayDiffEntry>{};
    }
    final map = <String, UnrouterInspectorReplayDiffEntry>{};
    for (final item in diff.changedEntries) {
      final path = item.currentPath ?? item.key;
      if (path.isNotEmpty) {
        map[path] = item;
      }
    }
    return map;
  }

  bool _isEntryDiff(
    UnrouterInspectorPanelEntry entry, {
    required Map<int, UnrouterInspectorReplayDiffEntry> diffBySequence,
    required Map<String, UnrouterInspectorReplayDiffEntry> diffByPath,
  }) {
    if (diffBySequence.containsKey(entry.sequence)) {
      return true;
    }
    final path = entry.routePath ?? entry.uri;
    if (path == null) {
      return false;
    }
    return diffByPath.containsKey(path);
  }

  String? _normalizeQuery(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text.toLowerCase();
  }

  bool _containsQuery(Object? value, String query) {
    if (value == null) {
      return false;
    }
    return value.toString().toLowerCase().contains(query);
  }

  bool _toggleMachineEventGroup(UnrouterMachineEventGroup group) {
    setState(() {
      if (_machineEventGroups.contains(group)) {
        _machineEventGroups.remove(group);
      } else {
        _machineEventGroups.add(group);
      }
    });
    _notifyMachineEventGroupsChanged();
    return true;
  }

  bool _clearMachineEventGroupFilter() {
    if (_machineEventGroups.isEmpty) {
      return false;
    }
    setState(() {
      _machineEventGroups = <UnrouterMachineEventGroup>{};
    });
    _notifyMachineEventGroupsChanged();
    return true;
  }

  String _formatMachineEventGroupLabel(UnrouterMachineEventGroup group) {
    final active = _machineEventGroups.contains(group);
    return active ? 'machine:${group.name}*' : 'machine:${group.name}';
  }

  String _describeMachineEventGroupFilter() {
    if (_machineEventGroups.isEmpty) {
      return 'all';
    }
    final ordered = UnrouterMachineEventGroup.values
        .where(_machineEventGroups.contains)
        .map((group) => group.name)
        .toList(growable: false);
    return ordered.join(',');
  }

  bool _toggleMachinePayloadKind(UnrouterMachineTypedPayloadKind kind) {
    setState(() {
      if (_machinePayloadKinds.contains(kind)) {
        _machinePayloadKinds.remove(kind);
      } else {
        _machinePayloadKinds.add(kind);
      }
    });
    _notifyMachinePayloadKindsChanged();
    return true;
  }

  bool _clearMachinePayloadKindFilter() {
    if (_machinePayloadKinds.isEmpty) {
      return false;
    }
    setState(() {
      _machinePayloadKinds = <UnrouterMachineTypedPayloadKind>{};
    });
    _notifyMachinePayloadKindsChanged();
    return true;
  }

  String _formatMachinePayloadKindLabel(UnrouterMachineTypedPayloadKind kind) {
    final active = _machinePayloadKinds.contains(kind);
    return active ? 'payload:${kind.name}*' : 'payload:${kind.name}';
  }

  String _describeMachinePayloadKindFilter() {
    if (_machinePayloadKinds.isEmpty) {
      return 'all';
    }
    final ordered = UnrouterMachineTypedPayloadKind.values
        .where(_machinePayloadKinds.contains)
        .map((kind) => kind.name)
        .toList(growable: false);
    return ordered.join(',');
  }

  bool _toggleReplayValidationSeverity(
    UnrouterInspectorReplayValidationSeverity severity,
  ) {
    setState(() {
      if (_replayValidationSeverities.contains(severity)) {
        _replayValidationSeverities.remove(severity);
      } else {
        _replayValidationSeverities.add(severity);
      }
    });
    return true;
  }

  bool _clearReplayValidationSeverityFilter() {
    if (_replayValidationSeverities.isEmpty) {
      return false;
    }
    setState(() {
      _replayValidationSeverities =
          <UnrouterInspectorReplayValidationSeverity>{};
    });
    return true;
  }

  String _formatReplayValidationSeverityLabel(
    UnrouterInspectorReplayValidationSeverity severity,
  ) {
    final active = _replayValidationSeverities.contains(severity);
    return active
        ? 'validationSeverity:${severity.name}*'
        : 'validationSeverity:${severity.name}';
  }

  String _describeReplayValidationSeverityFilter() {
    if (_replayValidationSeverities.isEmpty) {
      return 'all';
    }
    final ordered = UnrouterInspectorReplayValidationSeverity.values
        .where(_replayValidationSeverities.contains)
        .map((severity) => severity.name)
        .toList(growable: false);
    return ordered.join(',');
  }

  bool _toggleReplayValidationCode(
    UnrouterInspectorReplayValidationIssueCode code,
  ) {
    setState(() {
      if (_replayValidationCodes.contains(code)) {
        _replayValidationCodes.remove(code);
      } else {
        _replayValidationCodes.add(code);
      }
    });
    return true;
  }

  bool _clearReplayValidationCodeFilter() {
    if (_replayValidationCodes.isEmpty) {
      return false;
    }
    setState(() {
      _replayValidationCodes = <UnrouterInspectorReplayValidationIssueCode>{};
    });
    return true;
  }

  String _formatReplayValidationCodeLabel(
    UnrouterInspectorReplayValidationIssueCode code,
  ) {
    final active = _replayValidationCodes.contains(code);
    return active
        ? 'validationCode:${code.name}*'
        : 'validationCode:${code.name}';
  }

  String _describeReplayValidationCodeFilter() {
    if (_replayValidationCodes.isEmpty) {
      return 'all';
    }
    final ordered = UnrouterInspectorReplayValidationIssueCode.values
        .where(_replayValidationCodes.contains)
        .map((code) => code.name)
        .toList(growable: false);
    return ordered.join(',');
  }

  bool _entryMatchesMachineEventGroups(
    UnrouterInspectorPanelEntry entry,
    Set<UnrouterMachineEventGroup> groups,
  ) {
    final entryGroups = _machineEventGroupsForEntry(entry);
    if (entryGroups.isEmpty) {
      return false;
    }
    for (final group in entryGroups) {
      if (groups.contains(group)) {
        return true;
      }
    }
    return false;
  }

  bool _entryMatchesMachinePayloadKinds(
    UnrouterInspectorPanelEntry entry,
    Set<UnrouterMachineTypedPayloadKind> kinds,
  ) {
    final entryKinds = _machinePayloadKindsForEntry(entry);
    if (entryKinds.isEmpty) {
      return false;
    }
    for (final kind in entryKinds) {
      if (kinds.contains(kind)) {
        return true;
      }
    }
    return false;
  }

  Set<UnrouterMachineEventGroup> _machineEventGroupsForEntry(
    UnrouterInspectorPanelEntry entry,
  ) {
    final value = entry.report['machineTimelineTail'];
    if (value is! List<Object?>) {
      return const <UnrouterMachineEventGroup>{};
    }
    final groups = <UnrouterMachineEventGroup>{};
    for (final item in value) {
      if (item is! Map<Object?, Object?>) {
        continue;
      }
      final group = _parseMachineEventGroup(item['eventGroup']);
      if (group != null) {
        groups.add(group);
      }
    }
    return groups;
  }

  Set<UnrouterMachineTypedPayloadKind> _machinePayloadKindsForEntry(
    UnrouterInspectorPanelEntry entry,
  ) {
    final value = entry.report['machineTimelineTail'];
    if (value is! List<Object?>) {
      return const <UnrouterMachineTypedPayloadKind>{};
    }
    final kinds = <UnrouterMachineTypedPayloadKind>{};
    for (final item in value) {
      if (item is! Map<Object?, Object?>) {
        continue;
      }
      final kind = _resolveMachinePayloadKind(item);
      if (kind != null) {
        kinds.add(kind);
      }
    }
    return kinds;
  }

  UnrouterMachineTypedPayloadKind? _resolveMachinePayloadKind(
    Map<Object?, Object?> machineEntry,
  ) {
    final payloadKind = _parseMachinePayloadKind(machineEntry['payloadKind']);
    if (payloadKind != null) {
      return payloadKind;
    }
    final payload = machineEntry['payload'];
    if (payload is Map<Object?, Object?>) {
      final nestedKind = _parseMachinePayloadKind(payload['kind']);
      if (nestedKind != null) {
        return nestedKind;
      }
    }
    final event = _parseMachineEvent(machineEntry['event']);
    if (event == UnrouterMachineEvent.actionEnvelope) {
      return UnrouterMachineTypedPayloadKind.actionEnvelope;
    }
    final source = _parseMachineSource(machineEntry['source']);
    switch (source) {
      case UnrouterMachineSource.controller:
        return UnrouterMachineTypedPayloadKind.controller;
      case UnrouterMachineSource.navigation:
        return UnrouterMachineTypedPayloadKind.navigation;
      case UnrouterMachineSource.route:
        return UnrouterMachineTypedPayloadKind.route;
      case null:
        return UnrouterMachineTypedPayloadKind.generic;
    }
  }

  UnrouterMachineEventGroup? _parseMachineEventGroup(Object? raw) {
    if (raw is UnrouterMachineEventGroup) {
      return raw;
    }
    if (raw is! String) {
      return null;
    }
    for (final group in UnrouterMachineEventGroup.values) {
      if (group.name == raw) {
        return group;
      }
    }
    return null;
  }

  UnrouterMachineEvent? _parseMachineEvent(Object? raw) {
    if (raw is UnrouterMachineEvent) {
      return raw;
    }
    if (raw is! String) {
      return null;
    }
    for (final event in UnrouterMachineEvent.values) {
      if (event.name == raw) {
        return event;
      }
    }
    return null;
  }

  UnrouterMachineSource? _parseMachineSource(Object? raw) {
    if (raw is UnrouterMachineSource) {
      return raw;
    }
    if (raw is! String) {
      return null;
    }
    for (final source in UnrouterMachineSource.values) {
      if (source.name == raw) {
        return source;
      }
    }
    return null;
  }

  UnrouterMachineTypedPayloadKind? _parseMachinePayloadKind(Object? raw) {
    if (raw is UnrouterMachineTypedPayloadKind) {
      return raw;
    }
    if (raw is! String) {
      return null;
    }
    for (final kind in UnrouterMachineTypedPayloadKind.values) {
      if (kind.name == raw) {
        return kind;
      }
    }
    return null;
  }

  Set<UnrouterMachineEventGroup> _copyMachineEventGroupFilter(
    Set<UnrouterMachineEventGroup>? value,
  ) {
    if (value == null || value.isEmpty) {
      return <UnrouterMachineEventGroup>{};
    }
    return Set<UnrouterMachineEventGroup>.from(value);
  }

  Set<UnrouterMachineTypedPayloadKind> _copyMachinePayloadKindFilter(
    Set<UnrouterMachineTypedPayloadKind>? value,
  ) {
    if (value == null || value.isEmpty) {
      return <UnrouterMachineTypedPayloadKind>{};
    }
    return Set<UnrouterMachineTypedPayloadKind>.from(value);
  }

  bool _sameMachineEventGroupSet(
    Set<UnrouterMachineEventGroup>? a,
    Set<UnrouterMachineEventGroup>? b,
  ) {
    final resolvedA = a ?? const <UnrouterMachineEventGroup>{};
    final resolvedB = b ?? const <UnrouterMachineEventGroup>{};
    if (identical(resolvedA, resolvedB)) {
      return true;
    }
    if (resolvedA.length != resolvedB.length) {
      return false;
    }
    for (final value in resolvedA) {
      if (!resolvedB.contains(value)) {
        return false;
      }
    }
    return true;
  }

  bool _sameMachinePayloadKindSet(
    Set<UnrouterMachineTypedPayloadKind>? a,
    Set<UnrouterMachineTypedPayloadKind>? b,
  ) {
    final resolvedA = a ?? const <UnrouterMachineTypedPayloadKind>{};
    final resolvedB = b ?? const <UnrouterMachineTypedPayloadKind>{};
    if (identical(resolvedA, resolvedB)) {
      return true;
    }
    if (resolvedA.length != resolvedB.length) {
      return false;
    }
    for (final value in resolvedA) {
      if (!resolvedB.contains(value)) {
        return false;
      }
    }
    return true;
  }

  void _notifyMachineEventGroupsChanged() {
    final callback = widget.onMachineEventGroupsChanged;
    if (callback == null) {
      return;
    }
    if (_machineEventGroups.isEmpty) {
      callback(null);
      return;
    }
    callback(Set<UnrouterMachineEventGroup>.unmodifiable(_machineEventGroups));
  }

  void _notifyMachinePayloadKindsChanged() {
    final callback = widget.onMachinePayloadKindsChanged;
    if (callback == null) {
      return;
    }
    if (_machinePayloadKinds.isEmpty) {
      callback(null);
      return;
    }
    callback(
      Set<UnrouterMachineTypedPayloadKind>.unmodifiable(_machinePayloadKinds),
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
