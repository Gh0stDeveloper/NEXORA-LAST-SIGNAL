# Architecture

## Overview

NEXORA: LAST SIGNAL is a single-device simulation. The executable owns all gameplay state and never delegates authoritative decisions to a server.

```text
Boot
 ├─ SaveSystem ── user://profile.json
 └─ GameWorld
     ├─ Player
     ├─ HordeDirector
     │   └─ Zombie instances
     ├─ HUD
     └─ MobileControls (Android/mobile only)
```

## Autoloads

### `SaveSystem`

Owns local persistent profile data. It loads defaults, merges an existing save, recalculates derived level state and writes JSON to `user://profile.json`.

### `GameState`

Owns one active run's transient statistics: kills, NXC, XP, wave, shots and hits. Rewards are forwarded to `SaveSystem` immediately so progression is not dependent on a clean application exit.

## Boot layer

`Boot.tscn` is the configured main scene. `Boot.gd` creates the main menu, reads local profile data and launches a new `GameWorld` instance.

## World layer

`GameWorld.gd` creates the prototype environment, player, local horde director, HUD and optional mobile controls. It is also responsible for pause/resume, Game Over and returning to the main menu.

## Combat

`Player.gd` owns movement, camera rotation, local hitscan ray queries, ammunition, health and input. Hits are resolved directly against local physics objects.

There is no command queue, reconciliation, packet transport or remote authority step.

## Zombie simulation

`Zombie.gd` runs entirely through local physics processing. A zombie receives a local player reference, approaches it, attacks in melee range, accepts local damage and emits a local death/reward signal.

`HordeDirector.gd` controls wave number, spawn counts, population pressure and archetype selection. All timers and counters live in the local scene tree.

## UI

`HUD.gd` subscribes to local player and horde signals. `MobileControls.gd` translates touch gestures/buttons directly into methods on the local `Player` object.

## Data boundaries

Persistent:

- XP
- NXC
- level
- best wave
- settings

Session-only:

- current health
- current ammo
- current wave population
- run kills
- run rewards
- shot/hit counters

## Dependency rule

Runtime code must not introduce a required network client, socket, multiplayer peer or remote API. CI enforces this rule through `tools/verify_offline.py` and Android export permission checks.
