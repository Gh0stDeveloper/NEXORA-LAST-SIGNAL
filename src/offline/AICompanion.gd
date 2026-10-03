class_name LastSignalAICompanion
extends CharacterBody3D

const HealthScript = preload("res://src/core/health/HealthComponent.gd")
const LifeStateScript = preload("res://src/player/PlayerLifeState.gd")
const DamageEventScript = preload("res://src/core/damage/DamageEvent.gd")
const ProceduralCharacters = preload("res://src/assets/ProceduralCharacterModel.gd")

@export var player_entity_id := 101
@export var operator_id: StringName = &"operator_02"

var leader: Node3D
var move_speed := 4.6
var attack_range := 22.0
var fire_interval := 0.58

var _fire_cooldown := 0.0
var _target: Node3D
var _target_scan := 0.0
var _revive_elapsed := 0.0
var _revive_chase_elapsed := 0.0
var _revive_target: Node3D
var _support_cooldown := 0.0
var _model: Node3D
var _animation_time := 0.0
var health: Node
var life_state: Node

func _ready() -> void:
	add_to_group("deadfall_player")
	add_to_group("last_signal_companion")

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.40
	capsule.height = 1.80
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

	health = HealthScript.new()
	health.name = "Health"
	health.entity_id = player_entity_id
	health.max_health = 100.0
	add_child(health)

	life_state = LifeStateScript.new()
	life_state.name = "LifeState"
	life_state.health_path = NodePath("../Health")
	life_state.downed_enabled = true
	life_state.bleedout_seconds = 34.0
	life_state.revive_hold_seconds = 2.6
	life_state.revive_distance = 2.8
	life_state.revive_health_fraction = 0.40
	life_state.downed_move_multiplier = 0.0
	add_child(life_state)

	_apply_role_profile()
	_model = ProceduralCharacters.create_operator(operator_id, player_entity_id % 4)
	_model.name = "OperatorVisual"
	add_child(_model)

func configure(entity_id: int, character: StringName, squad_leader: Node3D) -> void:
	player_entity_id = entity_id
	operator_id = character
	leader = squad_leader

func get_entity_id() -> int:
	return player_entity_id

func is_downed() -> bool:
	return life_state != null and bool(life_state.call("is_downed"))

func is_dead() -> bool:
	return life_state != null and bool(life_state.call("is_dead"))

func _apply_role_profile() -> void:
	match operator_id:
		&"operator_03":
			fire_interval = 0.42
			attack_range = 20.0
			move_speed = 5.0
		&"operator_04":
			fire_interval = 0.68
			attack_range = 24.0
			move_speed = 4.35
		&"operator_01":
			fire_interval = 0.54
			attack_range = 28.0
			move_speed = 4.8
		_:
			fire_interval = 0.56
			attack_range = 22.0
			move_speed = 4.6

func _physics_process(delta: float) -> void:
	if health == null or bool(health.call("is_dead")) or is_dead():
		velocity = Vector3.ZERO
		return
	if is_downed():
		velocity = Vector3.ZERO
		_revive_target = null
		_revive_elapsed = 0.0
		_revive_chase_elapsed = 0.0
		_animate_model()
		return

	_animation_time += delta
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_support_cooldown = maxf(0.0, _support_cooldown - delta)

	var candidate := _find_revive_candidate()
	if candidate != null:
		if candidate != _revive_target:
			_clear_target_progress()
			_revive_target = candidate
			_revive_elapsed = 0.0
			_revive_chase_elapsed = 0.0
		_process_revive(delta)
		_animate_model()
		return
	else:
		_clear_target_progress()
		_revive_target = null
		_revive_elapsed = 0.0
		_revive_chase_elapsed = 0.0

	_try_support_heal()

	_target_scan -= delta
	if _target_scan <= 0.0:
		_target_scan = 0.25
		_target = _find_target()

	if _target != null and is_instance_valid(_target):
		var distance := global_position.distance_to(_target.global_position)
		if distance <= attack_range:
			var flat := _target.global_position - global_position
			flat.y = 0.0
			if flat.length_squared() > 0.01:
				look_at(global_position + flat.normalized(), Vector3.UP)
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
			if _fire_cooldown <= 0.0:
				_fire_cooldown = fire_interval
				_attack_target(_target)
		else:
			_move_toward_point(_target.global_position, delta)
	elif leader != null and is_instance_valid(leader):
		var offset := Vector3(float((player_entity_id % 3) - 1) * 1.8, 0, 2.2 + float(player_entity_id % 2))
		var goal := leader.global_position + leader.global_basis * offset
		if global_position.distance_to(goal) > 2.2:
			_move_toward_point(goal, delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()
	_animate_model()

func _find_revive_candidate() -> Node3D:
	if leader != null and is_instance_valid(leader) and _node_is_downed(leader):
		return leader
	var best: Node3D
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("deadfall_player"):
		var member := node as Node3D
		if member == null or member == self or not is_instance_valid(member) or not _node_is_downed(member):
			continue
		var distance := global_position.distance_squared_to(member.global_position)
		if distance < best_distance:
			best_distance = distance
			best = member
	return best

func _node_is_downed(member: Node3D) -> bool:
	var life := member.get_node_or_null("LifeState")
	return life != null and life.has_method("is_downed") and bool(life.call("is_downed"))

func _process_revive(delta: float) -> void:
	if _revive_target == null or not is_instance_valid(_revive_target) or not _node_is_downed(_revive_target):
		_clear_target_progress()
		_revive_target = null
		return

	var life := _revive_target.get_node_or_null("LifeState")
	if life == null:
		return
	var revive_distance := float(life.call("get_revive_distance")) if life.has_method("get_revive_distance") else 2.8
	var distance := global_position.distance_to(_revive_target.global_position)
	if distance > revive_distance * 0.88:
		_revive_elapsed = 0.0
		_revive_chase_elapsed += delta
		if life.has_method("clear_revive_progress_authoritative"):
			life.call("clear_revive_progress_authoritative", player_entity_id)
		_move_toward_point(_revive_target.global_position, delta)

		# Recovery for the current direct-movement companion navigation: if geometry
		# blocks a rescue for several seconds, move the rescuer to a safe nearby point.
		if _revive_chase_elapsed >= 4.0 and distance > revive_distance * 1.6:
			var rescue_offset := (_revive_target.global_position - global_position).normalized()
			rescue_offset.y = 0.0
			if rescue_offset.length_squared() < 0.01:
				rescue_offset = Vector3.RIGHT
			global_position = _revive_target.global_position - rescue_offset * minf(1.5, revive_distance * 0.55)
			_revive_chase_elapsed = 0.0
	else:
		_revive_chase_elapsed = 0.0
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
		_revive_elapsed += delta
		var hold := float(life.call("get_revive_hold_seconds")) if life.has_method("get_revive_hold_seconds") else 2.6
		var progress := clampf(_revive_elapsed / maxf(0.25, hold), 0.0, 1.0)
		if life.has_method("set_revive_progress_authoritative"):
			life.call("set_revive_progress_authoritative", progress, player_entity_id)
		if progress >= 1.0 and life.has_method("revive_authoritative"):
			if bool(life.call("revive_authoritative", player_entity_id)):
				AudioDirector.play_ui(&"ui_confirm")
			_revive_elapsed = 0.0
			_revive_target = null

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()

func _clear_target_progress() -> void:
	if _revive_target == null or not is_instance_valid(_revive_target):
		return
	var life := _revive_target.get_node_or_null("LifeState")
	if life != null and life.has_method("clear_revive_progress_authoritative"):
		life.call("clear_revive_progress_authoritative", player_entity_id)

func _try_support_heal() -> void:
	if operator_id != &"operator_04" or _support_cooldown > 0.0 or leader == null or not is_instance_valid(leader):
		return
	if global_position.distance_to(leader.global_position) > 5.0:
		return
	var leader_life := leader.get_node_or_null("LifeState")
	if leader_life != null and leader_life.has_method("is_downed") and bool(leader_life.call("is_downed")):
		return
	var leader_health := leader.get_node_or_null("Health")
	if leader_health == null or not leader_health.has_method("heal_authoritative"):
		return
	var current := float(leader_health.get("current_health"))
	var maximum := maxf(1.0, float(leader_health.get("max_health")))
	if current / maximum > 0.45:
		return
	if float(leader_health.call("heal_authoritative", 25.0)) > 0.0:
		_support_cooldown = 18.0
		AudioDirector.play_ui(&"ui_confirm")

func _move_toward_point(point: Vector3, delta: float) -> void:
	var direction := point - global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	direction = direction.normalized()
	look_at(global_position + direction, Vector3.UP)
	velocity.x = move_toward(velocity.x, direction.x * move_speed, 10.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * move_speed, 10.0 * delta)

func _find_target() -> Node3D:
	var best: Node3D
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("deadfall_zombie"):
		var zombie := node as Node3D
		if zombie == null:
			continue
		var target_health := zombie.get_node_or_null("Health")
		if target_health == null or bool(target_health.call("is_dead")):
			continue
		var distance := global_position.distance_squared_to(zombie.global_position)
		if distance < best_distance:
			best_distance = distance
			best = zombie
	return best

func _attack_target(target: Node3D) -> void:
	var target_health := target.get_node_or_null("Health")
	if target_health == null or Game.authority == null:
		return
	var event := DamageEventScript.new()
	event.attacker_id = player_entity_id
	event.victim_id = int(target_health.get("entity_id"))
	event.weapon_id = &"ai_rifle"
	event.amount = 18.0 if operator_id == &"operator_02" else (15.0 if operator_id == &"operator_04" else 16.0)
	event.damage_type = DamageEventScript.DamageType.BULLET
	event.body_part = DamageEventScript.BodyPart.CHEST
	event.hit_position = target.global_position + Vector3.UP
	event.hit_direction = (target.global_position - global_position).normalized()
	Game.authority.resolve_damage(event)
	AudioDirector.play_at(&"rifle", global_position, -8.0, 0.96, get_instance_id())

func _animate_model() -> void:
	if _model != null and is_instance_valid(_model) and _model.has_method("animate_pose"):
		var planar_speed := Vector2(velocity.x, velocity.z).length()
		var pose := &"downed" if is_downed() else &"idle"
		_model.call("animate_pose", _animation_time, planar_speed, pose)
