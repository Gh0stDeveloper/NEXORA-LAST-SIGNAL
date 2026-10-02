class_name LastSignalInventory
extends Node

signal changed(snapshot: Dictionary)

@export var max_distinct_items := 16
var items: Dictionary = {}
var weapons: Array[String] = ["nxr_rifle_01","nxr_pistol_01","machete"]

func add_item(item_id: StringName, amount: int = 1) -> int:
	if item_id.is_empty() or amount <= 0:
		return 0
	var key := String(item_id)
	if not items.has(key) and items.size() >= max_distinct_items:
		return 0
	items[key] = int(items.get(key,0)) + amount
	changed.emit(snapshot())
	return amount

func consume_item(item_id: StringName, amount: int = 1) -> bool:
	var key := String(item_id)
	var current := int(items.get(key,0))
	if current < amount or amount <= 0:
		return false
	current -= amount
	if current <= 0:
		items.erase(key)
	else:
		items[key] = current
	changed.emit(snapshot())
	return true

func has_item(item_id: StringName, amount: int = 1) -> bool:
	return int(items.get(String(item_id),0)) >= amount

func add_weapon(weapon_id: StringName) -> bool:
	var key := String(weapon_id)
	if key in weapons:
		return false
	weapons.append(key)
	changed.emit(snapshot())
	return true

func snapshot() -> Dictionary:
	return {"items":items.duplicate(true),"weapons":weapons.duplicate(),"capacity":max_distinct_items}
