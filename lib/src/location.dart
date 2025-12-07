/// Represents a navigation target.
class RouteLocation<T> {
  const RouteLocation.path(
    this.path, {
    this.state,
    this.hash,
    this.query = const {},
    this.replace = false,
    this.force = false,
  }) : name = null,
       params = const {};

  const RouteLocation.name(
    this.name, {
    this.params = const {},
    this.state,
    this.hash,
    this.query = const {},
    this.replace = false,
    this.force = false,
  }) : path = null;

  final String? path;
  final String? name;
  final Map<String, String> params;
  final T? state;
  final String? hash;
  final Map<String, String> query;
  final bool replace;
  final bool force;
}
