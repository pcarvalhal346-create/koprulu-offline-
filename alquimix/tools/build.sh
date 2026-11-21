#!/usr/bin/env bash
# Builds Alquimix from the command line with Defold's bob.jar.
#   BOB=/path/to/bob.jar tools/build.sh web|pages|android|check [release|debug]
#   pages: release web build + iPhone-friendly page (manifest, icons) copied to
#          ../docs/alquimix, ready for GitHub Pages ("Deploy from a branch", folder /docs).
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
    echo "Serve with: python3 -m http.server 8000 --directory dist/web/Alquimix" ;;
  pages)
    "$JAVA" -jar "$BOB" --root . --variant release --archive --platform wasm-web --architectures wasm-web \
      --bundle-output dist/web build bundle
    OUT="../docs/alquimix"
    rm -rf "$OUT" && mkdir -p "$OUT"
    cp -r dist/web/Alquimix/. "$OUT/"
    cp tools/web/index.html tools/web/manifest.webmanifest tools/web/icon-*.png "$OUT/"
    touch ../docs/.nojekyll
    echo "GitHub Pages build ready in $OUT" ;;
  android)
    "$JAVA" -jar "$BOB" --root . --variant "$VARIANT" --archive --platform arm64-android --architectures arm64-android,armv7-android \
      --bundle-format apk --bundle-output dist/android build bundle ;;
  *) echo "unknown target $TARGET"; exit 1 ;;
esac
