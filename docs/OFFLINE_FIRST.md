# Offline-first contract

## Requirement

A player must be able to install NEXORA: LAST SIGNAL, disable Internet connectivity, launch the game, start a session, fight waves, earn progression, change settings, die, return to the menu and relaunch with saved progress intact.

## Forbidden runtime dependencies

The core game may not require:

- HTTP/HTTPS APIs;
- WebSocket services;
- ENet multiplayer;
- UDP/TCP gameplay sockets;
- account authentication;
- matchmaking;
- cloud save providers;
- dedicated servers;
- telemetry required for normal execution.

## Android permissions

`export_presets.cfg` keeps these permissions disabled:

```text
permissions/internet=false
permissions/access_network_state=false
```

`VIBRATE` may remain enabled for future local haptic feedback because it is not a network capability.

## CI enforcement

`tools/verify_offline.py` scans Godot runtime resources for networking classes and URL literals. It also fails if Android networking permissions become enabled.

This audit is intentionally conservative. If a future optional online feature is ever considered, it must not become a dependency of gameplay and the architectural contract must be revised explicitly rather than bypassing the audit.
