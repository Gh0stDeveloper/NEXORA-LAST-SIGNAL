extends Node

signal progress_changed(snapshot: Dictionary)
signal cosmetic_purchased(item_id: StringName, price: int)

const Cosmetics = preload("res://src/customization/CosmeticCatalog.gd")
const PATH := "user://last_signal_progress.json"

var data := {
	"version": 2,
	"xp": 0,
	"coins": 0,
	"level": 1,
	"best_wave": 0,
	"missions_completed": [],
	"runs": 0,
	"owned_cosmetics": [],
}

func _ready() -> void:
	load_progress()

func load_progress() -> void:
	if FileAccess.file_exists(PATH):
		var file := FileAccess.open(PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				for key in parsed:
					data[key] = parsed[key]
	data.version = 2
	_ensure_starter_cosmetics()
	_recalculate_level()
	save()

func save() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))

func award_run(wave: int, kills: int, score: int, mission_id: StringName = &"", completed := false) -> Dictionary:
	var xp_gain := maxi(0, kills * 18 + wave * 35 + (250 if completed else 0))
	var coin_gain := maxi(0, int(score / 10) + kills * 3 + (100 if completed else 0))
	data.xp = int(data.get("xp",0)) + xp_gain
	data.coins = int(data.get("coins",0)) + coin_gain
	data.best_wave = maxi(int(data.get("best_wave",0)),wave)
	data.runs = int(data.get("runs",0)) + 1
	if completed and not mission_id.is_empty():
		var completed_list: Array = data.get("missions_completed",[])
		if String(mission_id) not in completed_list:
			completed_list.append(String(mission_id))
		data.missions_completed = completed_list
	_recalculate_level()
	save()
	progress_changed.emit(snapshot())
	return {"xp":xp_gain,"coins":coin_gain,"level":int(data.level)}

func owns_cosmetic(item_id: StringName) -> bool:
	return String(item_id) in _owned_cosmetics()

func can_afford_cosmetic(item_id: StringName) -> bool:
	var item := Cosmetics.get_item(item_id)
	return not item.is_empty() and int(data.get("coins",0)) >= int(item.get("price",0))

func purchase_cosmetic(item_id: StringName) -> Dictionary:
	var item := Cosmetics.get_item(item_id)
	if item.is_empty():
		return {"ok":false,"reason":"unknown_item"}
	var owned := _owned_cosmetics()
	if String(item_id) in owned:
		return {"ok":true,"already_owned":true,"item_id":String(item_id),"coins":int(data.get("coins",0))}
	var price := maxi(0, int(item.get("price",0)))
	var balance := int(data.get("coins",0))
	if price > balance:
		return {
			"ok":false,
			"reason":"insufficient_funds",
			"price":price,
			"coins":balance,
			"missing":price-balance,
		}
	data.coins = balance - price
	owned.append(String(item_id))
	data.owned_cosmetics = owned
	save()
	cosmetic_purchased.emit(item_id, price)
	progress_changed.emit(snapshot())
	return {
		"ok":true,
		"item_id":String(item_id),
		"price":price,
		"coins":int(data.coins),
	}

func get_coins() -> int:
	return int(data.get("coins",0))

func owned_cosmetics() -> Array[String]:
	return _owned_cosmetics().duplicate()

func snapshot() -> Dictionary:
	return data.duplicate(true)

func _owned_cosmetics() -> Array[String]:
	var raw = data.get("owned_cosmetics", [])
	var result: Array[String] = []
	if raw is Array:
		for value in raw:
			var id := String(value)
			if not id.is_empty() and id not in result:
				result.append(id)
	data.owned_cosmetics = result
	return result

func _ensure_starter_cosmetics() -> void:
	var owned := _owned_cosmetics()
	for item_id in Cosmetics.starter_ids():
		if item_id not in owned:
			owned.append(item_id)
	data.owned_cosmetics = owned

func _recalculate_level() -> void:
	data.level = 1 + int(floor(float(data.get("xp",0))/600.0))
