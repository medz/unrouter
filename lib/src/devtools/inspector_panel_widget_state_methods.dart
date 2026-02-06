part of 'inspector_panel_widget.dart';

extension _UnrouterInspectorPanelWidgetStateMethods
    on _UnrouterInspectorPanelWidgetState {
  bool _zoomIn() {
    if (_timelineZoomIndex >= widget.timelineZoomFactors.length - 1) {
      return false;
    }
    _setState(() {
      _timelineZoomIndex += 1;
    });
    return true;
  }

  bool _zoomOut() {
    if (_timelineZoomIndex <= 0) {
      return false;
    }
    _setState(() {
      _timelineZoomIndex -= 1;
    });
    return true;
  }

  bool _toggleCompareCollapsed() {
    _setState(() {
      _compareCollapsed = !_compareCollapsed;
    });
    return true;
  }

  bool _toggleCompareHighRiskOnly() {
    _setState(() {
      _compareHighRiskOnly = !_compareHighRiskOnly;
    });
    return true;
  }

  bool _toggleTimelineDiffOnly() {
    _setState(() {
      _timelineDiffOnly = !_timelineDiffOnly;
    });
    return true;
  }

  bool _toggleCompareCluster(int clusterIndex) {
    _setState(() {
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

    _setState(() {
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
    _setState(() {
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
    _setState(() {
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
    _setState(() {
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
    _setState(() {
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
    _setState(() {
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
    _setState(() {
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
    _setState(() {
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
    _setState(() {
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
