/// History mode for the router.
///
/// - [memory]: In-memory history (for testing or mobile apps)
/// - [browser]: Browser history using pushState API
/// - [hash]: Hash-based history (legacy browser support)
enum HistoryMode {
  memory,
  browser,
  hash,
}
