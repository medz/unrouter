import 'dart:async';

import 'package:flutter/widgets.dart';

import 'router_delegate.dart';
import 'url_search_params.dart';

class Link extends StatelessWidget {
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

  final String to;
  final Map<String, String>? params;
  final URLSearchParams? query;
  final Object? state;
  final bool replace;
  final bool enabled;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;
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
