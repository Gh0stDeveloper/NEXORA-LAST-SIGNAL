# Changelog

## 0.3.0-alpha.1

### DEADFALL parity and offline expansion

- Restored the DEADFALL asynchronous splash/loading presentation for LAST SIGNAL.
- Rebuilt the lobby on the DEADFALL tactical layout: operator stage, party rail, navigation, mode selection, arsenal and visual polish.
- Replaced online party slots with SOLO, DÚO IA and ESCUADRA IA formations.
- Added Mission 03 — Blackout.
- Added Mission 04 — Final Signal.
- Added campaign targets/checkpoints for the expanded missions.
- Added NXR-7 Viper SMG.
- Added NXR-18 Marksman DMR.
- Added NXR-60 Bastion LMG.
- Added NXR-12 Hammer heavy sidearm.
- Added persistent local primary/secondary loadout selection.
- Added Titan boss shockwave behavior.
- Added Screamer Prime summon behavior.
- Added companion revive logic and role-specific AI tuning.
- Added Sentinel emergency support healing.
- Removed residual server fire/reload/melee APIs.
- Removed runtime network/replica snapshot compatibility from health, campaign, horde, zombies, pickups and gore.
- Removed dedicated-server presentation branches from the offline runtime.
- Hardened offline CI so legacy server/replica APIs are rejected if reintroduced.

## 0.2.0-alpha.1

### DEADFALL offline-port conversion

- Rebased LAST SIGNAL gameplay architecture around DEADFALL local systems.
- Removed server/network/login/social runtime dependencies.
- Added strict local-only `Game` authority.
- Ported DEADFALL city, campaign, checkpoints, horde, five zombie archetypes, weapons, HUD, HUD editor, gore, day/night and mobile performance systems.
- Ported DEADFALL audio, ambience, mode art, tactical UI resources and operator avatars.
- Kept built-in procedural/skinned operators and infected while excluding the separate Objetos3D repository.
- Added four-operator local roster: Valeria, Dante, Phoenix and Sentinel.
- Added offline campaign, 10-wave assault and endless modes.
- Added Story, Normal, Hard and Nightmare difficulty.
- Added local inventory and expanded loot drops.
- Added boss milestone encounters.
- Added 0–3 AI-controlled local companions.
- Added local XP/NXC/level/best-wave/mission progression.
- Added offline run result flow.
- Replaced network campaign scene nodes with LocalPlayers and local authority wiring.
- Added CI checks that reject networking APIs, online module references/directories, Objetos3D dependencies and Android Internet permissions.

## 0.1.0-alpha.1

- Initial standalone LAST SIGNAL offline prototype.
