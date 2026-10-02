class_name LastSignalBossDirector
extends Node

const BossBehaviorScript = preload("res://src/offline/BossBehavior.gd")

var horde: Node
var difficulty_id := "normal"

func setup(horde_director: Node, requested_difficulty: String) -> void:
	horde = horde_director
	difficulty_id = requested_difficulty
	if horde != null and horde.has_signal("wave_started"):
		horde.connect("wave_started", _on_wave_started)

func _on_wave_started(wave: int, _total: int) -> void:
	if wave > 0 and wave % 5 == 0:
		call_deferred("_spawn_boss", wave)

func _spawn_boss(wave: int) -> void:
	if horde == null or not horde.has_method("debug_spawn_archetype"):
		return
	var kind := "screamer_prime" if wave % 10 == 0 else "titan"
	var archetype: StringName = &"screamer" if kind == "screamer_prime" else &"tank"
	var boss := horde.call("debug_spawn_archetype", archetype) as Node3D
	if boss == null:
		return
	boss.name = ("BOSS_SCREAMER_PRIME_" if kind == "screamer_prime" else "BOSS_TITAN_") + "WAVE_%d" % wave
	boss.set_meta("boss", true)
	boss.set_meta("boss_kind", kind)
	boss.scale = Vector3.ONE * (1.18 if kind == "screamer_prime" else 1.30)

	var health := boss.get_node_or_null("Health")
	if health != null:
		var entity_id := int(health.get("entity_id"))
		var base := float(health.get("max_health"))
		var difficulty_bonus := 1.0 if difficulty_id in ["story","normal"] else (1.25 if difficulty_id == "hard" else 1.45)
		var kind_bonus := 2.25 if kind == "screamer_prime" else 3.0
		health.call("configure_entity", entity_id, base * (kind_bonus + wave * 0.07) * difficulty_bonus)

	boss.set("_attack_damage_multiplier", 1.30 if kind == "screamer_prime" else (1.55 if difficulty_id != "nightmare" else 1.95))
	var behavior := BossBehaviorScript.new()
	behavior.name = "BossBehavior"
	boss.add_child(behavior)
	behavior.configure(boss, horde, kind, wave)
	AudioDirector.play_at(&"zombie_growl", boss.global_position, 2.0, 0.70, boss.get_instance_id())
