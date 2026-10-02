class_name LastSignalLootPickup
extends Area3D

@export var item_id: StringName = &"scrap"
@export var amount := 1
var _taken := false
var _elapsed := 0.0
var _visual: MeshInstance3D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.62
	shape.shape = sphere
	add_child(shape)
	_visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.42,0.28,0.42)
	_visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = _color_for_item()
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.35
	_visual.material_override = material
	_visual.position.y = 0.35
	add_child(_visual)

func _process(delta: float) -> void:
	_elapsed += delta
	if _visual != null:
		_visual.rotation.y += delta * 1.7
		_visual.position.y = 0.35 + sin(_elapsed*2.4)*0.07

func configure(id: StringName, value: int) -> void:
	item_id = id
	amount = maxi(1,value)

func _on_body_entered(body: Node3D) -> void:
	if _taken or body == null or not body.is_in_group("deadfall_player"):
		return
	var accepted := 0
	if item_id == &"ammo_box":
		var loadout := body.get_node_or_null("WeaponLoadout")
		if loadout != null and loadout.has_method("add_ammo"):
			accepted = int(loadout.call("add_ammo",amount))
	elif item_id == &"medkit":
		var inventory := body.get_node_or_null("Inventory")
		if inventory != null:
			accepted = int(inventory.call("add_item",item_id,amount))
	elif item_id == &"scrap" or item_id == &"weapon_parts":
		var inventory := body.get_node_or_null("Inventory")
		if inventory != null:
			accepted = int(inventory.call("add_item",item_id,amount))
	if accepted <= 0:
		return
	_taken = true
	AudioDirector.play_ui(&"ui_confirm")
	queue_free()

func _color_for_item() -> Color:
	match item_id:
		&"ammo_box": return Color(0.90,0.62,0.16)
		&"medkit": return Color(0.16,0.70,0.38)
		&"weapon_parts": return Color(0.18,0.58,0.72)
		_: return Color(0.62,0.66,0.70)
