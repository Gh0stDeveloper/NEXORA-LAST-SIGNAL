# Testing and CI

## Local preflight

Run from the repository root:

```bash
python tools/verify_offline.py
python -m py_compile tools/verify_offline.py
godot --headless --editor --path . --quit
godot --headless --path . --script scripts/ci/smoke.gd
godot --headless --path . --script scripts/ci/gameplay_smoke.gd
```

## Smoke test coverage

### Project smoke

`scripts/ci/smoke.gd` verifies:

- required source/configuration files exist;
- runtime scripts compile and can instantiate;
- `SaveSystem` and `GameState` autoloads are present;
- the configured boot scene loads and instantiates;
- the boot scene creates its initial UI.

### Gameplay smoke

`scripts/ci/gameplay_smoke.gd` verifies:

- player starting health/ammunition contract;
- damage and healing behavior;
- Tank death reward values;
- wave-one population formula;
- early-wave archetype selection.

## CI workflow

`.github/workflows/ci.yml` runs on `main`, pull requests and manual dispatch. A change is considered valid only when the offline audit, Godot import/parse and both smoke tests succeed.

## Android build workflow

`.github/workflows/android-debug.yml` performs:

1. JDK 17 setup.
2. Android SDK/API 36 tooling setup.
3. Godot 4.6.3 and export-template setup.
4. Project import.
5. ARM64 debug export.
6. Ephemeral CI keystore creation.
7. APK signing.
8. APK signature verification.
9. Artifact upload.

The CI signing key is temporary and is not suitable for app-store or persistent production distribution.

## Release acceptance checklist

Before treating an Android build as a release candidate, also test on physical hardware:

- clean install;
- launch with airplane mode enabled;
- start a game without any network connection;
- move/look/fire/reload/jump with touch controls;
- survive at least three waves;
- pause and resume;
- die and return to menu;
- verify XP/NXC/best wave persistence after app restart;
- check thermal behavior and frame pacing for at least 15 minutes;
- verify the APK does not request Internet permission.
