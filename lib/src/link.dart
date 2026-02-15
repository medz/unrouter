import 'dart:async';

import 'package:flutter/widgets.dart';

import 'router_delegate.dart';
import 'url_search_params.dart';

/// A clickable widget that triggers router navigation.
class Link extends StatelessWidget {
  /// Creates a navigation link widget.
  const Link({
    /// Route name or absolute path to navigate to.
    required this.to,

    /// Child widget used as the tap target.
    required this.child,

    /// Optional params used when [to] resolves by route name.
    this.params,

    /// Optional query params appended to the destination.
    this.query,

    /// Optional navigation state forwarded to the destination.
    this.state,

    /// Whether to use `replace` instead of `push`.
    this.replace = false,

    /// Whether interaction is enabled.
    this.enabled = true,

    /// Optional callback invoked before navigation is triggered.
    this.onTap,

    /// Hit test behavior for the internal [GestureDetector].
    this.behavior = HitTestBehavior.deferToChild,
    super.key,
  });

  /// Route name or absolute path to navigate to.
  final String to;

  /// Optional params used when [to] resolves by route name.
  final Map<String, String>? params;

  /// Optional query params appended to the destination.
  final URLSearchParams? query;

  /// Optional navigation state forwarded to the destination.
  final Object? state;

  /// Whether to use `replace` instead of `push`.
  final bool replace;

  /// Whether interaction is enabled.
  final bool enabled;

  /// Optional callback invoked before navigation is triggered.
  final VoidCallback? onTap;

  /// Hit test behavior for the internal [GestureDetector].
  final HitTestBehavior behavior;

  /// Child widget used as the tap target.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final router = useRouter(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: behavior,
        onTap: () {
          onTap?.call();
          final nextQuery = query?.clone();
          if (replace) {
            unawaited(
              router.replace<Object?>(
                to,
                params: params,
                query: nextQuery,
                state: state,
              ),
            );
            return;
          }

          unawaited(
            router.push<Object?>(
              to,
              params: params,
              query: nextQuery,
              state: state,
            ),
          );
        },
        child: child,
      ),
    );
  }
}
