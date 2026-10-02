# NEXORA: LAST SIGNAL

[![CI](https://github.com/Gh0stDeveloper/NEXORA-LAST-SIGNAL/actions/workflows/ci.yml/badge.svg)](https://github.com/Gh0stDeveloper/NEXORA-LAST-SIGNAL/actions/workflows/ci.yml)
[![Android Debug Build](https://github.com/Gh0stDeveloper/NEXORA-LAST-SIGNAL/actions/workflows/android-debug.yml/badge.svg)](https://github.com/Gh0stDeveloper/NEXORA-LAST-SIGNAL/actions/workflows/android-debug.yml)
![Godot](https://img.shields.io/badge/Godot-4.6.3-478CBF?logo=godot-engine&logoColor=white)
![Android](https://img.shields.io/badge/Android-ARM64-3DDC84?logo=android&logoColor=white)
![Offline](https://img.shields.io/badge/runtime-100%25%20offline-111827)

**NEXORA: LAST SIGNAL** is the offline edition/port of the gameplay experience developed for **NEXORA: DEADFALL**. Instead of reproducing DEADFALL approximately, this repository reuses its local gameplay, presentation, campaign, city, HUD, combat, zombie, audio, gore and operator systems while removing the online architecture.

The permanent runtime rule is simple:

> **A player must be able to launch and play the complete game without Internet access, a server, an account service, matchmaking or any remote API.**

Current version: **0.3.0-alpha.1**

## What is retained from DEADFALL

The offline port reuses or adapts the local DEADFALL systems that do not require a backend:

| Area | LAST SIGNAL |
| --- | --- |
| Tactical visual language | Retained |
| Quarantine hangar presentation | Retained |
| Operator/character presentation | Retained using built-in procedural/skinned rigs |
| Operator avatars | Retained |
| Mobile HUD | Retained |
| Custom HUD layout editor | Retained |
| First/third-person camera system | Retained |
| Walk/sprint/jump/crouch/prone | Retained |
| NXR-4, NXR-9 and machete | Retained |
| DEADFALL splash/loading screen | Retained and converted to local-only loading |
| DEADFALL tactical lobby | Retained and converted to local operators/AI squad |
| Hitscan/local damage authority | Retained |
| Campaign framework | Retained |
| Mission 01 · First Signal | Retained |
| Mission 02 · Last Broadcast | Retained |
| Checkpoint persistence | Retained locally |
| 192×192 destroyed-city layout | Retained |
| Enterable ruined structures | Retained |
| Destroyed/burning vehicles | Retained |
| Day/night cycle | Retained |
| Walker | Retained |
| Runner | Retained |
| Crawler | Retained |
| Screamer | Retained |
| Tank | Retained |
| Horde director | Retained |
| Ammo/health drops | Retained |
| Gore/dismemberment system | Retained |
| Mobile performance profiles | Retained |
| DEADFALL audio and ambience | Retained |
| Mode artwork | Retained as bundled local assets |

LAST SIGNAL adds an offline-only layer around those systems: local progression, inventory, expanded loot, difficulty profiles, boss encounters and AI-controlled squad companions.

## What was removed

The following DEADFALL areas are deliberately not part of the runtime:

- ENet or any other multiplayer transport;
- dedicated-server runtime;
- matchmaking;
- online party synchronization;
- login/authentication services;
- social/friends/messages services;
- remote telemetry;
- backend APIs;
- deployment/VPS infrastructure;
- web portal dependencies;
- network replication/snapshot APIs and remote-authority compatibility branches.

The Android package is exported with both Internet and network-state permissions disabled.

## External 3D repository exclusion

The separate **Gh0stDeveloper/Objetos3D** repository is intentionally **not** vendored, cloned or required by LAST SIGNAL.

Excluded paths include:

```text
vendor/Objetos3D
assets/external/objetos3d
```

DEADFALL's built-in procedural/skinned operator and infected presentation remains available, so operators, avatars, weapons and zombies continue to have a complete local visual representation without that external repository.

## DEADFALL loading and lobby

The startup flow uses the DEADFALL presentation structure directly: tactical backdrop, Rajdhani typography, large NEXORA title treatment, asynchronous progress bar, quarantine hangar art and the tactical operator lobby. Online party/matchmaking actions were replaced by local formation controls for SOLO, DÚO IA and ESCUADRA IA. The lobby retains the 3D operator stage, party rail, arsenal, settings, mode cards and DEADFALL visual-polish layer.

## Offline game modes

### Campaign

Campaign runs entirely on-device. Objectives, kills, survival timers, interactions, checkpoints and mission completion are evaluated by local simulation authority.

Included mission definitions:

- **Mission 01 · First Signal**
- **Mission 02 · Last Broadcast**
- **Mission 03 · Blackout**
- **Mission 04 · Final Signal**

Campaign checkpoint data is stored locally with checksum and backup recovery.

### Assault · 10 Waves

Survive ten escalating waves. The offline director controls population, spawn timing, archetype selection, loot and boss milestones.

### Endless

Infinite horde survival using the same local simulation, progression, loot and difficulty systems.

## Offline squad

The lobby can launch a run with **0–3 AI companions**.

Companions:

- follow the local player;
- acquire nearby infected;
- fire locally simulated weapons;
- receive local health/damage;
- count toward horde squad scaling;
- use the same built-in operator presentation system;
- revive the player when downed;
- provide role-specific combat behavior;
- Sentinel can provide local emergency healing support.

No companion state is transmitted anywhere.

## Operators

Current local operator roster:

- **VALERIA** — Reconocimiento
- **DANTE** — Vanguardia
- **PHOENIX** — Asalto
- **SENTINEL** — Soporte

The selected operator is stored on-device.

## Combat and weapons

The DEADFALL combat stack is reused locally:

- **NXR-4 Carbine**
- **NXR-7 Viper** — SMG
- **NXR-18 Marksman** — DMR
- **NXR-60 Bastion** — LMG
- **NXR-9 Sidearm**
- **NXR-12 Hammer** — heavy sidearm
- **Machete**
- finite magazines/reserve ammunition;
- automatic reload/fallback;
- local raycast hit resolution;
- body-part hitboxes;
- critical/body-part damage rules;
- melee resolution;
- first-person procedural weapon presentation;
- local weapon audio.

The local inventory tracks weapon ownership and loot independently from any online account.

## Loot and inventory

LAST SIGNAL adds a local inventory and world-loot layer.

Current loot categories include:

- ammunition boxes;
- medkits;
- scrap;
- weapon parts.

Loot is generated on-device when infected die and never requires an API or inventory server.

## Zombies and bosses

DEADFALL archetypes are retained:

- Walker
- Runner
- Crawler
- Tank
- Screamer

LAST SIGNAL adds milestone bosses every five waves:

- **Titan** — heavy infected with a close-range shockwave.
- **Screamer Prime** — elite Screamer that periodically calls additional infected.

Boss health, damage and ability cadence scale with wave progression and difficulty.

## Difficulty

Four local profiles are available from the lobby:

| Difficulty | Intent |
| --- | --- |
| Story | Reduced enemy pressure/damage |
| Normal | Baseline DEADFALL-style balance |
| Hard | Increased health, damage and spawn pressure |
| Nightmare | Maximum local pressure |

Difficulty modifies simulation values directly in the device runtime.

## City and day/night cycle

The retained campaign city uses the DEADFALL 192×192 deterministic layout, including:

- streets/intersections;
- sidewalks;
- enterable ruined buildings;
- interior collision;
- damaged roofs/walls;
- destroyed cars;
- burning wrecks;
- vegetation;
- street furniture;
- skyline;
- quarantine props;
- local navigation mesh.

The day/night controller modifies sun, moon, sky, fog, ambient lighting and shadow budgets without any clock/server dependency.

## HUD

The DEADFALL mobile HUD remains the gameplay HUD and includes:

- movement joystick;
- touch look;
- fire;
- aim;
- reload;
- jump;
- sprint;
- crouch;
- prone;
- flashlight;
- camera switching;
- weapon selection;
- HP/ammunition display;
- crosshair;
- quick sensitivity control;
- **HUD layout editor** with drag, resize, reset and local save.

An offline inventory panel is also available in-game.

## Audio

Bundled DEADFALL audio includes:

- rifle;
- pistol;
- reload;
- dry fire;
- melee;
- impacts;
- footsteps;
- zombie growls;
- zombie attacks;
- zombie deaths;
- UI click/confirm/error;
- `last_signal.ogg`;
- `quarantine_wind.ogg`.

All files are packaged with the game. Playback does not stream media from the Internet.

## Save data

LAST SIGNAL uses local files under `user://`:

```text
last_signal_profile.json
last_signal_settings_v2.json
last_signal_progress.json
campaign_last_signal_campaign.json
```

Campaign saves use a temporary file + backup + checksum strategy inherited from DEADFALL's campaign persistence.

## Architecture

```text
Boot
└── Offline Lobby
    └── Offline operation
        ├── LocalAuthority
        ├── CityArena
        │   ├── local NavigationRegion
        │   └── DayNightCycle
        ├── Player
        │   ├── Health/LifeState
        │   ├── WeaponLoadout
        │   └── Inventory
        ├── 0–3 AI companions
        ├── HordeDirector
        │   └── local Zombie instances
        ├── CampaignDirector
        │   └── local checkpoints
        ├── DifficultyDirector
        ├── BossDirector
        ├── LootDirector
        ├── Gore
        ├── MobileHUD
        └── InventoryHUD
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Strict offline audit

`tools/verify_offline.py` fails CI if runtime code contains or restores:

- HTTP clients;
- ENet;
- WebSocket;
- UDP/TCP networking;
- Godot multiplayer APIs;
- references to `src/network`, `src/server`, `src/social` or `src/login`;
- references to the excluded Objetos3D runtime paths;
- legacy server/replica APIs such as `server_try_*`, `apply_network_snapshot` and `apply_replica_*`;
- Android Internet/network-state permissions.

It also fails if forbidden online/external directories are physically present.

## Development and validation

Recommended engine:

```text
Godot 4.6.3
```

Run the offline audit:

```bash
python tools/verify_offline.py
```

Import/compile all resources:

```bash
godot --headless --editor --path . --quit
```

Run smoke tests:

```bash
godot --headless --path . --script scripts/ci/smoke.gd
godot --headless --path . --script scripts/ci/gameplay_smoke.gd
```

## Android

Target:

- Android
- ARM64
- Godot Mobile renderer
- package `com.nexora.lastsignal`

The debug workflow installs Godot 4.6.3 export templates, Android tooling and JDK 17, exports the APK, signs it with an ephemeral CI key, verifies its signature and uploads it as a workflow artifact.

No production keystore is stored in this repository.

## Controls

Desktop/development:

| Input | Action |
| --- | --- |
| W/A/S/D | Move |
| Shift | Sprint |
| Space | Jump |
| C | Crouch |
| Z | Prone |
| V | Cycle camera |
| F | Flashlight |
| E | Interact |
| Left mouse | Fire |
| Right mouse | Aim |
| R | Reload |
| 1/2/3 | Weapon slots |
| Q | Next weapon |
| I | Inventory |

Android uses the DEADFALL touch HUD and its customizable layout.

## Repository policy

Any feature may be expanded as long as it does not make the game depend on connectivity. Optional future online code must live outside the runtime used by LAST SIGNAL and may not weaken the offline acceptance test.

## Credits

Project owner/developer: **Ghost Developer / Nexora**

Presentation/audio credits retained from DEADFALL are documented in:

```text
assets/PRESENTATION_CREDITS.txt
```

---

**NEXORA: LAST SIGNAL is intended to preserve the DEADFALL gameplay experience while making local/offline execution the only required authority path.**
