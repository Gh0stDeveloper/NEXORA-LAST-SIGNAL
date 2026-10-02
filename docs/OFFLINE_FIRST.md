# Offline contract

## Acceptance rule

With the device in airplane mode and no previously established connection, a clean install must be able to:

1. launch;
2. load the local profile;
3. select an operator;
4. select campaign/waves/endless;
5. select difficulty and AI companion count;
6. enter the city;
7. move/aim/fire/reload/use melee;
8. run zombie AI and horde waves;
9. generate loot;
10. use inventory;
11. save/restore campaign checkpoints;
12. run the day/night cycle;
13. show gore and local audio;
14. finish or lose a run;
15. award XP/NXC;
16. return to the lobby;
17. relaunch and recover local progress.

Any failure caused solely by lack of Internet violates the project contract.

## Forbidden dependencies

Runtime may not require or include:

- HTTP clients;
- WebSockets;
- ENet;
- UDP/TCP gameplay transport;
- multiplayer peers;
- dedicated server code;
- matchmaking;
- social/account backends;
- login APIs;
- remote telemetry required by gameplay.

## Android

Required export state:

```text
permissions/internet=false
permissions/access_network_state=false
```

## Objetos3D

The separate `Gh0stDeveloper/Objetos3D` repository is excluded. Neither its vendor directory nor canonical external-model directory may be present.

## Enforcement

`tools/verify_offline.py` checks API tokens, forbidden paths, forbidden directories and Android permissions on every CI run.
