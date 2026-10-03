class_name LastSignalCosmeticCatalog
extends RefCounted

const CATEGORIES := ["outerwear", "headwear", "glasses", "top", "pants", "shoes"]
const CATEGORY_LABELS := {
	"outerwear":"ROPA",
	"headwear":"GORRAS",
	"glasses":"LENTES",
	"top":"PLAYERAS",
	"pants":"PANTALONES",
	"shoes":"ZAPATOS",
	"profile_icon":"ICONOS DE PERFIL",
}

const ITEMS := [
	{"id":"outerwear_field","category":"outerwear","name":"Chaleco de campo","price":0,"gender":"any","starter":true,"color":"33454a"},
	{"id":"outerwear_responder","category":"outerwear","name":"Chaqueta Responder","price":650,"gender":"any","color":"68443f"},
	{"id":"outerwear_night","category":"outerwear","name":"Arnés Night Ops","price":900,"gender":"any","color":"20282f"},
	{"id":"outerwear_signal","category":"outerwear","name":"Chaleco Last Signal","price":1250,"gender":"any","color":"3a2938"},

	{"id":"headwear_none_f","category":"headwear","name":"Sin gorra","price":0,"gender":"female","starter":true,"style":"none"},
	{"id":"headwear_none_m","category":"headwear","name":"Sin gorra","price":0,"gender":"male","starter":true,"style":"none"},
	{"id":"headwear_cap_black","category":"headwear","name":"Gorra negra","price":250,"gender":"any","style":"cap","color":"1a2026"},
	{"id":"headwear_cap_red","category":"headwear","name":"Gorra Signal","price":425,"gender":"any","style":"cap","color":"7f1d27"},
	{"id":"headwear_beanie","category":"headwear","name":"Gorro urbano","price":500,"gender":"any","style":"beanie","color":"28373d"},

	{"id":"glasses_none_f","category":"glasses","name":"Sin lentes","price":0,"gender":"female","starter":true,"style":"none"},
	{"id":"glasses_none_m","category":"glasses","name":"Sin lentes","price":0,"gender":"male","starter":true,"style":"none"},
	{"id":"glasses_clear","category":"glasses","name":"Lentes tácticos","price":280,"gender":"any","style":"glasses","color":"8ccbd3"},
	{"id":"glasses_dark","category":"glasses","name":"Lentes oscuros","price":420,"gender":"any","style":"glasses","color":"1d2a31"},
	{"id":"glasses_red","category":"glasses","name":"Visor rojo","price":700,"gender":"any","style":"visor","color":"b7353f"},

	{"id":"top_field_f","category":"top","name":"Playera Field F","price":0,"gender":"female","starter":true,"color":"405052"},
	{"id":"top_field_m","category":"top","name":"Playera Field M","price":0,"gender":"male","starter":true,"color":"354651"},
	{"id":"top_urban_f","category":"top","name":"Playera Urban F","price":320,"gender":"female","color":"5c4b56"},
	{"id":"top_urban_m","category":"top","name":"Playera Urban M","price":320,"gender":"male","color":"405468"},
	{"id":"top_signal_f","category":"top","name":"Playera Signal F","price":550,"gender":"female","color":"7b3541"},
	{"id":"top_signal_m","category":"top","name":"Playera Signal M","price":550,"gender":"male","color":"315b66"},

	{"id":"pants_field_f","category":"pants","name":"Pantalón Field F","price":0,"gender":"female","starter":true,"color":"46504a"},
	{"id":"pants_field_m","category":"pants","name":"Pantalón Field M","price":0,"gender":"male","starter":true,"color":"394754"},
	{"id":"pants_cargo_f","category":"pants","name":"Cargo oscuro F","price":390,"gender":"female","color":"343d3b"},
	{"id":"pants_cargo_m","category":"pants","name":"Cargo oscuro M","price":390,"gender":"male","color":"313942"},
	{"id":"pants_recon_f","category":"pants","name":"Recon F","price":620,"gender":"female","color":"54414a"},
	{"id":"pants_recon_m","category":"pants","name":"Recon M","price":620,"gender":"male","color":"354f50"},

	{"id":"shoes_field_f","category":"shoes","name":"Botas Field F","price":0,"gender":"female","starter":true,"color":"293235"},
	{"id":"shoes_field_m","category":"shoes","name":"Botas Field M","price":0,"gender":"male","starter":true,"color":"293235"},
	{"id":"shoes_runner_f","category":"shoes","name":"Runner F","price":300,"gender":"female","color":"463c42"},
	{"id":"shoes_runner_m","category":"shoes","name":"Runner M","price":300,"gender":"male","color":"35434a"},
	{"id":"shoes_signal","category":"shoes","name":"Botas Signal","price":575,"gender":"any","color":"5c3034"},

	{"id":"profile_medic","category":"profile_icon","name":"Medic","price":0,"gender":"female","starter":true,"asset":"res://assets/ui/avatars/medic.svg"},
	{"id":"profile_elite","category":"profile_icon","name":"Elite","price":0,"gender":"male","starter":true,"asset":"res://assets/ui/avatars/elite.svg"},
	{"id":"profile_scout","category":"profile_icon","name":"Scout","price":325,"gender":"female","asset":"res://assets/ui/avatars/scout.svg"},
	{"id":"profile_viper","category":"profile_icon","name":"Viper","price":325,"gender":"male","asset":"res://assets/ui/avatars/viper.svg"},
	{"id":"profile_phoenix","category":"profile_icon","name":"Phoenix","price":650,"gender":"any","asset":"res://assets/ui/avatars/phoenix.svg"},
	{"id":"profile_sentinel","category":"profile_icon","name":"Sentinel","price":650,"gender":"any","asset":"res://assets/ui/avatars/sentinel.svg"},
]

const DEFAULT_LOADOUTS := {
	"female":{
		"outerwear":"outerwear_field",
		"headwear":"headwear_none_f",
		"glasses":"glasses_none_f",
		"top":"top_field_f",
		"pants":"pants_field_f",
		"shoes":"shoes_field_f",
	},
	"male":{
		"outerwear":"outerwear_field",
		"headwear":"headwear_none_m",
		"glasses":"glasses_none_m",
		"top":"top_field_m",
		"pants":"pants_field_m",
		"shoes":"shoes_field_m",
	},
}

static func all_items() -> Array:
	return ITEMS.duplicate(true)

static func get_item(item_id: StringName) -> Dictionary:
	var wanted := String(item_id)
	for item in ITEMS:
		if String(item.get("id","")) == wanted:
			return Dictionary(item).duplicate(true)
	return {}

static func category_label(category: String) -> String:
	return String(CATEGORY_LABELS.get(category, category.to_upper()))

static func is_compatible(item: Dictionary, gender: String) -> bool:
	if item.is_empty():
		return false
	var item_gender := String(item.get("gender","any"))
	return item_gender == "any" or item_gender == gender

static func items_for_gender(gender: String, category: String = "") -> Array:
	var result: Array = []
	for raw in ITEMS:
		var item := Dictionary(raw)
		if not category.is_empty() and String(item.get("category","")) != category:
			continue
		if is_compatible(item, gender):
			result.append(item.duplicate(true))
	return result

static func default_loadout(gender: String) -> Dictionary:
	var normalized := "male" if gender == "male" else "female"
	return Dictionary(DEFAULT_LOADOUTS[normalized]).duplicate(true)

static func default_profile_icon(gender: String) -> StringName:
	return &"profile_elite" if gender == "male" else &"profile_medic"

static func starter_ids() -> Array[String]:
	var result: Array[String] = []
	for item in ITEMS:
		if bool(item.get("starter",false)):
			result.append(String(item.get("id","")))
	return result

static func sanitize_loadout(loadout: Dictionary, gender: String) -> Dictionary:
	var clean := default_loadout(gender)
	for category in CATEGORIES:
		var item_id := StringName(String(loadout.get(category, clean[category])))
		var item := get_item(item_id)
		if not item.is_empty() and String(item.get("category","")) == category and is_compatible(item, gender):
			clean[category] = String(item_id)
	return clean

static func profile_icon_asset(item_id: StringName) -> String:
	var item := get_item(item_id)
	return String(item.get("asset","res://assets/ui/avatars/medic.svg"))

static func item_color(item_id: StringName, fallback: Color) -> Color:
	var item := get_item(item_id)
	var value := String(item.get("color",""))
	return Color(value) if not value.is_empty() else fallback

static func item_style(item_id: StringName) -> String:
	return String(get_item(item_id).get("style","none"))

static func ai_appearance(slot_index: int) -> Dictionary:
	var male := slot_index % 2 == 0
	var gender := "male" if male else "female"
	var loadout := default_loadout(gender)
	if slot_index % 3 == 0:
		loadout["outerwear"] = "outerwear_night"
		loadout["headwear"] = "headwear_cap_black"
		loadout["glasses"] = "glasses_dark"
	elif slot_index % 3 == 1:
		loadout["outerwear"] = "outerwear_responder"
		loadout["headwear"] = "headwear_cap_red"
		loadout["glasses"] = "glasses_clear"
	else:
		loadout["outerwear"] = "outerwear_signal"
		loadout["headwear"] = "headwear_beanie"
		loadout["glasses"] = "glasses_red"
	return {
		"gender":gender,
		"profile_icon":String(default_profile_icon(gender)),
		"cosmetics":loadout,
	}
