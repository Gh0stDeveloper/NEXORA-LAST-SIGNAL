class_name DeadfallAmmoPickup
extends Area3D

signal collected(pickup_id: int, ammo_added: int, collector_entity_id: int)

@export var pickup_id := 0
@export_range(1, 240, 1) var ammo_amount := 30
@export_range(5.0, 180.0, 1.0) var lifetime_seconds := 45.0
@export_enum("ammo", "health") var pickup_kind := "ammo"

var _collect_elapsed := 0.0
var _age := 0.0
var _collected := false
var _visual: Node3D

func _enter_tree() -> void:
	if preload("res://src/core/PresentationRuntime.gd").enabled() and not has_node("Visual"):
		var presentation: Node3D = preload("res://src/horde/PickupPresentation.gd").new()
		presentation.name = "Visual"
		add_child(presentation)
		presentation.call("rebuild", pickup_kind, ammo_amount)

func _ready() -> void:
	_visual = get_node_or_null("Visual") as Node3D
	body_entered.connect(_on_body_entered)
	monitoring = Game != null and Game.is_simulation_authority()
	monitorable = true
	set_process(true)

func _process(delta: float) -> void:
	if _visual != null:
		_visual.rotation.y += delta * 1.35
		_visual.position.y = 0.16 + sin(Time.get_ticks_msec() * 0.004 + float(pickup_id % 17)) * 0.07
	if not Game.is_simulation_authority():
		return
	_collect_elapsed += delta
	if _collect_elapsed >= 0.2 and not _collected:
		_collect_elapsed = 0.0
		for body in get_overlapping_bodies():
			_on_body_entered(body)
	_age += delta
	if _age >= lifetime_seconds:
		queue_free()

func configure(id: int, amount: int, kind: String = "ammo") -> void:
	pickup_id = id
	pickup_kind = "health" if kind == "health" else "ammo"
	ammo_amount = maxi(1, amount)
	if is_inside_tree():
		monitoring = Game != null and Game.is_simulation_authority()

func _on_body_entered(body: Node3D) -> void:
	if _collected or not Game.is_simulation_authority() or body == null or not body.is_in_group("deadfall_player"):
		return
	var life := body.get_node_or_null("LifeState")
	if life != null and not bool(life.call("can_use_weapon")):
		return
	var added := 0
	var loadout := body.get_node_or_null("WeaponLoadout")
	if pickup_kind == "health":
		var health := body.get_node_or_null("Health")
		if health != null:
			added = ceili(float(health.call("heal_authoritative", float(ammo_amount))))
	elif loadout != null and loadout.has_method("add_ammo"):
		added = int(loadout.call("add_ammo", ammo_amount))
	else:
		var weapon := body.get_node_or_null("PrimaryWeapon")
		if weapon != null and weapon.has_method("add_reserve_ammo"):
			added = int(weapon.call("add_reserve_ammo", ammo_amount))
	if added <= 0:
		return
	_collected = true
	set_deferred("monitoring", false)
	var entity_value = body.get("player_entity_id")
	var entity_id := int(entity_value) if entity_value != null else 0
	collected.emit(pickup_id, added, entity_id)
	queue_free()
