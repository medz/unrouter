part of 'route_definition.dart';

/// Strongly typed parser helpers built from a matched URI.
class RouteParserState {
  RouteParserState({
    required this.uri,
    required Map<String, String> pathParameters,
  }) : _pathParameters = Map.unmodifiable(pathParameters);

  final Uri uri;
  final Map<String, String> _pathParameters;

  Map<String, String> get pathParameters {
    return UnmodifiableMapView(_pathParameters);
  }

  Map<String, String> get queryParameters {
    return UnmodifiableMapView(uri.queryParameters);
  }

  /// Returns required path parameter by [key].
  String path(String key) {
    final value = _pathParameters[key];
    if (value != null) {
      return value;
    }

    throw FormatException(
      'Missing required path parameter "$key" for uri "$uri".',
    );
  }

  /// Returns nullable path parameter by [key].
  String? pathOrNull(String key) {
    return _pathParameters[key];
  }

  /// Parses required path parameter as `int`.
  int pathInt(String key) {
    final raw = path(key);
    final parsed = int.tryParse(raw);
    if (parsed != null) {
      return parsed;
    }

    throw FormatException(
      'Path parameter "$key" must be an int, got "$raw" for uri "$uri".',
    );
  }

  /// Returns required query parameter by [key], or [fallback] when provided.
  String query(String key, {String? fallback}) {
    final value = uri.queryParameters[key];
    if (value != null) {
      return value;
    }

    if (fallback != null) {
      return fallback;
    }

    throw FormatException(
      'Missing required query parameter "$key" for uri "$uri".',
    );
  }

  /// Returns nullable query parameter by [key].
  String? queryOrNull(String key) {
    return uri.queryParameters[key];
  }

  /// Parses required query parameter as `int`.
  int queryInt(String key, {int? fallback}) {
    final value = queryOrNull(key);
    if (value == null) {
      if (fallback != null) {
        return fallback;
      }

      throw FormatException(
        'Missing required query parameter "$key" for uri "$uri".',
      );
    }

    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }

    throw FormatException(
      'Query parameter "$key" must be an int, got "$value" for uri "$uri".',
    );
  }

  /// Parses nullable query parameter as `int`.
  int? queryIntOrNull(String key) {
    final value = queryOrNull(key);
    if (value == null) {
      return null;
    }

    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }

    throw FormatException(
      'Query parameter "$key" must be an int, got "$value" for uri "$uri".',
    );
  }

  /// Parses query parameter as enum value by matching `Enum.name`.
  T queryEnum<T extends Enum>(String key, List<T> values, {T? fallback}) {
    final value = queryOrNull(key);
    if (value == null) {
      if (fallback != null) {
        return fallback;
      }

      throw FormatException(
        'Missing required query parameter "$key" for uri "$uri".',
      );
    }

    for (final entry in values) {
      if (entry.name == value) {
        return entry;
      }
    }

    throw FormatException(
      'Query parameter "$key" must be one of '
      '${values.map((entry) => entry.name).join(', ')}, got "$value".',
    );
  }
}
