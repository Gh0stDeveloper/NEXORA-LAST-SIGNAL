from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
RUNTIME_EXTENSIONS = {".gd", ".tscn", ".godot", ".cfg", ".tres"}
FORBIDDEN = {
    "HTTPRequest": "HTTP networking",
    "HTTPClient": "HTTP networking",
    "ENetMultiplayerPeer": "ENet networking",
    "WebSocketPeer": "WebSocket networking",
    "WebSocketMultiplayerPeer": "WebSocket networking",
    "PacketPeerUDP": "UDP networking",
    "StreamPeerTCP": "TCP networking",
    "TCPServer": "TCP networking",
    "MultiplayerAPI": "multiplayer runtime",
    "MultiplayerPeer": "multiplayer runtime",
    "multiplayer_peer": "multiplayer runtime",
    "http://": "runtime URL dependency",
    "https://": "runtime URL dependency",
}

violations: list[tuple[Path, str, str]] = []
for path in ROOT.rglob("*"):
    if path.is_dir() or ".git" in path.parts or path.suffix not in RUNTIME_EXTENSIONS:
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    for token, reason in FORBIDDEN.items():
        if token in text:
            violations.append((path.relative_to(ROOT), token, reason))

preset = ROOT / "export_presets.cfg"
if not preset.exists():
    violations.append((Path("export_presets.cfg"), "missing", "Android export contract"))
else:
    preset_text = preset.read_text(encoding="utf-8", errors="ignore")
    for permission in ("permissions/internet=true", "permissions/access_network_state=true"):
        if permission in preset_text:
            violations.append((Path("export_presets.cfg"), permission, "network permission enabled"))

if violations:
    print("Offline audit FAILED")
    for path, token, reason in violations:
        print(f"- {path}: {token} ({reason})")
    sys.exit(1)

print("Offline audit passed: runtime contains no networking APIs/URLs and Android network permissions are disabled.")
