class_name DeadfallExternalModelCatalog
extends RefCounted

# LAST SIGNAL intentionally does not ship the separate Objetos3D repository.
# DEADFALL presentation scripts keep this compatibility facade and always fall
# back to the built-in procedural/skinned operators and infected.
static func character(_character_id: StringName) -> Dictionary:
	return {"path":"","expects_animation":false,"scale":Vector3.ONE,"rotation_degrees":Vector3.ZERO,"offset":Vector3.ZERO}

static func zombie(_variant: StringName = &"animated") -> Dictionary:
	return {"path":"","expects_animation":false,"scale":Vector3.ONE,"rotation_degrees":Vector3.ZERO,"offset":Vector3.ZERO}

static func model_exists(_config: Dictionary) -> bool:
	return false
