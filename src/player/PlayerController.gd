class_name DeadfallPlayerController
extends CharacterBody3D

enum Stance { STAND, CROUCH, PRONE }
enum ControlMode { OFFLINE_LOCAL }

@export_category("Movement")
@export var walk_speed := 4.5
@export var sprint_speed := 7.5
@export var crouch_speed := 2.8
@export var prone_speed := 1.6
@export var jump_velocity := 5.2
@export var ground_acceleration := 22.0
@export var air_acceleration := 7.0
@export_category("Look")
@export var look_sensitivity := 0.0025
@export_category("Stance")
@export var standing_height := 1.80
@export var crouch_height := 1.25
@export var prone_height := 0.80
@export var standing_eye_height := 1.62
@export var crouch_eye_height := 1.08
@export var prone_eye_height := 0.58
@export var player_entity_id := 1
@export var control_mode: int = ControlMode.OFFLINE_LOCAL

@onready var input_source: DeadfallPlayerInput = $PlayerInput
@onready var health: Node = $Health
@onready var life_state: Node = $LifeState
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual_root: Node3D = $VisualRoot
@onready var visual_body: MeshInstance3D = get_node_or_null("VisualRoot/Body")
@onready var camera_rig: DeadfallCameraRig = $CameraRig

var stance: Stance = Stance.STAND
var _gravity := 9.8
var _jump_serial := 0
var _crouch_serial := 0
var _prone_serial := 0

func _enter_tree() -> void:
	preload("res://src/core/PresentationRuntime.gd").attach_actor(self, "res://src/player/PlayerPresentation.tscn", false)

func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	if collision_shape.shape != null:
		collision_shape.shape = collision_shape.shape.duplicate(true)
	camera_rig.camera_mode_changed.connect(_on_camera_mode_changed)
	if life_state != null and life_state.has_signal("state_changed"):
		life_state.connect("state_changed", Callable(self,"_on_life_state_changed"))
	_apply_stance_geometry(stance)
	camera_rig.set_camera_enabled(true)
	_on_camera_mode_changed(int(camera_rig.mode))

func _physics_process(delta: float) -> void:
	if _life_is_dead():
		velocity = Vector3.ZERO
		return
	camera_rig.set_aiming(input_source.is_action_pressed(&"aim"), delta)
	_apply_local_look(input_source.consume_look_delta())
	if input_source.consume_action_just_pressed(&"camera_cycle"):
		camera_rig.cycle_camera()
	if input_source.consume_action_just_pressed(&"crouch"):
		_crouch_serial += 1
		_try_set_stance(Stance.STAND if stance == Stance.CROUCH else Stance.CROUCH)
	if input_source.consume_action_just_pressed(&"prone"):
		_prone_serial += 1
		_try_set_stance(Stance.STAND if stance == Stance.PRONE else Stance.PRONE)
	var jump := input_source.consume_action_just_pressed(&"jump")
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = -0.1
		if jump and stance != Stance.PRONE:
			velocity.y = jump_velocity
	else:
		velocity.y -= _gravity * delta
	var move := input_source.get_move_vector()
	var sprint := input_source.is_action_pressed(&"sprint") and not _life_is_downed()
	if sprint:
		_try_set_stance(Stance.STAND)
	var local_direction := Vector3(move.x,0.0,move.y)
	var world_direction := (global_transform.basis * local_direction).normalized()
	var speed := _target_speed(sprint) * _life_move_multiplier()
	var target := world_direction * speed
	var accel := ground_acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x,target.x,accel*delta)
	velocity.z = move_toward(velocity.z,target.z,accel*delta)
	preload("res://src/core/CharacterMovement.gd").move(self,delta)

func configure_local_identity(entity_id: int = 1) -> void:
	player_entity_id = entity_id
	health.set("entity_id", entity_id)
	for path in ["PrimaryWeapon","SecondaryWeapon","MacheteWeapon"]:
		var weapon := get_node_or_null(path)
		if weapon != null and weapon.get("shooter_entity_id") != null:
			weapon.set("shooter_entity_id",entity_id)

func can_use_weapon() -> bool:
	return life_state == null or bool(life_state.call("can_use_weapon"))

func is_recoverable() -> bool:
	return life_state == null or bool(life_state.call("is_recoverable"))

func get_stance_name() -> String:
	return Stance.keys()[int(stance)]

func _apply_local_look(delta: Vector2) -> void:
	if delta.is_zero_approx():
		return
	var sensitivity := float(Settings.get_look_radians_per_pixel()) if Settings != null else look_sensitivity
	rotation.y -= delta.x * sensitivity
	camera_rig.add_pitch(-delta.y * sensitivity)

func _target_speed(sprint: bool) -> float:
	match stance:
		Stance.CROUCH: return crouch_speed
		Stance.PRONE: return prone_speed
		_: return sprint_speed if sprint else walk_speed

func _try_set_stance(target: Stance) -> bool:
	if target == stance:
		return true
	var target_height := _height_for_stance(target)
	if target_height > _height_for_stance(stance) and not _can_fit_height(target_height):
		return false
	stance = target
	_apply_stance_geometry(target)
	return true

func _can_fit_height(target_height: float) -> bool:
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null or not is_inside_tree():
		return true
	var shape := CapsuleShape3D.new()
	shape.radius = capsule.radius
	shape.height = target_height
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.transform = Transform3D(global_basis,global_position+Vector3.UP*(target_height*0.5+0.025))
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func _apply_stance_geometry(target: Stance) -> void:
	var h := _height_for_stance(target)
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule != null:
		capsule.height = h
		collision_shape.position.y = h*0.5
	if visual_body != null:
		visual_body.scale.y = h/standing_height
		visual_body.position.y = h*0.5
	camera_rig.position.y = _eye_height_for_stance(target)

func _height_for_stance(value: Stance) -> float:
	if value == Stance.CROUCH: return crouch_height
	if value == Stance.PRONE: return prone_height
	return standing_height

func _eye_height_for_stance(value: Stance) -> float:
	if value == Stance.CROUCH: return crouch_eye_height
	if value == Stance.PRONE: return prone_eye_height
	return standing_eye_height

func _on_camera_mode_changed(mode: int) -> void:
	visual_root.visible = mode != DeadfallCameraRig.CameraMode.FIRST_PERSON

func _on_life_state_changed(_previous: int, current: int, _reason: String) -> void:
	if current == 1:
		_try_set_stance(Stance.PRONE)
	elif current == 2:
		velocity = Vector3.ZERO

func _life_is_downed() -> bool:
	return life_state != null and bool(life_state.call("is_downed"))

func _life_is_dead() -> bool:
	return life_state != null and bool(life_state.call("is_dead"))

func _life_move_multiplier() -> float:
	return float(life_state.call("get_movement_multiplier")) if life_state != null else 1.0
