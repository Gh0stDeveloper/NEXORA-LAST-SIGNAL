# Changelog

## 1.0.0rc

### Animation, profile, cosmetics and automatic public distribution

- Integrated the supplied humanoid animation library into the universal operator presentation.
- Added movement, crouch, jump, landing, pistol, reload, melee, damage, interaction and death animation states.
- Added female and male presentation variants on the same gameplay character.
- Added persistent offline profile, avatar selection and gender selection.
- Added cosmetic inventory with clothing, caps, glasses, shirts, pants and shoes.
- Added an offline NXC shop and persistent ownership/equipment state.
- Added differentiated cosmetic appearances for offline AI companions.
- Added validation coverage for animation clips, wardrobe compatibility and profile starter items.
- Public Android release builds now run automatically on every push to `main`.
- The current version tag is repointed to the exact validated commit and public release assets are replaced automatically after a successful build.

### Lobby, loading and branding release candidate

- Added a guaranteed visible DEADFALL-style loading transition before every match.
- Added loading briefing details for mode, mission, difficulty and local AI formation.
- Pauses the arena while the loading transition finishes, preventing gameplay from starting behind the overlay.
- Added persistent quick-select buttons for Campaign, Assault and Endless directly in the lobby.
- Added a MODOS navigation entry and retained the full visual mode picker with artwork.
- Enhanced the lobby background with the DEADFALL quarantine hangar presentation, stronger tactical overlays and version information.
- Added a dedicated LAST SIGNAL application icon and wired it through `project.godot`.
- Promoted public-facing version name to `1.0.0rc`.
- Replaced the old Android version code with the simpler internal code `10000`.
- Updated GitHub Release prerelease detection so `rc` versions remain prereleases.
- Reworked the README into a release-candidate quality project overview.

## 0.3.0-alpha.1

### Distribution

- Added public GitHub Release automation for Android.
- Added persistent release-signing contract through GitHub Actions Secrets.
- Added explicit APK Signature Scheme V1, V2, V3 and V4 signing and verification.
- Added V4 `.idsig`, SHA-256 checksums, signature report and release manifest assets.

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
