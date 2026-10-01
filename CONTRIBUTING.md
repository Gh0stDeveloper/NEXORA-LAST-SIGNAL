# Contributing

## Core rule

NEXORA: LAST SIGNAL is offline-first. Gameplay changes must not add a required network service, account system, matchmaking dependency or cloud-only state.

## Branches

Use focused branches and Conventional Commit-style messages where practical, for example:

```text
feat(combat): add pistol weapon slot
fix(mobile): prevent fire button from sticking
ci(android): verify signed debug artifact
```

## Required validation

Before opening a pull request:

```bash
python tools/verify_offline.py
godot --headless --editor --path . --quit
godot --headless --path . --script scripts/ci/smoke.gd
godot --headless --path . --script scripts/ci/gameplay_smoke.gd
```

Do not commit generated `.godot/`, `build/`, APK/AAB files, keystores or signing secrets.
