# Testing

## CI gates

The repository uses two workflows.

### CI

Runs:

1. Python syntax check for the offline auditor.
2. Strict offline/module audit.
3. Godot 4.6.3 installation.
4. Full editor import/resource compilation.
5. Project/lobby/scene smoke test.
6. Local-authority gameplay smoke test.

The gameplay smoke validates:

- LocalAuthority is active;
- no network/dedicated session mode is possible;
- local player health registers with authority;
- local damage resolves;
- inventory add/consume works;
- horde scaling works;
- only offline modes are active;
- external Objetos3D models cannot resolve;
- campaign checkpoint save/restore works.

### Android Debug Build

Runs Android SDK/JDK/Godot setup, exports ARM64, signs with an ephemeral debug key, verifies the APK and uploads the artifact.

## Local commands

```bash
python tools/verify_offline.py
godot --headless --editor --path . --quit
godot --headless --path . --script scripts/ci/smoke.gd
godot --headless --path . --script scripts/ci/gameplay_smoke.gd
```

## Physical-device acceptance

Test with airplane mode enabled:

- clean install and launch;
- lobby/operator selection;
- each game mode;
- each difficulty;
- 0 and 3 AI companions;
- all weapon slots;
- inventory/loot;
- checkpoint restart;
- at least five waves and a boss milestone;
- HUD editing + restart persistence;
- day/night transition;
- background/resume;
- death/result/lobby flow;
- relaunch and progress persistence;
- confirm Android does not request Internet permission.
