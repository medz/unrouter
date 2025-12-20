/// How URLs should be represented on the web.
///
/// - [UrlStrategy.browser] produces path-based URLs like `/about`.
/// - [UrlStrategy.hash] produces hash-based URLs like `/#/about`.
///
/// Use this via `Unrouter(strategy: ...)`.
enum UrlStrategy {
  /// Path-based URLs (uses the browser's `pathname` / `search` / `hash`).
  browser,

  /// Hash-based URLs (stores the route inside `location.hash`).
  ///
  /// This strategy typically works without server-side rewrites.
  hash,
}
