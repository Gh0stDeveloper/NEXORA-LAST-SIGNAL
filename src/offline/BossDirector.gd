class_name LastSignalBossDirector
extends Node

var horde: Node
var difficulty_id := "normal"

func setup(horde_director: Node, requested_difficulty: String) -> void:
	horde = horde_director
	difficulty_id = requested_difficulty
	if horde != null and horde.has_signal("wave_started"):
		horde.connect("wave_started",_on_wave_started)

func _on_wave_started(wave: int, _total: int) -> void:
	if wave > 0 and wave % 5 == 0:
		call_deferred("_spawn_boss",wave)

func _spawn_boss(wave: int) -> void:
	if horde == null or not horde.has_method("debug_spawn_archetype"):
		return
	var boss := horde.call("debug_spawn_archetype",&"tank") as Node3D
	if boss == null:
		return
	boss.name = "BOSS_TITAN_WAVE_%d" % wave
	boss.scale = Vector3.ONE * (1.22 + minf(0.22,float(wave)*0.01))
	var health := boss.get_node_or_null("Health")
	if health != null:
		var entity_id := int(health.get("entity_id"))
		var base := float(health.get("max_health"))
		var difficulty_bonus := 1.0 if difficulty_id in ["story","normal"] else 1.25
		health.call("configure_entity",entity_id,base*(2.6+wave*0.08)*difficulty_bonus)
	boss.set("_attack_damage_multiplier",1.45 if difficulty_id != "nightmare" else 1.85)
	AudioDirector.play_at(&"zombie_growl",boss.global_position,0.0,0.72,boss.get_instance_id())
