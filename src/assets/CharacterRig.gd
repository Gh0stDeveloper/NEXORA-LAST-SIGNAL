class_name DeadfallCharacterRig
extends Node3D

const UniversalAnimations = preload("res://src/assets/UniversalAnimationLibrary.gd")

var infected := false
var archetype: StringName = &"walker"
var appearance: Dictionary = {}
var _weapon_slot := -1
var _weapon: Node3D
var _rest_rotations: Dictionary = {}
var _active_clip: StringName = &""
var _clip_started_at := 0.0
var _one_shot_until := 0.0
var _last_requested_action: StringName = &""
var _animation_ready := false

func animate_pose(time: float, speed: float, action: StringName = &"idle") -> void:
	if infected:
		_animate_infected(time, speed, action)
		return
	_animate_operator(time, speed, action)

func _animate_operator(time: float, speed: float, action: StringName) -> void:
	if not _animation_ready:
		_capture_rest_pose()
		_animation_ready = true

	var requested := _clip_for(action, speed)
	var is_one_shot := action in [&"attack", &"melee", &"reload", &"hurt", &"jump_start", &"jump_land", &"interact"]
	if action == &"death":
		if _active_clip != &"Death01":
			_begin_clip(&"Death01", time, INF)
	elif is_one_shot and action != _last_requested_action:
		var clip_data := UniversalAnimations.clip(requested)
		var duration := float(clip_data.get("duration", 0.35))
		_begin_clip(requested, time, time + maxf(0.12, duration))
	elif time >= _one_shot_until and requested != _active_clip:
		_begin_clip(requested, time, 0.0)

	_last_requested_action = action
	if _active_clip == &"":
		_active_clip = &"Idle_Loop"
	_apply_clip(_active_clip, time)

	# Keep long guns attached to the procedural grip while the source animation
	# supplies torso/leg motion. Pistol/sword one-shots keep their authored arms.
	if is_instance_valid(_weapon) and (_weapon_slot == 0 or (action not in [&"attack", &"melee", &"reload"])):
		_pose_weapon_arms(time, action)

	if action in [&"crouch", &"crouch_idle", &"crouch_walk", &"crawl"]:
		position.y = -0.10
	elif action == &"death":
		position.y = 0.04
	else:
		position.y = lerpf(position.y, 0.0, 0.28)

func _begin_clip(clip_name: StringName, time: float, locked_until: float) -> void:
	if not UniversalAnimations.has_clip(clip_name):
		clip_name = &"Idle_Loop"
	_active_clip = clip_name
	_clip_started_at = time
	_one_shot_until = locked_until

func _clip_for(action: StringName, speed: float) -> StringName:
	match action:
		&"death": return &"Death01"
		&"hurt": return &"Hit_Chest"
		&"crouch_idle", &"crawl": return &"Crouch_Idle_Loop"
		&"crouch", &"crouch_walk": return &"Crouch_Fwd_Loop"
		&"jump_start": return &"Jump_Start"
		&"jump", &"jump_loop": return &"Jump_Loop"
		&"jump_land": return &"Jump_Land"
		&"reload": return &"Pistol_Reload"
		&"aim": return &"Pistol_Aim_Neutral"
		&"melee": return &"Sword_Attack" if _weapon_slot == 2 else &"Punch_Cross"
		&"attack":
			if _weapon_slot == 2:
				return &"Sword_Attack"
			return &"Pistol_Shoot"
		&"interact": return &"Interact"
		&"run": return &"Sprint_Loop" if speed >= 5.7 else &"Jog_Fwd_Loop"
		&"walk": return &"Walk_Loop"
		_:
			return &"Pistol_Idle_Loop" if _weapon_slot == 1 else (&"Sword_Idle" if _weapon_slot == 2 else &"Idle_Loop")

func _capture_rest_pose() -> void:
	for path_value in UniversalAnimations.paths():
		var path := String(path_value)
		if path == "__root__":
			continue
		var node := get_node_or_null(path) as Node3D
		if node != null:
			_rest_rotations[path] = node.rotation

func _apply_clip(clip_name: StringName, time: float) -> void:
	var clip_data := UniversalAnimations.clip(clip_name)
	if clip_data.is_empty():
		return
	var frames: Array = clip_data.get("frames", [])
	if frames.is_empty():
		return
	var duration := maxf(0.001, float(clip_data.get("duration", 0.1)))
	var local_time := maxf(0.0, time - _clip_started_at)
	if bool(clip_data.get("loop", false)):
		local_time = fposmod(local_time, duration)
	else:
		local_time = minf(local_time, duration)
	var frame_pos := local_time * UniversalAnimations.fps()
	var a_index := clampi(int(floor(frame_pos)), 0, frames.size() - 1)
	var b_index := mini(a_index + 1, frames.size() - 1)
	var blend := clampf(frame_pos - floor(frame_pos), 0.0, 1.0)
	var a: Array = frames[a_index]
	var b: Array = frames[b_index]
	var paths := UniversalAnimations.paths()
	for path_index in range(paths.size()):
		var path := String(paths[path_index])
		if path == "__root__" or not _rest_rotations.has(path):
			continue
		var node := get_node_or_null(path) as Node3D
		if node == null:
			continue
		var offset := path_index * 3
		if offset + 2 >= a.size() or offset + 2 >= b.size():
			continue
		var source_delta := Vector3(
			lerpf(float(a[offset]), float(b[offset]), blend),
			lerpf(float(a[offset + 1]), float(b[offset + 1]), blend),
			lerpf(float(a[offset + 2]), float(b[offset + 2]), blend)
		) * 0.1
		# The source is a Unity-standard humanoid. A small attenuation keeps the
		# source motion natural on LAST SIGNAL's compact procedural proportions.
		var delta := source_delta * 0.82 * PI / 180.0
		var rest: Vector3 = _rest_rotations[path]
		node.rotation.x = rest.x + delta.x
		node.rotation.y = rest.y + delta.y
		node.rotation.z = rest.z + delta.z

func _animate_infected(time: float, speed: float, action: StringName) -> void:
	var stride := clampf(speed / 4.0, 0.0, 1.0)
	var cycle := time * (6.0 + stride * 4.0)
	var death := action == &"death"
	var crawl := action == &"crawl"
	var body := get_node_or_null("Torso") as Node3D
	if body != null:
		body.rotation.z = sin(time * 1.5) * 0.012
		body.rotation.x = -0.10
		if action == &"hurt":
			body.rotation.z += sin(time * 22.0) * 0.1
	for side in [-1, 1]:
		var prefix := "Left" if side < 0 else "Right"
		var leg := get_node_or_null(prefix + "Leg") as Node3D
		if leg != null:
			leg.rotation.x = sin(cycle + (PI if side < 0 else 0.0)) * stride * 0.48
			var knee := leg.get_node_or_null("Knee") as Node3D
			if knee != null:
				knee.rotation.x = maxf(0.0, -sin(cycle + (PI if side < 0 else 0.0))) * stride * 0.75
		var arm := get_node_or_null(prefix + "Arm") as Node3D
		if arm != null:
			arm.rotation.x = -0.28 + sin(cycle + side) * stride * 0.22
			arm.rotation.z = side * -0.14
			if action == &"attack":
				arm.rotation.x = -1.3 + sin(time * 14.0) * 0.4
	if crawl:
		rotation.x = -1.43
		position.y = 0.24
	elif death:
		rotation.x = 1.48
		position.y = 0.16
	else:
		rotation.x = 0.0
		position.y = sin(time * 2.1) * 0.004 + absf(sin(cycle)) * stride * 0.012

func equip_visual(slot: int) -> void:
	if infected or _weapon_slot == slot:
		return
	_weapon_slot = slot
	if is_instance_valid(_weapon):
		_weapon.free()
	var factory = load("res://src/assets/ProceduralWeaponModels.gd")
	_weapon = factory.create_view_model(&"nxr_rifle_01" if slot == 0 else (&"nxr_pistol_01" if slot == 1 else &"machete"))
	_weapon.name = "HeldWeapon"
	_weapon.scale = Vector3.ONE * 0.78
	_weapon.position = Vector3(0.08, 1.13, -0.28)
	_weapon.rotation = Vector3(-0.13, 1.05, 0.03)
	if slot == 1:
		_weapon.position = Vector3(0.10, 1.09, -0.35)
		_weapon.rotation = Vector3(-0.12, 0.32, 0)
	if slot == 2:
		_weapon.rotation = Vector3(-0.20, 0.25, -0.45)
		_weapon.position = Vector3(0.31, 1.02, -0.23)
	add_child(_weapon)

func _pose_weapon_arms(time: float, action: StringName) -> void:
	for side in [-1, 1]:
		if _weapon_slot == 2 and side == -1:
			continue
		var prefix := "Left" if side < 0 else "Right"
		var arm := get_node_or_null(prefix + "Arm") as Node3D
		var grip := _weapon.get_node_or_null("GripLeft" if side < 0 else "GripRight") as Node3D
		if arm == null or grip == null:
			continue
		var elbow := arm.get_node_or_null("Elbow") as Node3D
		if elbow == null:
			continue
		var target: Vector3 = _weapon.transform * grip.position
		if action == &"attack":
			target.z += sin(time * 35.0) * 0.008
		var upper_length := 0.24
		var lower_length := 0.255
		var reach := target - arm.position
		var distance := clampf(reach.length(), 0.06, upper_length + lower_length - 0.002)
		var direction := reach.normalized()
		var pole := Vector3(float(side) * 0.7, -0.6, 0.15)
		pole = (pole - direction * pole.dot(direction)).normalized()
		var along := (upper_length * upper_length + distance * distance - lower_length * lower_length) / (2.0 * distance)
		var bend := sqrt(maxf(0.0, upper_length * upper_length - along * along))
		var elbow_at := arm.position + direction * along + pole * bend
		arm.quaternion = Quaternion(Vector3.DOWN, (elbow_at - arm.position).normalized())
		var lower_direction := arm.basis.inverse() * (target - elbow_at).normalized()
		elbow.quaternion = Quaternion(Vector3.DOWN, lower_direction.normalized())
		var hand := elbow.get_node_or_null("Hand") as Node3D
		if hand != null:
			hand.basis = (arm.basis * elbow.basis).inverse() * _weapon.basis.orthonormalized()
