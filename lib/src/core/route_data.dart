/// Base contract for typed routes consumed by `Unrouter`.
///
/// A route object must provide a canonical `Uri` representation through
/// [toUri].
abstract interface class RouteData {
  const RouteData();

  Uri toUri();
}
