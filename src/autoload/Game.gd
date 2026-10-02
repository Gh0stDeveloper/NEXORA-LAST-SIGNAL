extends Node

const LocalAuthorityScript = preload("res://src/core/authority/LocalAuthority.gd")

enum SessionMode { NONE, LOCAL }

var session_mode: SessionMode = SessionMode.NONE
var authority: RefCounted

func _ready() -> void:
	start_local_session()

func start_local_session() -> void:
	if authority != null:
		authority.stop()
	authority = LocalAuthorityScript.new()
	session_mode = SessionMode.LOCAL
	authority.start()

func stop_session() -> void:
	if authority != null:
		authority.stop()
	authority = null
	session_mode = SessionMode.NONE

func is_local_session() -> bool:
	return session_mode == SessionMode.LOCAL and authority != null

func is_simulation_authority() -> bool:
	return is_local_session()

# Compatibility for shared DEADFALL gameplay components. These are permanently
# false in LAST SIGNAL; there is no remote transport or server authority.
func is_network_client() -> bool:
	return false

func is_dedicated_server() -> bool:
	return false

func get_active_authority() -> RefCounted:
	return authority
