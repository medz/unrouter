#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_dart_package_checks() {
  local package_dir="$1"

  echo "==> Checking ${package_dir}"
  (
    cd "${ROOT_DIR}/${package_dir}"
    dart pub get
    dart analyze
    dart test
  )
}

run_flutter_package_checks() {
  local package_dir="$1"

  echo "==> Checking ${package_dir}"
  (
    cd "${ROOT_DIR}/${package_dir}"
    flutter pub get
    flutter analyze
    flutter test
  )
}

echo "==> Resolving workspace dependencies"
(
  cd "${ROOT_DIR}"
  dart pub get
)

run_dart_package_checks "pub/unrouter"
run_flutter_package_checks "pub/flutter_unrouter"
run_dart_package_checks "pub/jaspr_unrouter"

echo "==> Workspace checks passed"
