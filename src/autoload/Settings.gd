extends Node

signal quality_profile_changed(tier: int, profile: Dictionary)
signal gore_enabled_changed(enabled: bool)
signal camera_sensitivity_changed(value: float)
signal master_volume_changed(value: float)
signal music_volume_changed(value: float)
signal hud_layout_changed(element_id: StringName, value: Dictionary)

enum QualityTier { SMOOTH, STANDARD, ULTRA, ULTRA_HD }

const SETTINGS_SCHEMA_VERSION := 2
const SETTINGS_PATH := "user://last_signal_settings_v2.json"
const CAMERA_SENSITIVITY_MIN := 0.10
const CAMERA_SENSITIVITY_MAX := 1.00
const CAMERA_SENSITIVITY_DEFAULT := 0.50

var quality_tier: QualityTier = QualityTier.STANDARD
var gore_enabled := true
var camera_sensitivity := CAMERA_SENSITIVITY_DEFAULT
var master_volume := 1.0
var music_volume := 0.75
var audio_volumes := {"SFX": 1.0, "UI": 0.7, "Ambience": 0.7}
var hud_layout: Dictionary = {}

const QUALITY_PROFILES := {
	QualityTier.SMOOTH: {"render_scale":0.65,"gore_parts":4,"blood_emitters":2,"blood_particles":10,"decals":4,"limb_lifetime":5.0,"decal_lifetime":12.0,"horde_population":8,"horde_spawn_rate":0.85,"horde_squad_population_bonus":2},
	QualityTier.STANDARD: {"render_scale":0.90,"gore_parts":8,"blood_emitters":4,"blood_particles":18,"decals":6,"limb_lifetime":8.0,"decal_lifetime":20.0,"horde_population":14,"horde_spawn_rate":1.0,"horde_squad_population_bonus":3},
	QualityTier.ULTRA: {"render_scale":1.0,"gore_parts":16,"blood_emitters":6,"blood_particles":28,"decals":8,"limb_lifetime":12.0,"decal_lifetime":35.0,"horde_population":20,"horde_spawn_rate":1.15,"horde_squad_population_bonus":4},
	QualityTier.ULTRA_HD: {"render_scale":1.0,"gore_parts":28,"blood_emitters":8,"blood_particles":40,"decals":10,"limb_lifetime":16.0,"decal_lifetime":50.0,"horde_population":28,"horde_spawn_rate":1.30,"horde_squad_population_bonus":5},
}

func _ready() -> void:
	_load_settings()
	apply_audio_settings()

func current_profile() -> Dictionary:
	return QUALITY_PROFILES[quality_tier].duplicate(true)

func set_quality_tier(value: int) -> void:
	var next := clampi(value, QualityTier.SMOOTH, QualityTier.ULTRA_HD)
	quality_tier = next as QualityTier
	quality_profile_changed.emit(next, current_profile())
	_save_settings()

func set_gore_enabled(value: bool) -> void:
	gore_enabled = value
	gore_enabled_changed.emit(value)
	_save_settings()

func set_camera_sensitivity(value: float) -> void:
	camera_sensitivity = clampf(value, CAMERA_SENSITIVITY_MIN, CAMERA_SENSITIVITY_MAX)
	camera_sensitivity_changed.emit(camera_sensitivity)
	_save_settings()

func get_look_radians_per_pixel() -> float:
	return camera_sensitivity * 0.01

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume)
	master_volume_changed.emit(master_volume)
	_save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("Music", music_volume)
	music_volume_changed.emit(music_volume)
	_save_settings()

func get_audio_volume(bus: String) -> float:
	return float(audio_volumes.get(bus, 1.0))

func set_audio_volume(value: float, bus: String) -> void:
	if not audio_volumes.has(bus):
		return
	audio_volumes[bus] = clampf(value, 0.0, 1.0)
	_apply_bus_volume(bus, audio_volumes[bus])
	_save_settings()

func get_hud_element(element_id: StringName, fallback: Dictionary = {}) -> Dictionary:
	var stored: Variant = hud_layout.get(String(element_id), fallback)
	return stored.duplicate(true) if stored is Dictionary else fallback.duplicate(true)

func set_hud_element(element_id: StringName, value: Dictionary) -> void:
	hud_layout[String(element_id)] = {
		"x":clampf(float(value.get("x",0.5)),0.0,1.0),
		"y":clampf(float(value.get("y",0.5)),0.0,1.0),
		"scale":clampf(float(value.get("scale",1.0)),0.55,1.75),
		"opacity":clampf(float(value.get("opacity",0.82)),0.15,1.0),
		"visible":bool(value.get("visible",true)),
	}
	hud_layout_changed.emit(element_id, get_hud_element(element_id))
	_save_settings()

func reset_hud_layout() -> void:
	hud_layout.clear()
	hud_layout_changed.emit(&"*", {})
	_save_settings()

func save_configuration() -> void:
	_save_settings()

func apply_audio_settings() -> void:
	for bus in audio_volumes:
		_apply_bus_volume(bus, float(audio_volumes[bus]))
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("Music", music_volume)

func _apply_bus_volume(bus_name: String, linear_value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear_value, 0.0001)))
	AudioServer.set_bus_mute(index, linear_value <= 0.0001)

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	quality_tier = clampi(int(data.get("quality_tier",1)),0,3) as QualityTier
	gore_enabled = bool(data.get("gore_enabled",true))
	camera_sensitivity = clampf(float(data.get("camera_sensitivity",0.5)),CAMERA_SENSITIVITY_MIN,CAMERA_SENSITIVITY_MAX)
	master_volume = clampf(float(data.get("master_volume",1.0)),0.0,1.0)
	music_volume = clampf(float(data.get("music_volume",0.75)),0.0,1.0)
	if data.get("audio_volumes") is Dictionary:
		for bus in audio_volumes:
			audio_volumes[bus] = clampf(float(data.audio_volumes.get(bus,audio_volumes[bus])),0.0,1.0)
	if data.get("hud_layout") is Dictionary:
		hud_layout = Dictionary(data.hud_layout).duplicate(true)

func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"schema_version":SETTINGS_SCHEMA_VERSION,"quality_tier":int(quality_tier),"gore_enabled":gore_enabled,"camera_sensitivity":camera_sensitivity,"master_volume":master_volume,"music_volume":music_volume,"audio_volumes":audio_volumes,"hud_layout":hud_layout}, "\t"))
