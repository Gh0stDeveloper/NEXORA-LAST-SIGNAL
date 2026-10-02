# Android public releases

NEXORA: LAST SIGNAL publishes installable Android APKs through GitHub Releases.

## Release signing

Public releases use a persistent Android signing identity stored only in GitHub Actions Secrets. Never commit the keystore or its password.

Required repository secrets:

- `LAST_SIGNAL_ANDROID_KEYSTORE_B64` — Base64-encoded release keystore.
- `LAST_SIGNAL_ANDROID_KEYSTORE_ALIAS` — alias inside the keystore.
- `LAST_SIGNAL_ANDROID_KEYSTORE_PASSWORD` — keystore/key password.

The same signing key must be preserved for all future direct-distribution updates.

## Signature schemes

The release workflow explicitly enables and verifies:

- V1 (JAR signing)
- V2
- V3
- V4

V4 is detached and produces `<apk>.idsig`. The APK remains the normal file users install. The `.idsig` file is also attached to each release for incremental-install use.

## Publishing

The workflow is `.github/workflows/release.yml`.

It runs on:

- tags matching `v*`; or
- manual `workflow_dispatch`.

The tag must match `v<VERSION>`. For example, VERSION `0.3.0-alpha.1` publishes tag `v0.3.0-alpha.1`.

Each release contains:

- signed ARM64 APK;
- V4 `.idsig`;
- signature verification report;
- SHA-256 checksums;
- release manifest.

Versions containing a hyphen, such as alpha/beta/rc builds, are published as GitHub prereleases. Stable semantic versions are published as normal releases.
