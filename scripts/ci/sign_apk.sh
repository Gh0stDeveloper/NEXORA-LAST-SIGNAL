#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <unsigned.apk> <signed.apk> <keystore> <alias>" >&2
  exit 64
fi

UNSIGNED_APK="$1"
SIGNED_APK="$2"
KEYSTORE="$3"
KEY_ALIAS="$4"
: "${APK_SIGNING_PASSWORD:?APK_SIGNING_PASSWORD must be set}"

test -s "$UNSIGNED_APK"
test -s "$KEYSTORE"

BUILD_TOOLS_DIR="$(find "${ANDROID_HOME:?ANDROID_HOME must be set}/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)"
ZIPALIGN="$BUILD_TOOLS_DIR/zipalign"
APKSIGNER="$BUILD_TOOLS_DIR/apksigner"
test -x "$ZIPALIGN"
test -x "$APKSIGNER"

mkdir -p "$(dirname "$SIGNED_APK")"
ALIGNED_APK="${SIGNED_APK%.apk}-aligned.apk"
REPORT="${SIGNED_APK%.apk}-signatures.txt"

"$ZIPALIGN" -f -p 4 "$UNSIGNED_APK" "$ALIGNED_APK"

"$APKSIGNER" sign   --ks "$KEYSTORE"   --ks-key-alias "$KEY_ALIAS"   --ks-pass env:APK_SIGNING_PASSWORD   --key-pass env:APK_SIGNING_PASSWORD   --v1-signing-enabled true   --v2-signing-enabled true   --v3-signing-enabled true   --v4-signing-enabled true   --out "$SIGNED_APK"   "$ALIGNED_APK"

rm -f "$ALIGNED_APK"
test -s "$SIGNED_APK"
test -s "$SIGNED_APK.idsig"

V1_REPORT="$(mktemp)"
ALL_REPORT="$(mktemp)"
trap 'rm -f "$V1_REPORT" "$ALL_REPORT"' EXIT

"$APKSIGNER" verify   --verbose   --print-certs   --min-sdk-version 21   --max-sdk-version 23   "$SIGNED_APK" >"$V1_REPORT"

if ! "$APKSIGNER" verify   --verbose   --print-certs   --v4-signature-file "$SIGNED_APK.idsig"   "$SIGNED_APK" >"$ALL_REPORT" 2>&1; then
  "$APKSIGNER" verify     --verbose     --print-certs     -v4-signature-file "$SIGNED_APK.idsig"     "$SIGNED_APK" >"$ALL_REPORT"
fi

grep -Fq "Verified using v1 scheme (JAR signing): true" "$V1_REPORT"
grep -Fq "Verified using v2 scheme (APK Signature Scheme v2): true" "$ALL_REPORT"
grep -Fq "Verified using v3 scheme (APK Signature Scheme v3): true" "$ALL_REPORT"
grep -Fq "Verified using v4 scheme (APK Signature Scheme v4): true" "$ALL_REPORT"

{
  echo "NEXORA: LAST SIGNAL Android signature verification"
  echo
  echo "APK: $(basename "$SIGNED_APK")"
  echo "IDSIG: $(basename "$SIGNED_APK.idsig")"
  echo
  echo "V1 compatibility verification (API 21-23):"
  cat "$V1_REPORT"
  echo
  echo "V2/V3/V4 verification:"
  cat "$ALL_REPORT"
} >"$REPORT"

cat "$REPORT"
