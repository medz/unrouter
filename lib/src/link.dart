import 'dart:async';

import 'package:flutter/widgets.dart';

import 'router_delegate.dart';
import 'url_search_params.dart';

/// A tappable widget that triggers Unrouter navigation.
///
/// [Link] is a lightweight Flutter widget alternative to imperative navigation
/// calls from button handlers. It resolves [to] with the same rules as router
/// navigation: route name first, then absolute path.
///
/// If [replace] is `true`, the tap uses `replace`; otherwise it uses `push`.
///
/// Example:
/// ```dart
/// Link(
///   to: 'user',
///   params: {'id': '42'},
///   query: URLSearchParams('tab=profile'),
///   child: const Text('Open profile'),
/// )
/// ```
///
/// See also:
///
///  * `Unrouter.push`, which performs imperative push navigation.
///  * `Unrouter.replace`, which replaces the current history entry.
class Link extends StatelessWidget {
  /// Creates a navigation link.
  ///
  /// Set [enabled] to `false` to disable interaction while preserving [child].
  const Link({
    required this.to,
    required this.child,
    this.params,
    this.query,
    this.state,
    this.replace = false,
    this.enabled = true,
    this.onTap,
    this.behavior = HitTestBehavior.deferToChild,
    super.key,
  });

  /// Route name or absolute path to navigate to.
  final String to;

  /// Params used when [to] resolves as a route name.
  ///
  /// This value is ignored for absolute-path navigation.
  final Map<String, String>? params;

  /// Query params merged into the destination URI.
  ///
  /// When both [to] and [query] provide the same key, [query] wins.
  final URLSearchParams? query;

  /// Navigation state forwarded to the destination history entry.
  final Object? state;

  /// Whether to use replace navigation instead of push navigation.
  final bool replace;

  /// Whether tap interaction is enabled.
  final bool enabled;

  /// Callback invoked before navigation is triggered.
  final VoidCallback? onTap;

  /// Hit test behavior used by the internal [GestureDetector].
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
