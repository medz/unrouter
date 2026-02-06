typedef RedirectDiagnosticsCallback =
    void Function(RedirectDiagnostics diagnostics);

enum RedirectLoopPolicy { error, ignore }

enum RedirectDiagnosticsReason { loopDetected, maxHopsExceeded }

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
