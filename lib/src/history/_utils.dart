int _identifierCounter = 0;

String generateIdentifier() {
  return 'loc_${_identifierCounter++}';
}
