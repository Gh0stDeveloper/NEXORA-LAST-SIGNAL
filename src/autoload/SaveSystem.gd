extends Node

const SAVE_PATH := "user://profile.json"

var data: Dictionary = {}

func _ready() -> void:
    load_profile()

func defaults() -> Dictionary:
    return {
        "version": 1,
        "coins": 0,
        "xp": 0,
        "level": 1,
        "best_wave": 0,
        "settings": {
            "sensitivity": 0.16,
            "master_volume": 0.8,
            "show_mobile_controls": true,
        }
    }

func load_profile() -> void:
    data = defaults()
    if not FileAccess.file_exists(SAVE_PATH):
        flush()
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        _merge_dictionary(data, parsed)
    _recalculate_level()

func _merge_dictionary(target: Dictionary, incoming: Dictionary) -> void:
    for key in incoming.keys():
        if target.has(key) and target[key] is Dictionary and incoming[key] is Dictionary:
            _merge_dictionary(target[key], incoming[key])
        else:
            target[key] = incoming[key]

func flush() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data, "  "))

func award(coins: int, xp: int) -> void:
    data.coins = int(data.get("coins", 0)) + max(coins, 0)
    data.xp = int(data.get("xp", 0)) + max(xp, 0)
    _recalculate_level()
    flush()

func register_best_wave(wave: int) -> void:
    data.best_wave = max(int(data.get("best_wave", 0)), wave)

func set_setting(key: String, value: Variant) -> void:
    if not data.has("settings"):
        data.settings = defaults().settings
    data.settings[key] = value
    flush()

func get_setting(key: String, fallback: Variant) -> Variant:
    return data.get("settings", {}).get(key, fallback)

func _recalculate_level() -> void:
    var xp := int(data.get("xp", 0))
    data.level = 1 + int(floor(float(xp) / 500.0))
