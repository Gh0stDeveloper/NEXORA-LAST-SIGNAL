class_name DeadfallGuestIdentity
extends Node

signal identity_ready(snapshot: Dictionary)
signal username_changed(username: String)
signal selected_character_changed(character_id: StringName)
signal loadout_changed(primary_id: StringName, secondary_id: StringName)

const PROFILE_PATH := "user://last_signal_profile.json"
const DEFAULT_CHARACTER: StringName = &"operator_01"
const DEFAULT_PRIMARY: StringName = &"nxr_rifle_01"
const DEFAULT_SECONDARY: StringName = &"nxr_pistol_01"

var guest_id := ""
var username := "SURVIVOR"
var selected_character: StringName = DEFAULT_CHARACTER
var selected_primary: StringName = DEFAULT_PRIMARY
var selected_secondary: StringName = DEFAULT_SECONDARY
var created_unix := 0

func _ready() -> void:
	_load_or_create()
	identity_ready.emit(snapshot())

func snapshot() -> Dictionary:
	return {
		"guest_id":guest_id,
		"username":username,
		"selected_character":String(selected_character),
		"selected_primary":String(selected_primary),
		"selected_secondary":String(selected_secondary),
		"created_unix":created_unix,
		"offline":true,
	}

func has_local_credentials() -> bool:
	return not guest_id.is_empty()

func has_complete_profile() -> bool:
	return has_local_credentials() and not username.is_empty()

func is_valid_username(value: String) -> bool:
	var clean := value.strip_edges()
	return clean.length() >= 1 and clean.length() <= 16

func set_username(value: String) -> bool:
	var clean := value.strip_edges()
	if not is_valid_username(clean):
		return false
	username = clean
	_save()
	username_changed.emit(username)
	return true

func set_selected_character(character_id: StringName) -> void:
	if character_id.is_empty() or character_id == selected_character:
		return
	selected_character = character_id
	_save()
	selected_character_changed.emit(selected_character)

func set_loadout(primary_id: StringName, secondary_id: StringName) -> void:
	selected_primary = primary_id if not primary_id.is_empty() else DEFAULT_PRIMARY
	selected_secondary = secondary_id if not secondary_id.is_empty() else DEFAULT_SECONDARY
	_save()
	loadout_changed.emit(selected_primary, selected_secondary)

func account_path() -> String:
	return PROFILE_PATH

func _load_or_create() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				guest_id = String(parsed.get("guest_id",""))
				username = String(parsed.get("username","SURVIVOR"))
				selected_character = StringName(String(parsed.get("selected_character",String(DEFAULT_CHARACTER))))
				selected_primary = StringName(String(parsed.get("selected_primary",String(DEFAULT_PRIMARY))))
				selected_secondary = StringName(String(parsed.get("selected_secondary",String(DEFAULT_SECONDARY))))
				created_unix = int(parsed.get("created_unix",0))
	if guest_id.is_empty():
		guest_id = "local_%s" % str(Time.get_ticks_usec()).sha256_text().left(20)
		created_unix = int(Time.get_unix_time_from_system())
		_save()

func _save() -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot(), "\t"))
