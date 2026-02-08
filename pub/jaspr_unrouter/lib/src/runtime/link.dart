import 'package:jaspr/dom.dart' as dom;
import 'package:jaspr/jaspr.dart';
import 'package:unrouter/unrouter.dart';

import 'navigation.dart';

/// Navigation mode used by [UnrouterLink].
enum UnrouterLinkMode {
  /// Replaces current history entry with the target route.
  go,

  /// Alias of [go], kept for API readability.
  replace,

  /// Pushes target route as a new history entry.
  push,
}

/// Declarative route link for Jaspr apps.
///
/// On client, when [target] is null or `_self`, clicks are intercepted and
/// dispatched through `unrouter` controller without full page reload.
///
/// When [target] is `_blank` / `_parent` / `_top`, native browser navigation is
/// preserved.
class UnrouterLink<R extends RouteData> extends StatelessComponent {
  const UnrouterLink({
    required this.route,
    required this.children,
    this.mode = UnrouterLinkMode.go,
    this.state,
    this.download,
    this.target,
    this.type,
    this.referrerPolicy,
    this.id,
    this.classes,
    this.styles,
    this.attributes,
    this.events,
    super.key,
  });

  /// Target typed route.
  final R route;

  /// Link children.
  final List<Component> children;

  /// Navigation behavior on click.
  final UnrouterLinkMode mode;

  /// Optional history state payload for navigation writes.
  final Object? state;

  final String? download;
  final dom.Target? target;
  final String? type;
  final dom.ReferrerPolicy? referrerPolicy;
  final String? id;
  final String? classes;
  final dom.Styles? styles;
  final Map<String, String>? attributes;
  final Map<String, EventCallback>? events;

  @override
  Component build(BuildContext context) {
    final controller = context.unrouterAs<R>();
    final href = controller.href(route);
    final canIntercept = target == null || target == dom.Target.self;

    return dom.a(
      children,
      href: href,
      onClick: canIntercept ? () => _onClick(controller) : null,
      download: download,
      target: target,
      type: type,
      referrerPolicy: referrerPolicy,
      id: id,
      classes: classes,
      styles: styles,
      attributes: attributes,
      events: events,
    );
  }

  void _onClick(UnrouterController<R> controller) {
    switch (mode) {
      case UnrouterLinkMode.go:
        controller.go(route, state: state);
        return;
      case UnrouterLinkMode.replace:
        controller.replace(route, state: state);
        return;
      case UnrouterLinkMode.push:
        controller.push<void>(route, state: state);
        return;
    }
  }
}
