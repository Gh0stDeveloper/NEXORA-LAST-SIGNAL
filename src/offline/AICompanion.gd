class_name LastSignalAICompanion
extends CharacterBody3D

const HealthScript = preload("res://src/core/health/HealthComponent.gd")
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
var health: Node

func _ready() -> void:
	add_to_group("deadfall_player")
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
	var model := ProceduralCharacters.create_operator(operator_id,player_entity_id%4)
	model.name = "OperatorVisual"
	add_child(model)

func configure(entity_id: int, character: StringName, squad_leader: Node3D) -> void:
	player_entity_id = entity_id
	operator_id = character
	leader = squad_leader

func _physics_process(delta: float) -> void:
	if health == null or bool(health.call("is_dead")):
		velocity = Vector3.ZERO
		return
	_fire_cooldown = maxf(0.0,_fire_cooldown-delta)
	_target_scan -= delta
	if _target_scan <= 0.0:
		_target_scan = 0.25
		_target = _find_target()
	if _target != null and is_instance_valid(_target):
		var distance := global_position.distance_to(_target.global_position)
		if distance <= attack_range:
			var flat := _target.global_position-global_position
			flat.y=0
			if flat.length_squared()>0.01:
				look_at(global_position+flat.normalized(),Vector3.UP)
			velocity.x = move_toward(velocity.x,0.0,12.0*delta)
			velocity.z = move_toward(velocity.z,0.0,12.0*delta)
			if _fire_cooldown <= 0.0:
				_fire_cooldown = fire_interval
				_attack_target(_target)
		else:
			_move_toward_point(_target.global_position,delta)
	elif leader != null and is_instance_valid(leader):
		var offset := Vector3(float((player_entity_id%3)-1)*1.8,0,2.2+float(player_entity_id%2))
		var goal := leader.global_position + leader.global_basis*offset
		if global_position.distance_to(goal)>2.2:
			_move_toward_point(goal,delta)
		else:
			velocity.x=move_toward(velocity.x,0.0,10.0*delta)
			velocity.z=move_toward(velocity.z,0.0,10.0*delta)
	if not is_on_floor():
		velocity.y -= 9.8*delta
	move_and_slide()

func _move_toward_point(point: Vector3, delta: float) -> void:
	var direction := point-global_position
	direction.y=0
	if direction.length_squared()<0.01:
		return
	direction=direction.normalized()
	look_at(global_position+direction,Vector3.UP)
	velocity.x=move_toward(velocity.x,direction.x*move_speed,10.0*delta)
	velocity.z=move_toward(velocity.z,direction.z*move_speed,10.0*delta)

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
			best_distance=distance
			best=zombie
	return best

func _attack_target(target: Node3D) -> void:
	var target_health := target.get_node_or_null("Health")
	if target_health == null or Game.authority == null:
		return
	var event := DamageEventScript.new()
	event.attacker_id=player_entity_id
	event.victim_id=int(target_health.get("entity_id"))
	event.weapon_id=&"ai_rifle"
	event.amount=16.0
	event.damage_type=DamageEventScript.DamageType.BULLET
	event.body_part=DamageEventScript.BodyPart.CHEST
	event.hit_position=target.global_position+Vector3.UP
	event.hit_direction=(target.global_position-global_position).normalized()
	Game.authority.resolve_damage(event)
	AudioDirector.play_at(&"rifle",global_position,-8.0,0.96,get_instance_id())
