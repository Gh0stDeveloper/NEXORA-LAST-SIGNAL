extends Node

const PATH := "user://last_signal_progress.json"

var data := {
	"version": 1,
	"xp": 0,
	"coins": 0,
	"level": 1,
	"best_wave": 0,
	"missions_completed": [],
	"runs": 0,
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
	_recalculate_level()

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
	return {"xp":xp_gain,"coins":coin_gain,"level":int(data.level)}

func snapshot() -> Dictionary:
	return data.duplicate(true)

func _recalculate_level() -> void:
	data.level = 1 + int(floor(float(data.get("xp",0))/600.0))
