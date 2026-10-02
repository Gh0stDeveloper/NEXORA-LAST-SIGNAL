class_name LastSignalOfflineSquadDirector
extends Node

const CompanionScript = preload("res://src/offline/AICompanion.gd")
const OPERATORS := [&"operator_02",&"operator_03",&"operator_04"]

var companions: Array[Node3D] = []

func setup(players_root: Node3D, leader: Node3D, horde: Node, count: int) -> void:
	if players_root == null or leader == null:
		return
	for index in range(clampi(count,0,3)):
		var companion := CompanionScript.new()
		companion.configure(101+index,OPERATORS[index%OPERATORS.size()],leader)
		companion.name="AI_Companion_%d" % (index+1)
		players_root.add_child(companion)
		companion.global_position=leader.global_position+Vector3(float(index-1)*1.8,0,2.5+index)
		companions.append(companion)
		if horde != null and horde.has_method("register_player"):
			horde.call("register_player",companion)
