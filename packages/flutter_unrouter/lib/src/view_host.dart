import 'package:flutter/widgets.dart';

import 'inlet.dart';

/// Renders and caches the widget produced by [builder], rebuilding only when
/// [builder] itself changes identity.
class ViewHost extends StatefulWidget {
  /// Creates a view host.
  const ViewHost({required this.builder, super.key});

  /// View builder called to produce the widget for this host.
  final ViewBuilder builder;

  @override
  State<ViewHost> createState() => _ViewHostState();
}

class _ViewHostState extends State<ViewHost> {
  late Widget child = widget.builder.call();

  @override
  void didUpdateWidget(covariant ViewHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.builder != widget.builder) {
      child = widget.builder.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
