class_name DeadfallModeCatalog
extends RefCounted

const MODES := [
	{"id":"campaign","title":"ZOMBIS · CAMPAÑA","tag":"OFFLINE","description":"Avanza por la ciudad, cumple objetivos y alcanza la evacuación.","image":"res://assets/ui/modes/campaign.webp"},
	{"id":"waves","title":"ASALTO · 10 OLEADAS","tag":"OFFLINE","description":"Sobrevive diez rondas y elimina al jefe final.","image":"res://assets/ui/modes/waves.webp"},
	{"id":"endless","title":"RESISTENCIA INFINITA","tag":"OFFLINE","description":"Oleadas sin límite con bosses y loot local.","image":"res://assets/ui/modes/endless.webp"},
]

static func find(id: String) -> Dictionary:
	for mode in MODES:
		if String(mode.id) == id:
			return mode.duplicate(true)
	return MODES[0].duplicate(true)

static func is_pvp(_id: String) -> bool:
	return false
