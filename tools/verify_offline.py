from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
RUNTIME_EXTENSIONS = {".gd", ".tscn", ".godot", ".cfg", ".tres", ".gdshader"}
FORBIDDEN_TOKENS = {
    "HTTPRequest": "HTTP networking API",
    "HTTPClient": "HTTP networking API",
    "ENetMultiplayerPeer": "ENet networking API",
    "WebSocketPeer": "WebSocket networking API",
    "WebSocketMultiplayerPeer": "WebSocket networking API",
    "PacketPeerUDP": "UDP networking API",
    "StreamPeerTCP": "TCP networking API",
    "TCPServer": "TCP networking API",
    "MultiplayerAPI": "multiplayer runtime",
    "MultiplayerPeer": "multiplayer runtime",
    "multiplayer_peer": "multiplayer runtime",
    "res://src/network/": "DEADFALL network module reference",
    "res://src/server/": "DEADFALL server module reference",
    "res://src/social/": "DEADFALL social module reference",
    "res://src/login/": "DEADFALL login module reference",
    "res://vendor/Objetos3D": "external Objetos3D dependency",
    "res://assets/external/objetos3d": "external Objetos3D dependency",
    "http://": "runtime URL dependency",
    "https://": "runtime URL dependency",
}
FORBIDDEN_DIRS = [
    ROOT / "src/network",
    ROOT / "src/server",
    ROOT / "src/social",
    ROOT / "src/login",
    ROOT / "vendor/Objetos3D",
    ROOT / "assets/external/objetos3d",
]

violations: list[tuple[Path, str, str]] = []
for directory in FORBIDDEN_DIRS:
    if directory.exists():
        violations.append((directory.relative_to(ROOT), "directory", "forbidden online/external module"))

runtime_files = [ROOT / "project.godot", ROOT / "export_presets.cfg"]
runtime_files += [
    path for path in (ROOT / "src").rglob("*")
    if path.is_file() and path.suffix in RUNTIME_EXTENSIONS
]
for path in runtime_files:
    if not path.exists():
        continue
    content = path.read_text(encoding="utf-8", errors="ignore")
    for token, reason in FORBIDDEN_TOKENS.items():
        if token in content:
            violations.append((path.relative_to(ROOT), token, reason))

preset = ROOT / "export_presets.cfg"
if not preset.exists():
    violations.append((Path("export_presets.cfg"), "missing", "Android export contract"))
else:
    content = preset.read_text(encoding="utf-8", errors="ignore")
    required = [
        "permissions/internet=false",
        "permissions/access_network_state=false",
    ]
    for token in required:
        if token not in content:
            violations.append((Path("export_presets.cfg"), token, "offline Android permission contract missing"))
    for token in ("permissions/internet=true", "permissions/access_network_state=true"):
        if token in content:
            violations.append((Path("export_presets.cfg"), token, "network permission enabled"))

if violations:
    print("Offline DEADFALL-port audit FAILED")
    for path, token, reason in violations:
        print(f"- {path}: {token} ({reason})")
    sys.exit(1)

print("Offline DEADFALL-port audit passed: no network/server/social/login runtime, no Objetos3D dependency, and Android networking permissions are disabled.")
