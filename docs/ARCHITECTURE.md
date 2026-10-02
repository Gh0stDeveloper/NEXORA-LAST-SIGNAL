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

Legacy network/dedicated compatibility methods were removed. Retained gameplay components now call local authority directly.

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


## DEADFALL presentation flow

```text
Boot.tscn
└─ DEADFALL-style asynchronous splash
   └─ Lobby.tscn
      ├─ TacticalBackdrop
      ├─ OperatorStage
      ├─ PartyRail (local player + AI)
      ├─ Arsenal
      ├─ Difficulty
      ├─ Mode/Mission picker
      └─ MatchLoadingOverlay
         └─ OutbreakDistrict
```

The loading/lobby layer contains no matchmaking, social or account service dependency.

## Weapon selection

`WeaponCatalog.gd` maps local weapon IDs to `WeaponData` resources. `GuestIdentity` persists the selected primary and secondary IDs; the arena applies those resources before the player enters the scene tree.

## Boss abilities

`BossDirector.gd` creates milestone bosses and attaches `BossBehavior.gd`. Titan performs local shockwave damage; Screamer Prime creates local infected reinforcements through the horde director.
