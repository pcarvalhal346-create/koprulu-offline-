#!/usr/bin/env bash
# Builds Elemental Chaos from the command line with Defold's bob.jar.
#   BOB=/path/to/bob.jar tools/build.sh web|android|check [release|debug]
# bob.jar must match a recent stable Defold (developed against 1.14.1, which needs Java 25).
# Downloads: https://github.com/defold/defold/releases (asset "bob.jar").
set -euo pipefail
cd "$(dirname "$0")/.."
BOB="${BOB:-bob.jar}"
JAVA="${JAVA:-java}"
TARGET="${1:-check}"
VARIANT="${2:-release}"
case "$TARGET" in
  check)
    "$JAVA" -jar "$BOB" --root . --variant debug build ;;
  web)
    "$JAVA" -jar "$BOB" --root . --variant "$VARIANT" --archive --platform wasm-web --architectures wasm-web \
      --bundle-output dist/web build bundle
    echo "Serve with: python3 -m http.server 8000 --directory dist/web/ElementalChaos" ;;
  android)
    "$JAVA" -jar "$BOB" --root . --variant "$VARIANT" --archive --platform arm64-android --architectures arm64-android,armv7-android \
      --bundle-format apk --bundle-output dist/android build bundle ;;
  *) echo "unknown target $TARGET"; exit 1 ;;
esac
