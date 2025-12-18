import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

final class DefaultKey extends ValueKey<Symbol> {
  @literal
  const DefaultKey() : super(#unrouter.default_key);
}
