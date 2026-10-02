class_name LastSignalBossBehavior
extends Node

const DamageEventScript = preload("res://src/core/damage/DamageEvent.gd")

var boss: Node3D
var horde: Node
var boss_kind := "titan"
var wave := 5
var _ability_cooldown := 5.0

func configure(owner_boss: Node3D, horde_director: Node, kind: String, wave_number: int) -> void:
	boss = owner_boss
	horde = horde_director
	boss_kind = kind
	wave = wave_number
	_ability_cooldown = 4.0 if boss_kind == "screamer_prime" else 5.5

func _process(delta: float) -> void:
	if boss == null or not is_instance_valid(boss):
		queue_free()
		return
	var health := boss.get_node_or_null("Health")
	if health != null and health.has_method("is_dead") and bool(health.call("is_dead")):
		queue_free()
		return
	_ability_cooldown -= delta
	if _ability_cooldown > 0.0:
		return
	if boss_kind == "screamer_prime":
		_summon_infected()
		_ability_cooldown = maxf(5.5, 9.0 - float(wave) * 0.08)
	else:
		_titan_shockwave()
		_ability_cooldown = maxf(4.5, 7.0 - float(wave) * 0.05)

func _summon_infected() -> void:
	if horde == null or not horde.has_method("debug_spawn_archetype"):
		return
	for archetype in [&"runner", &"walker", &"runner"]:
		horde.call_deferred("debug_spawn_archetype", archetype)
	AudioDirector.play_at(&"zombie_growl", boss.global_position, 2.0, 0.72, boss.get_instance_id())

func _titan_shockwave() -> void:
	if Game.authority == null:
		return
	for node in get_tree().get_nodes_in_group("deadfall_player"):
		var player := node as Node3D
		if player == null or not is_instance_valid(player):
			continue
		var distance := boss.global_position.distance_to(player.global_position)
		if distance > 5.2:
			continue
		var target_health := player.get_node_or_null("Health")
		if target_health == null or bool(target_health.call("is_dead")):
			continue
		var event := DamageEventScript.new()
		var boss_health := boss.get_node_or_null("Health")
		event.attacker_id = int(boss_health.get("entity_id")) if boss_health != null else boss.get_instance_id()
		event.victim_id = int(target_health.get("entity_id"))
		event.weapon_id = &"titan_shockwave"
		event.amount = 18.0 + float(wave) * 0.7
		event.damage_type = DamageEventScript.DamageType.MELEE
		event.body_part = DamageEventScript.BodyPart.CHEST
		event.hit_position = player.global_position
		event.hit_direction = (player.global_position - boss.global_position).normalized()
		Game.authority.resolve_damage(event)
		if player is CharacterBody3D:
			var push := event.hit_direction
			push.y = 0.35
			(player as CharacterBody3D).velocity += push.normalized() * 5.5
	AudioDirector.play_at(&"impact", boss.global_position, 3.0, 0.78, boss.get_instance_id())
