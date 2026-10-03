class_name DeadfallPlayerModelPresenter
extends Node3D

const ProceduralCharacters = preload("res://src/assets/ProceduralCharacterModel.gd")
const UniversalAnimations = preload("res://src/assets/UniversalAnimationLibrary.gd")
const ATTACK_PRESENTATION_USEC := 360_000
const JUMP_START_PRESENTATION_USEC := 170_000
const LAND_PRESENTATION_USEC := 240_000

@export var fallback_body_path := NodePath("../Body")

var _fallback_body: GeometryInstance3D
var _loaded_model: Node3D
var _character_id: StringName = &"operator_01"
var _appearance: Dictionary = {}
var _appearance_signature := ""
var _animation_status: Dictionary = {}
var _elapsed := 0.0
var _semantic_state: StringName = &"idle"
var _last_action_sequences := {0: 0, 1: 0, 2: 0}
var _attack_until_usec := 0
var _jump_start_until_usec := 0
var _land_until_usec := 0
var _was_on_floor := true
var _visuals_enabled := true

func _ready() -> void:
	_fallback_body = get_node_or_null(fallback_body_path) as GeometryInstance3D
	if DisplayServer.get_name() == "headless":
		_visuals_enabled = false
		visible = false
		set_process(false)
		return
	if GuestIdentity != null:
		_appearance = GuestIdentity.appearance_snapshot()
		_appearance_signature = JSON.stringify(_appearance)
		if GuestIdentity.has_signal("appearance_changed"):
			GuestIdentity.appearance_changed.connect(_on_identity_appearance_changed)
	set_process(true)
	call_deferred("configure_character", _character_id)

func _process(delta: float) -> void:
	if not _visuals_enabled or _loaded_model == null:
		return
	_elapsed += delta
	var owner := _owner_body()
	if owner == null:
		return
	_update_jump_state(owner)
	_detect_weapon_action()
	var desired := _desired_semantic_state(owner)
	_semantic_state = desired
	var planar_speed := Vector2(owner.velocity.x, owner.velocity.z).length()
	if _loaded_model.has_method("animate_pose"):
		_loaded_model.call("animate_pose", _elapsed, planar_speed, desired)
	var loadout := owner.get_node_or_null("WeaponLoadout")
	if loadout != null and _loaded_model.has_method("equip_visual"):
		_loaded_model.call("equip_visual", int(loadout.get("active_slot")))
	_animation_status = {
		"ok":true,
		"source":"supplied_animation_library",
		"semantic":String(desired),
		"source_sha256":UniversalAnimations.SOURCE_SHA256,
	}

func configure_character(character_id: StringName) -> bool:
	_character_id = character_id if not character_id.is_empty() else &"operator_01"
	if GuestIdentity != null and _appearance.is_empty():
		_appearance = GuestIdentity.appearance_snapshot()
		_appearance_signature = JSON.stringify(_appearance)
	return _rebuild_model()

func configure_appearance(value: Dictionary) -> bool:
	var next := value.duplicate(true)
	var signature := JSON.stringify(next)
	if signature == _appearance_signature and _loaded_model != null:
		return true
	_appearance = next
	_appearance_signature = signature
	return _rebuild_model()

func _rebuild_model() -> bool:
	if not _visuals_enabled:
		return false
	if _loaded_model != null and is_instance_valid(_loaded_model):
		_loaded_model.queue_free()
	_loaded_model = ProceduralCharacters.create_operator(_character_id, 0, _appearance)
	if _loaded_model == null:
		_set_fallback_visible(true)
		return false
	_loaded_model.name = "UniversalOperatorModel"
	add_child(_loaded_model)
	_loaded_model.call("equip_visual", 0)
	_set_fallback_visible(false)
	_semantic_state = &"idle"
	_elapsed = 0.0
	_last_action_sequences = {0:0,1:0,2:0}
	_attack_until_usec = 0
	_jump_start_until_usec = 0
	_land_until_usec = 0
	var owner := _owner_body()
	_was_on_floor = owner.is_on_floor() if owner != null else true
	_animation_status = {
		"ok":true,
		"source":"supplied_animation_library",
		"semantic":"idle",
		"source_sha256":UniversalAnimations.SOURCE_SHA256,
	}
	return true

func _owner_body() -> CharacterBody3D:
	var visual_root := get_parent()
	return visual_root.get_parent() as CharacterBody3D if visual_root != null else null

func _update_jump_state(owner: CharacterBody3D) -> void:
	var on_floor := owner.is_on_floor()
	var now := Time.get_ticks_usec()
	if _was_on_floor and not on_floor and owner.velocity.y > 0.05:
		_jump_start_until_usec = now + JUMP_START_PRESENTATION_USEC
		_land_until_usec = 0
	elif not _was_on_floor and on_floor:
		_land_until_usec = now + LAND_PRESENTATION_USEC
		_jump_start_until_usec = 0
	_was_on_floor = on_floor

func _detect_weapon_action() -> void:
	var context := _weapon_context()
	if context.is_empty():
		return
	var slot := int(context.get("slot",0))
	var weapon_state: Dictionary = context.get("state",{})
	var sequence := int(weapon_state.get("last_sequence",0))
	var previous := int(_last_action_sequences.get(slot,0))
	if sequence > previous:
		_last_action_sequences[slot] = sequence
		_attack_until_usec = Time.get_ticks_usec() + ATTACK_PRESENTATION_USEC

func _weapon_context() -> Dictionary:
	var owner := _owner_body()
	if owner == null:
		return {}
	var loadout := owner.get_node_or_null("WeaponLoadout")
	if loadout == null or not loadout.has_method("get_authoritative_state"):
		return {}
	var state: Dictionary = loadout.call("get_authoritative_state")
	var slot := clampi(int(state.get("active_slot",0)),0,2)
	var weapon_state: Dictionary
	match slot:
		1:
			weapon_state = Dictionary(state.get("secondary",{}))
		2:
			weapon_state = Dictionary(state.get("melee",{}))
		_:
			weapon_state = Dictionary(state.get("primary",{}))
	return {"slot":slot,"state":weapon_state}

func _desired_semantic_state(owner: CharacterBody3D) -> StringName:
	var life_state := owner.get_node_or_null("LifeState")
	if life_state != null:
		var raw_state = life_state.get("state")
		var life := int(raw_state) if raw_state != null else 0
		if life == 2:
			return &"death"
		if life == 1:
			return &"crawl"

	var now := Time.get_ticks_usec()
	if now < _jump_start_until_usec:
		return &"jump_start"
	if not owner.is_on_floor():
		return &"jump"
	if now < _land_until_usec:
		return &"jump_land"

	var context := _weapon_context()
	var slot := int(context.get("slot",0))
	var weapon_state: Dictionary = context.get("state",{})
	if bool(weapon_state.get("reloading",false)):
		return &"reload"
	if now < _attack_until_usec:
		return &"melee" if slot == 2 else &"attack"

	var stance_value = owner.get("stance")
	var stance := int(stance_value) if stance_value != null else 0
	var planar_speed := Vector2(owner.velocity.x, owner.velocity.z).length()
	if stance == 2:
		return &"crawl"
	if stance == 1:
		return &"crouch_walk" if planar_speed > 0.18 else &"crouch_idle"

	var input_source := owner.get_node_or_null("PlayerInput")
	if input_source != null and slot == 1 and input_source.has_method("is_action_pressed"):
		if bool(input_source.call("is_action_pressed",&"aim")):
			return &"aim"
	if planar_speed > 5.8:
		return &"run"
	if planar_speed > 0.22:
		return &"walk"
	return &"idle"

func current_character_id() -> StringName:
	return _character_id

func current_appearance() -> Dictionary:
	return _appearance.duplicate(true)

func has_external_model() -> bool:
	return _loaded_model != null and is_instance_valid(_loaded_model)

func get_animation_status() -> Dictionary:
	return _animation_status.duplicate(true)

func get_semantic_state() -> StringName:
	return _semantic_state

func get_semantic_inventory() -> Dictionary:
	var result := {}
	for clip_name in UniversalAnimations.data().get("clips",{}).keys():
		result[String(clip_name)] = String(clip_name)
	return result

func _on_identity_appearance_changed(value: Dictionary) -> void:
	configure_appearance(value)

func _set_fallback_visible(value: bool) -> void:
	if _fallback_body != null:
		_fallback_body.visible = value
