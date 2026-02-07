/// Receives redirect diagnostics emitted by the route resolver.
typedef RedirectDiagnosticsCallback =
    void Function(RedirectDiagnostics diagnostics);

/// Behavior when redirect loops are detected.
enum RedirectLoopPolicy { error, ignore }

/// Reason for a redirect diagnostic emission.
enum RedirectDiagnosticsReason { loopDetected, maxHopsExceeded }

/// Redirect safety metadata captured during route resolution.
class RedirectDiagnostics {
  const RedirectDiagnostics({
    required this.reason,
    required this.currentUri,
    required this.redirectUri,
    required this.trail,
    required this.hop,
    required this.maxHops,
    required this.loopPolicy,
  });

  final RedirectDiagnosticsReason reason;
  final Uri currentUri;
  final Uri redirectUri;
  final List<Uri> trail;
  final int hop;
  final int maxHops;
  final RedirectLoopPolicy loopPolicy;
}
