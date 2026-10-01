# NEXORA: LAST SIGNAL

[![CI](https://github.com/Gh0stDeveloper/NEXORA-LAST-SIGNAL/actions/workflows/ci.yml/badge.svg)](https://github.com/Gh0stDeveloper/NEXORA-LAST-SIGNAL/actions/workflows/ci.yml)
[![Android Debug Build](https://github.com/Gh0stDeveloper/NEXORA-LAST-SIGNAL/actions/workflows/android-debug.yml/badge.svg)](https://github.com/Gh0stDeveloper/NEXORA-LAST-SIGNAL/actions/workflows/android-debug.yml)
![Godot](https://img.shields.io/badge/Godot-4.6.3-478CBF?logo=godot-engine&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Mode](https://img.shields.io/badge/Mode-100%25%20Offline-111827)
![Status](https://img.shields.io/badge/Status-Alpha-orange)

**NEXORA: LAST SIGNAL** is an Android-first 3D zombie survival shooter built with **Godot 4.6.3**. It follows the survival-combat direction explored in NEXORA: DEADFALL while being a completely separate game and codebase designed around one hard requirement: **the complete gameplay loop must work locally without Internet access or a backend**.

> Current version: **0.1.0-alpha.1**

## Project goals

- Deliver a responsive mobile zombie-survival experience that remains playable offline.
- Keep all combat, AI, waves, progression, settings, rewards and saves on the device.
- Use Android as the primary target while retaining keyboard/mouse support for development.
- Keep the runtime independent from matchmaking, accounts, dedicated servers, HTTP APIs and cloud services.
- Maintain a CI pipeline that validates both the offline contract and an installable Android build.

## Current playable foundation

| Area | Implemented |
| --- | --- |
| Player | First-person movement, sprint, jump, camera look, health |
| Combat | Automatic hitscan rifle, finite magazine, reserve ammunition, reload |
| Enemies | Walker, Runner, Crawler, Screamer and Tank variants |
| AI | Local chase, melee attack, damage and death |
| Survival | Infinite wave director, spawn budget and increasing pressure |
| Progression | Local XP, NXC, level calculation and best-wave record |
| UI | Main menu, HUD, crosshair, pause overlay and Game Over summary |
| Input | Keyboard/mouse test controls and Android touch controls |
| Persistence | Local profile stored at `user://profile.json` |
| Rendering | Godot Mobile renderer baseline |
| CI | Offline audit, Godot import/parse, smoke tests and Android ARM64 debug APK |

## 100% offline contract

The gameplay runtime does **not** require any of the following:

- account or login;
- Internet connection;
- matchmaking;
- dedicated or relay servers;
- HTTP/REST APIs;
- WebSockets;
- ENet multiplayer;
- UDP/TCP gameplay transport;
- cloud saves.

The Android export preset explicitly keeps `INTERNET` and `ACCESS_NETWORK_STATE` disabled. CI also scans runtime files for networking APIs and URLs. See [docs/OFFLINE_FIRST.md](docs/OFFLINE_FIRST.md) for the contract and enforcement rules.

## Gameplay loop

1. Start a local survival session from the main menu.
2. Fight progressively larger zombie waves.
3. Earn XP and NXC for eliminations.
4. Survive as many waves as possible.
5. Return to the menu with the run summary.
6. Keep level, currency and best-wave progress locally on the device.

No network state participates in this loop.

## Enemy roster

| Archetype | Role | Current behavior |
| --- | --- | --- |
| Walker | Baseline threat | Balanced health, speed and melee damage |
| Runner | Pressure | Lower health, much faster movement |
| Crawler | Fast low-profile threat | Lower body profile and faster approach |
| Screamer | Specialist foundation | Distinct statistics and presentation; advanced scream behavior is planned |
| Tank | Heavy threat | High health, slow movement and high melee damage |

## Controls

### Desktop development controls

| Input | Action |
| --- | --- |
| `W`, `A`, `S`, `D` | Move |
| `Shift` | Sprint |
| `Space` | Jump |
| Mouse | Look |
| Hold left mouse button | Fire |
| `R` | Reload |
| `Esc` | Pause |

### Android controls

- Left-side drag: movement.
- Right-side drag: camera.
- Hold **DISPARAR**: automatic fire.
- **RECARGAR**: reload.
- **SALTAR**: jump.
- Pause button: pause/resume the local simulation.

## Technology

- [Godot Engine 4.6.3](https://godotengine.org/)
- GDScript
- Godot Mobile renderer
- GitHub Actions
- Python 3 for static CI audits
- Android ARM64 export target
- JDK 17 for Android tooling

## Repository layout

```text
NEXORA-LAST-SIGNAL/
├── .github/workflows/
│   ├── ci.yml
│   └── android-debug.yml
├── docs/
│   ├── ARCHITECTURE.md
│   ├── OFFLINE_FIRST.md
│   ├── ROADMAP.md
│   └── TESTING.md
├── scripts/ci/
│   ├── gameplay_smoke.gd
│   └── smoke.gd
├── src/
│   ├── autoload/
│   │   ├── GameState.gd
│   │   └── SaveSystem.gd
│   ├── enemies/
│   │   └── Zombie.gd
│   ├── game/
│   │   ├── GameWorld.gd
│   │   └── HordeDirector.gd
│   ├── main/
│   │   ├── Boot.gd
│   │   └── Boot.tscn
│   ├── player/
│   │   └── Player.gd
│   └── ui/
│       ├── HUD.gd
│       └── MobileControls.gd
├── tools/
│   └── verify_offline.py
├── export_presets.cfg
├── project.godot
└── VERSION
```

For component responsibilities and runtime flow, read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Run locally

### Requirements

- Godot **4.6.3** recommended.
- Desktop: Linux, Windows or macOS for development.
- Android export: Android SDK, platform/build tools for API 36 and JDK 17.

### Editor

```bash
git clone https://github.com/Gh0stDeveloper/NEXORA-LAST-SIGNAL.git
cd NEXORA-LAST-SIGNAL
godot --editor project.godot
```

Open the project and run `src/main/Boot.tscn` through the configured main scene.

### Headless validation

```bash
python tools/verify_offline.py
godot --headless --editor --path . --quit
godot --headless --path . --script scripts/ci/smoke.gd
godot --headless --path . --script scripts/ci/gameplay_smoke.gd
```

## Android build

The repository includes the `Android Debug` export preset. A local unsigned debug export can be created with:

```bash
mkdir -p build/android
godot --headless --path . --export-debug "Android Debug" build/android/NEXORA-LAST-SIGNAL-debug.apk
```

GitHub Actions performs a stronger path: it installs Godot export templates, configures Android tooling, exports an ARM64 APK, signs it with an **ephemeral CI debug key**, verifies the signature and uploads the APK as a workflow artifact.

The CI key is intentionally temporary and must **not** be used as a production/release signing identity.

## Continuous integration

### `CI`

Runs on pushes and pull requests targeting `main` and checks:

1. Python audit-tool syntax.
2. Offline/networking contract.
3. Godot 4.6.3 setup.
4. Full headless project import and resource parsing.
5. Main scene/autoload smoke test.
6. Player, zombie and wave gameplay contracts.

### `Android Debug Build`

Builds and validates an installable ARM64 APK using Android API 36 tooling. The resulting APK is available in the workflow artifacts as:

```text
NEXORA-LAST-SIGNAL-android-debug
```

Detailed commands and failure criteria are documented in [docs/TESTING.md](docs/TESTING.md).

## Save data

Player data is stored locally at:

```text
user://profile.json
```

Current persisted fields include:

```json
{
  "version": 1,
  "coins": 0,
  "xp": 0,
  "level": 1,
  "best_wave": 0,
  "settings": {
    "sensitivity": 0.16,
    "master_volume": 0.8,
    "show_mobile_controls": true
  }
}
```

The save layer merges missing fields with defaults so future schema additions can remain backward-compatible.

## Development principles

1. **Offline first:** gameplay must never depend on an external service.
2. **Local authority:** AI, damage, rewards and wave state are calculated on-device.
3. **Deterministic ownership:** the local game owns the session state; there is no remote authority layer.
4. **Android first:** touch usability and mobile performance are primary constraints.
5. **CI-gated changes:** broken scripts, broken scenes, networking regressions and failed Android exports should be caught before release.
6. **Separate identity:** this project is not a branch or offline mode of DEADFALL; it is an independent title.

## Roadmap

The next production milestones cover:

- reusable weapon/loadout architecture;
- ADS, recoil, spread and melee;
- pickups, healing and ammunition economy;
- campaign missions and checkpoints;
- larger destroyed-city environments;
- day/night cycle and lighting polish;
- animation state machines and hit reactions;
- original audio and ambience;
- improved zombie archetype behaviors and bosses;
- offline AI companions and squad commands;
- configurable mobile HUD;
- graphics/performance presets for Android;
- multiple local save slots and difficulty modes;
- signed release pipeline once a production keystore is intentionally configured.

See [docs/ROADMAP.md](docs/ROADMAP.md) for the phased plan.

## Relationship to NEXORA: DEADFALL

NEXORA: LAST SIGNAL is inspired by the gameplay direction and lessons learned from **NEXORA: DEADFALL**, but it intentionally removes the multiplayer/backend architecture. DEADFALL remains a separate project; changes here must not modify or depend on its repository, services or deployment infrastructure.

## Contributing

Before opening a pull request:

```bash
python tools/verify_offline.py
godot --headless --editor --path . --quit
godot --headless --path . --script scripts/ci/smoke.gd
godot --headless --path . --script scripts/ci/gameplay_smoke.gd
```

Any change that introduces a required network dependency into runtime gameplay violates the core project contract. Additional conventions are in [CONTRIBUTING.md](CONTRIBUTING.md).

## Project owner

**Ghost Developer / Nexora**  
GitHub: [@Gh0stDeveloper](https://github.com/Gh0stDeveloper)

---

NEXORA: LAST SIGNAL is currently in active alpha development. Systems, assets, balancing and presentation will evolve while the offline-first contract remains a permanent architectural requirement.
