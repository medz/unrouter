import 'package:flutter/foundation.dart';

/// Configuration for file-based routing tools (CLI only).
///
/// These values are not used by the router at runtime. They are intended for
/// tooling that scans your project and generates route code.
@immutable
class FileRoutingConfig {
  const FileRoutingConfig({this.pagesDir, this.output});

  /// Directory that contains file-based pages.
  ///
  /// The CLI treats this as a path relative to the file that defines the
  /// [Unrouter] instance, or as an absolute path if provided.
  final String? pagesDir;

  /// Output file path for generated routes.
  ///
  /// The CLI treats this as a path relative to the file that defines the
  /// [Unrouter] instance, or as an absolute path if provided.
  final String? output;
}
