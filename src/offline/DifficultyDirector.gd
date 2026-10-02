class_name LastSignalDifficultyDirector
extends Node

const PROFILES := {
	"story":{"health":0.75,"damage":0.70,"spawn":0.82},
	"normal":{"health":1.0,"damage":1.0,"spawn":1.0},
	"hard":{"health":1.35,"damage":1.25,"spawn":1.16},
	"nightmare":{"health":1.75,"damage":1.55,"spawn":1.32},
}

var difficulty_id := "normal"
var horde: Node

func setup(horde_director: Node, requested: String) -> void:
	horde = horde_director
	difficulty_id = requested if PROFILES.has(requested) else "normal"
	var profile: Dictionary = PROFILES[difficulty_id]
	if horde != null:
		var base_interval := float(horde.get("spawn_interval_seconds"))
		horde.set("spawn_interval_seconds",maxf(0.18,base_interval/float(profile.spawn)))
		if horde.has_signal("zombie_spawned"):
			horde.connect("zombie_spawned",_on_zombie_spawned)

func _on_zombie_spawned(zombie: Node, _archetype: StringName, _cost: int) -> void:
	if zombie == null:
		return
	var profile: Dictionary = PROFILES[difficulty_id]
	var health := zombie.get_node_or_null("Health")
	if health != null:
		var entity_id := int(health.get("entity_id"))
		var maximum := float(health.get("max_health")) * float(profile.health)
		health.call("configure_entity",entity_id,maximum)
	zombie.set("_attack_damage_multiplier",float(profile.damage))
