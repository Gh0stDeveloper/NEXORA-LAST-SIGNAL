class_name LastSignalWeaponCatalog
extends RefCounted

const DEFINITIONS := {
	"nxr_rifle_01": {"name":"NXR-4","role":"FUSIL DE ASALTO","resource":"res://src/weapons/data/nxr_rifle_01.tres","slot":"primary"},
	"nxr_smg_01": {"name":"NXR-7","role":"SUBFUSIL","resource":"res://src/weapons/data/nxr_smg_01.tres","slot":"primary"},
	"nxr_dmr_01": {"name":"NXR-18","role":"RIFLE DE PRECISIÓN","resource":"res://src/weapons/data/nxr_dmr_01.tres","slot":"primary"},
	"nxr_lmg_01": {"name":"NXR-60","role":"AMETRALLADORA LIGERA","resource":"res://src/weapons/data/nxr_lmg_01.tres","slot":"primary"},
	"nxr_pistol_01": {"name":"NXR-9","role":"PISTOLA","resource":"res://src/weapons/data/nxr_pistol_01.tres","slot":"secondary"},
	"nxr_pistol_02": {"name":"NXR-12","role":"PISTOLA PESADA","resource":"res://src/weapons/data/nxr_pistol_02.tres","slot":"secondary"},
}

static func all_for_slot(slot: String) -> Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for id in DEFINITIONS:
		var definition:Dictionary=Dictionary(DEFINITIONS[id]).duplicate(true)
		if String(definition.slot)==slot:
			definition["id"]=id
			result.append(definition)
	return result

static func get_definition(id: StringName) -> Dictionary:
	return Dictionary(DEFINITIONS.get(String(id), DEFINITIONS["nxr_rifle_01"])).duplicate(true)

static func resource_for(id: StringName) -> Resource:
	var definition:=get_definition(id)
	return load(String(definition.resource)) as Resource
