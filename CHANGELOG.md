# Changelog

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
