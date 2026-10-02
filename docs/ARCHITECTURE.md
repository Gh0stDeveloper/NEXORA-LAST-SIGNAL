# Architecture

## Goal

NEXORA: LAST SIGNAL is a local-authority port of NEXORA: DEADFALL. Shared gameplay concepts remain, but the authoritative simulation is always inside the player's process.

## Runtime graph

```text
Game (autoload)
└─ LocalAuthority
   └─ damageables by entity id

Boot
├─ OfflineLobby
└─ LastSignalOutbreakDistrict
   ├─ CityArena / navigation
   ├─ DayNightCycle
   ├─ LocalPlayers
   │  ├─ Player_1
   │  └─ AI companions
   ├─ HordeZombies
   ├─ WorldPickups
   ├─ HordeDirector
   ├─ CampaignDirector
   ├─ AmmoDropDirector
   ├─ LootDirector
   ├─ BossDirector
   ├─ DifficultyDirector
   └─ HUD layers
```

## Authority

`Game.gd` exposes only `NONE` and `LOCAL`. It creates `LocalAuthority`, which registers health components and resolves damage through DEADFALL damage rules.

Compatibility methods `is_network_client()` and `is_dedicated_server()` return false unconditionally so retained local components can query session capability without linking network code.

## City

`CityLayout.gd` is deterministic and describes the 192×192 collision/world layout. `CityPresentation.gd` builds batched rendering. `CityArena.gd` generates navigation locally.

No server sends map state.

## Campaign

`CampaignDirector.gd` evaluates objectives on the local simulation authority. `CampaignSaveStore.gd` provides checksum-protected checkpoint persistence with backup recovery.

## Combat

Player weapons and infected damage resolve through `LocalAuthority`. There is no command transport, prediction/reconciliation requirement or remote damage resolver.

## Offline squad

`OfflineSquadDirector.gd` creates AI companions. `AICompanion.gd` follows the local player, selects infected targets and creates local damage events.

## Progression

`ProgressStore.gd` stores XP, NXC, level, best wave, completed missions and run count locally.

## Inventory and loot

`Inventory.gd` owns local items/weapons. `LootDirector.gd` creates `LootPickup.gd` objects from local zombie deaths.

## External model boundary

The separate Objetos3D repository is not part of this graph. `ExternalModelCatalog.gd` is an offline compatibility facade that never resolves an external model. DEADFALL's built-in procedural/skinned rigs provide the visual fallback.

## Presentation

The port retains DEADFALL tactical UI, mode art, operator avatars, local audio, procedural weapons, gore, lighting and HUD layout editor.

## Removed boundaries

The runtime contains no network, server, login or social module directories. CI checks this structurally and scans runtime resources for network APIs and forbidden module references.
