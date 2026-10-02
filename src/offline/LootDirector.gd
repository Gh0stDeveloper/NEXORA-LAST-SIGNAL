class_name LastSignalLootDirector
extends Node

const PickupScript = preload("res://src/offline/LootPickup.gd")

var zombies_root: Node3D
var pickups_root: Node3D
var _tracked: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func setup(zombies: Node3D, pickups: Node3D) -> void:
	zombies_root = zombies
	pickups_root = pickups
	_rng.randomize()
	if zombies_root != null:
		zombies_root.child_entered_tree.connect(_on_zombie_entered)
		for child in zombies_root.get_children():
			_on_zombie_entered(child)

func _on_zombie_entered(node: Node) -> void:
	if node == null or not node.is_in_group("deadfall_zombie"):
		return
	var key := node.get_instance_id()
	if _tracked.has(key):
		return
	_tracked[key] = true
	node.tree_exiting.connect(_on_zombie_exiting.bind(node,key),CONNECT_ONE_SHOT)

func _on_zombie_exiting(zombie: Node, key: int) -> void:
	_tracked.erase(key)
	if zombie == null or not is_instance_valid(zombie) or pickups_root == null:
		return
	var health := zombie.get_node_or_null("Health")
	if health == null or not bool(health.call("is_dead")) or _rng.randf() > 0.46:
		return
	var roll := _rng.randf()
	var item: StringName = &"scrap"
	var amount := _rng.randi_range(1,3)
	if roll < 0.28:
		item = &"ammo_box"; amount = _rng.randi_range(18,42)
	elif roll < 0.48:
		item = &"medkit"; amount = 1
	elif roll < 0.62:
		item = &"weapon_parts"; amount = 1
	var pickup := PickupScript.new()
	pickup.configure(item,amount)
	pickups_root.add_child(pickup)
	pickup.global_position = zombie.global_position + Vector3(0,0.2,0)
