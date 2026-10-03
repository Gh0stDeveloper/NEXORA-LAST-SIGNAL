class_name LastSignalOfflineSquadDirector
extends Node

signal player_revive_status_changed(visible: bool, target_name: String, progress: float)

const CompanionScript = preload("res://src/offline/AICompanion.gd")
const OPERATORS := [&"operator_02",&"operator_03",&"operator_04"]

var companions: Array[Node3D] = []
var _leader: Node3D
var _leader_input: Node
var _player_revive_target: Node3D
var _player_revive_elapsed := 0.0

func setup(players_root: Node3D, leader: Node3D, horde: Node, count: int) -> void:
	if players_root == null or leader == null:
		return
	_leader = leader
	_leader_input = leader.get_node_or_null("PlayerInput")
	for index in range(clampi(count,0,3)):
		var companion := CompanionScript.new()
		companion.configure(101+index,OPERATORS[index%OPERATORS.size()],leader)
		companion.name="AI_Companion_%d" % (index+1)
		players_root.add_child(companion)
		companion.global_position=leader.global_position+Vector3(float(index-1)*1.8,0,2.5+index)
		companions.append(companion)
		if horde != null and horde.has_method("register_player"):
			horde.call("register_player",companion)
	set_process(not companions.is_empty())

func _process(delta: float) -> void:
	_process_player_revive(delta)

func get_companions() -> Array[Node3D]:
	return companions.duplicate()

func get_player_revive_status() -> Dictionary:
	if _player_revive_target == null or not is_instance_valid(_player_revive_target):
		return {"visible":false,"target":"","progress":0.0}
	return {
		"visible":true,
		"target":_player_revive_target.name,
		"progress":_current_target_progress(),
	}

func _process_player_revive(delta: float) -> void:
	if _leader == null or not is_instance_valid(_leader) or _leader_input == null:
		_reset_player_revive()
		return
	var leader_life := _leader.get_node_or_null("LifeState")
	if leader_life != null and leader_life.has_method("is_alive") and not bool(leader_life.call("is_alive")):
		_reset_player_revive()
		return

	var target := _nearest_downed_companion()
	if target == null:
		_reset_player_revive()
		return
	var life := target.get_node_or_null("LifeState")
	if life == null:
		_reset_player_revive()
		return
	var revive_distance := float(life.call("get_revive_distance")) if life.has_method("get_revive_distance") else 2.8
	var distance := _leader.global_position.distance_to(target.global_position)
	if distance > revive_distance:
		_reset_player_revive()
		return

	if target != _player_revive_target:
		_reset_player_revive()
		_player_revive_target = target

	var pressed := bool(_leader_input.call("is_action_pressed", &"interact")) if _leader_input.has_method("is_action_pressed") else false
	if not pressed:
		_player_revive_elapsed = 0.0
		if life.has_method("clear_revive_progress_authoritative"):
			life.call("clear_revive_progress_authoritative", _leader_entity_id())
		player_revive_status_changed.emit(true, target.name, 0.0)
		return

	_player_revive_elapsed += delta
	var hold := float(life.call("get_revive_hold_seconds")) if life.has_method("get_revive_hold_seconds") else 2.6
	var progress := clampf(_player_revive_elapsed / maxf(0.25, hold), 0.0, 1.0)
	if life.has_method("set_revive_progress_authoritative"):
		life.call("set_revive_progress_authoritative", progress, _leader_entity_id())
	player_revive_status_changed.emit(true, target.name, progress)
	if progress >= 1.0 and life.has_method("revive_authoritative"):
		if bool(life.call("revive_authoritative", _leader_entity_id())):
			AudioDirector.play_ui(&"ui_confirm")
			if OS.has_feature("mobile"):
				Input.vibrate_handheld(70)
		_reset_player_revive()

func _nearest_downed_companion() -> Node3D:
	var best: Node3D
	var best_distance := INF
	for companion in companions:
		if companion == null or not is_instance_valid(companion):
			continue
		var life := companion.get_node_or_null("LifeState")
		if life == null or not life.has_method("is_downed") or not bool(life.call("is_downed")):
			continue
		var distance := _leader.global_position.distance_squared_to(companion.global_position)
		if distance < best_distance:
			best_distance = distance
			best = companion
	return best

func _leader_entity_id() -> int:
	var value = _leader.get("player_entity_id") if _leader != null else 1
	return int(value) if value != null else 1

func _current_target_progress() -> float:
	if _player_revive_target == null or not is_instance_valid(_player_revive_target):
		return 0.0
	var life := _player_revive_target.get_node_or_null("LifeState")
	return float(life.get("revive_progress")) if life != null else 0.0

func _reset_player_revive() -> void:
	if _player_revive_target != null and is_instance_valid(_player_revive_target):
		var life := _player_revive_target.get_node_or_null("LifeState")
		if life != null and life.has_method("clear_revive_progress_authoritative"):
			life.call("clear_revive_progress_authoritative", _leader_entity_id())
	_player_revive_target = null
	_player_revive_elapsed = 0.0
	player_revive_status_changed.emit(false, "", 0.0)
