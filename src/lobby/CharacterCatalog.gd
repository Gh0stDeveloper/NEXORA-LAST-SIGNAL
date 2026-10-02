class_name DeadfallCharacterCatalog
extends RefCounted

const CHARACTERS := [
	{"id":&"operator_01","name":"VALERIA","role":"RECONOCIMIENTO","description":"Especialista en reconocimiento urbano y rescate.","accent":Color(0.42,0.68,0.52,1),"avatar":"res://assets/ui/avatars/medic.svg","design":"valeria"},
	{"id":&"operator_02","name":"DANTE","role":"VANGUARDIA","description":"Operador de primera línea para presión y rescate.","accent":Color(0.15,0.34,0.48,1),"avatar":"res://assets/ui/avatars/elite.svg"},
	{"id":&"operator_03","name":"PHOENIX","role":"ASALTO","description":"Especialista en ofensiva rápida y control de hordas.","accent":Color(0.82,0.30,0.18,1),"avatar":"res://assets/ui/avatars/phoenix.svg"},
	{"id":&"operator_04","name":"SENTINEL","role":"SOPORTE","description":"Operador de soporte para supervivencia prolongada.","accent":Color(0.28,0.62,0.72,1),"avatar":"res://assets/ui/avatars/sentinel.svg"},
]

static func all() -> Array:
	return CHARACTERS.duplicate(true)

static func get_character(character_id: StringName) -> Dictionary:
	for character in CHARACTERS:
		if StringName(character.get("id",&"")) == character_id:
			return Dictionary(character).duplicate(true)
	return Dictionary(CHARACTERS[0]).duplicate(true)
