class_name DeadfallWeaponLoadout
extends Node

signal active_weapon_changed(slot: int, weapon_id: StringName, display_name: String, weapon: Node)

enum Slot { PRIMARY, SECONDARY, MELEE }
const SLOT_COUNT := 3

@export var primary_path := NodePath("../PrimaryWeapon")
@export var secondary_path := NodePath("../SecondaryWeapon")
@export var melee_path := NodePath("../MacheteWeapon")
@export var input_path := NodePath("../PlayerInput")
@export var active_slot: int = Slot.PRIMARY

var _primary: Node
var _secondary: Node
var _melee: Node
var _input: Node

func _ready() -> void:
	_primary = get_node_or_null(primary_path)
	_secondary = get_node_or_null(secondary_path)
	_melee = get_node_or_null(melee_path)
	_input = get_node_or_null(input_path)
	_ensure_input_actions()
	_apply_slot(active_slot)

func _process(_delta: float) -> void:
	maintain_ammunition()
	if _input == null:
		return
	if bool(_input.call("consume_action_just_pressed",&"weapon_primary")):
		request_slot(Slot.PRIMARY)
	elif bool(_input.call("consume_action_just_pressed",&"weapon_secondary")):
		request_slot(Slot.SECONDARY)
	elif bool(_input.call("consume_action_just_pressed",&"weapon_melee")):
		request_slot(Slot.MELEE)
	elif bool(_input.call("consume_action_just_pressed",&"weapon_next")):
		request_slot((active_slot+1)%SLOT_COUNT)

func maintain_ammunition() -> void:
	if active_slot == Slot.MELEE:
		return
	var owner := get_parent()
	if owner != null and owner.has_method("can_use_weapon") and not bool(owner.call("can_use_weapon")):
		return
	var weapon := get_active_weapon()
	if weapon == null or not weapon.has_method("get_ammo_in_mag"):
		return
	if int(weapon.call("get_ammo_in_mag"))>0 or bool(weapon.call("is_reloading")):
		return
	if int(weapon.call("get_reserve_ammo"))>0:
		weapon.call("start_automatic_reload")
		return
	for slot in [Slot.PRIMARY,Slot.SECONDARY]:
		var candidate:=get_weapon_for_slot(slot)
		if slot!=active_slot and candidate!=null and int(candidate.call("get_ammo_in_mag"))>0:
			_apply_slot(slot)
			return
	_apply_slot(Slot.MELEE)

func request_slot(slot: int) -> bool:
	var requested:=clampi(slot,Slot.PRIMARY,Slot.MELEE)
	if not _slot_available(requested):
		return false
	_apply_slot(requested)
	return true

func force_active_slot(slot: int) -> void:
	_apply_slot(clampi(slot,Slot.PRIMARY,Slot.MELEE))

func get_active_weapon() -> Node:
	if active_slot==Slot.SECONDARY: return _secondary
	if active_slot==Slot.MELEE: return _melee
	return _primary

func get_weapon_for_slot(slot: int) -> Node:
	if slot==Slot.SECONDARY: return _secondary
	if slot==Slot.MELEE: return _melee
	return _primary

func get_active_weapon_id() -> StringName:
	return _weapon_id(get_active_weapon(),active_slot)

func get_active_display_name() -> String:
	return _weapon_display_name(get_active_weapon(),active_slot)

func get_authoritative_state() -> Dictionary:
	return {
		"active_slot": active_slot,
		"primary": _primary.call("get_authoritative_state") if _primary != null and _primary.has_method("get_authoritative_state") else {},
		"secondary": _secondary.call("get_authoritative_state") if _secondary != null and _secondary.has_method("get_authoritative_state") else {},
		"melee": _melee.call("get_authoritative_state") if _melee != null and _melee.has_method("get_authoritative_state") else {},
	}

func add_ammo(amount: int) -> int:
	if amount<=0:
		return 0
	var remaining:=amount
	var visited:Array[Node]=[]
	for weapon in [get_active_weapon(),_primary,_secondary]:
		if weapon==null or weapon==_melee or weapon in visited or not weapon.has_method("add_reserve_ammo"):
			continue
		visited.append(weapon)
		remaining-=int(weapon.call("add_reserve_ammo",remaining))
		if remaining<=0:
			break
	return amount-remaining

func _apply_slot(slot: int) -> void:
	if not _slot_available(slot):
		return
	active_slot=slot
	if _primary!=null: _primary.call("set_input_enabled",active_slot==Slot.PRIMARY)
	if _secondary!=null: _secondary.call("set_input_enabled",active_slot==Slot.SECONDARY)
	if _melee!=null: _melee.call("set_input_enabled",active_slot==Slot.MELEE)
	var weapon:=get_active_weapon()
	active_weapon_changed.emit(active_slot,_weapon_id(weapon,active_slot),_weapon_display_name(weapon,active_slot),weapon)

func _slot_available(slot: int) -> bool:
	return get_weapon_for_slot(slot)!=null

func _weapon_id(weapon: Node,slot: int)->StringName:
	if slot==Slot.MELEE: return &"machete"
	if weapon!=null:
		var data=weapon.get("weapon_data")
		if data!=null: return StringName(data.get("weapon_id"))
	return &"weapon"

func _weapon_display_name(weapon: Node,slot: int)->String:
	if slot==Slot.MELEE: return "Machete"
	if weapon!=null:
		var data=weapon.get("weapon_data")
		if data!=null: return String(data.get("display_name"))
	return "Weapon"

func _ensure_input_actions()->void:
	var bindings={&"weapon_primary":KEY_1,&"weapon_secondary":KEY_2,&"weapon_melee":KEY_3,&"weapon_next":KEY_Q}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action,0.2)
		if InputMap.action_get_events(action).is_empty():
			var key:=InputEventKey.new()
			key.physical_keycode=int(bindings[action])
			InputMap.action_add_event(action,key)
