class_name DeadfallGuestIdentity
extends Node

signal identity_ready(snapshot: Dictionary)
signal username_changed(username: String)
signal selected_character_changed(character_id: StringName)
signal loadout_changed(primary_id: StringName, secondary_id: StringName)
signal gender_changed(gender: String)
signal appearance_changed(snapshot: Dictionary)
signal profile_icon_changed(icon_id: StringName)

const Cosmetics = preload("res://src/customization/CosmeticCatalog.gd")
const PROFILE_PATH := "user://last_signal_profile.json"
const DEFAULT_CHARACTER: StringName = &"operator_01"
const DEFAULT_PRIMARY: StringName = &"nxr_rifle_01"
const DEFAULT_SECONDARY: StringName = &"nxr_pistol_01"

var guest_id := ""
var username := "SURVIVOR"
var selected_character: StringName = DEFAULT_CHARACTER
var selected_primary: StringName = DEFAULT_PRIMARY
var selected_secondary: StringName = DEFAULT_SECONDARY
var gender := "female"
var profile_icon: StringName = &"profile_medic"
var equipped_cosmetics_by_gender: Dictionary = {}
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
		"gender":gender,
		"profile_icon":String(profile_icon),
		"equipped_cosmetics_by_gender":equipped_cosmetics_by_gender.duplicate(true),
		"appearance":appearance_snapshot(),
		"created_unix":created_unix,
		"offline":true,
	}

func appearance_snapshot() -> Dictionary:
	return {
		"gender":gender,
		"profile_icon":String(profile_icon),
		"cosmetics":get_equipped_cosmetics(),
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

func set_gender(value: String) -> bool:
	var next_gender := "male" if value.to_lower() == "male" else "female"
	if next_gender == gender:
		return true
	gender = next_gender
	_ensure_gender_loadout(gender)
	var current_icon := Cosmetics.get_item(profile_icon)
	if current_icon.is_empty() or not Cosmetics.is_compatible(current_icon, gender):
		profile_icon = Cosmetics.default_profile_icon(gender)
		profile_icon_changed.emit(profile_icon)
	_save()
	gender_changed.emit(gender)
	appearance_changed.emit(appearance_snapshot())
	return true

func set_profile_icon(item_id: StringName) -> bool:
	var item := Cosmetics.get_item(item_id)
	if item.is_empty() or String(item.get("category","")) != "profile_icon":
		return false
	if not Cosmetics.is_compatible(item, gender):
		return false
	if profile_icon == item_id:
		return true
	profile_icon = item_id
	_save()
	profile_icon_changed.emit(profile_icon)
	appearance_changed.emit(appearance_snapshot())
	return true

func equip_cosmetic(category: String, item_id: StringName) -> bool:
	if category not in Cosmetics.CATEGORIES:
		return false
	var item := Cosmetics.get_item(item_id)
	if item.is_empty() or String(item.get("category","")) != category:
		return false
	if not Cosmetics.is_compatible(item, gender):
		return false
	_ensure_gender_loadout(gender)
	var loadout: Dictionary = Dictionary(equipped_cosmetics_by_gender.get(gender, Cosmetics.default_loadout(gender))).duplicate(true)
	if String(loadout.get(category,"")) == String(item_id):
		return true
	loadout[category] = String(item_id)
	equipped_cosmetics_by_gender[gender] = Cosmetics.sanitize_loadout(loadout, gender)
	_save()
	appearance_changed.emit(appearance_snapshot())
	return true

func get_equipped_cosmetics() -> Dictionary:
	_ensure_gender_loadout(gender)
	return Dictionary(equipped_cosmetics_by_gender.get(gender, Cosmetics.default_loadout(gender))).duplicate(true)

func account_path() -> String:
	return PROFILE_PATH

func _load_or_create() -> void:
	var parsed: Dictionary = {}
	if FileAccess.file_exists(PROFILE_PATH):
		var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
		if file != null:
			var value = JSON.parse_string(file.get_as_text())
			if value is Dictionary:
				parsed = value
	if not parsed.is_empty():
		guest_id = String(parsed.get("guest_id",""))
		username = String(parsed.get("username","SURVIVOR"))
		selected_character = StringName(String(parsed.get("selected_character",String(DEFAULT_CHARACTER))))
		selected_primary = StringName(String(parsed.get("selected_primary",String(DEFAULT_PRIMARY))))
		selected_secondary = StringName(String(parsed.get("selected_secondary",String(DEFAULT_SECONDARY))))
		created_unix = int(parsed.get("created_unix",0))
		gender = _normalize_gender(String(parsed.get("gender", _legacy_gender(selected_character))))
		var stored_cosmetics = parsed.get("equipped_cosmetics_by_gender", {})
		if stored_cosmetics is Dictionary:
			equipped_cosmetics_by_gender = Dictionary(stored_cosmetics).duplicate(true)
		elif parsed.get("equipped_cosmetics", {}) is Dictionary:
			equipped_cosmetics_by_gender[gender] = Dictionary(parsed.get("equipped_cosmetics", {})).duplicate(true)
		profile_icon = StringName(String(parsed.get("profile_icon", String(Cosmetics.default_profile_icon(gender)))))
	else:
		gender = "female"
		profile_icon = Cosmetics.default_profile_icon(gender)

	_ensure_gender_loadout("female")
	_ensure_gender_loadout("male")
	var icon_item := Cosmetics.get_item(profile_icon)
	if icon_item.is_empty() or not Cosmetics.is_compatible(icon_item, gender):
		profile_icon = Cosmetics.default_profile_icon(gender)

	if guest_id.is_empty():
		guest_id = "local_%s" % str(Time.get_ticks_usec()).sha256_text().left(20)
	if created_unix <= 0:
		created_unix = int(Time.get_unix_time_from_system())
	_save()

func _ensure_gender_loadout(value: String) -> void:
	var key := _normalize_gender(value)
	var stored = equipped_cosmetics_by_gender.get(key, {})
	var loadout := Dictionary(stored) if stored is Dictionary else {}
	equipped_cosmetics_by_gender[key] = Cosmetics.sanitize_loadout(loadout, key)

func _legacy_gender(character_id: StringName) -> String:
	return "female" if character_id == &"operator_01" else "male"

func _normalize_gender(value: String) -> String:
	return "male" if value.to_lower() == "male" else "female"

func _save() -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot(), "\t"))
