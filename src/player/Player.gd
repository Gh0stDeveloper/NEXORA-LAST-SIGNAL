extends CharacterBody3D

signal stats_changed(health: int, ammo: int, reserve: int)
signal died

const WALK_SPEED := 5.2
const SPRINT_SPEED := 8.0
const JUMP_VELOCITY := 5.2
const MAG_SIZE := 30
const MAX_HEALTH := 100
const SHOT_DISTANCE := 120.0
const SHOT_DAMAGE := 28
const FIRE_INTERVAL := 0.11

var health := MAX_HEALTH
var ammo := MAG_SIZE
var reserve_ammo := 150
var sensitivity := 0.16
var gravity := 9.8
var pitch := 0.0
var fire_cooldown := 0.0
var mobile_move := Vector2.ZERO
var mobile_look := Vector2.ZERO
var mobile_fire_held := false
var input_enabled := true

var camera: Camera3D

func _ready() -> void:
	sensitivity = float(SaveSystem.get_setting("sensitivity", 0.16))
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_build_body()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	stats_changed.emit(health, ammo, reserve_ammo)

func _build_body() -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 1.62, 0.0)
	camera.current = true
	camera.fov = 78.0
	add_child(camera)

	var weapon := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.12, 0.65)
	weapon.mesh = mesh
	weapon.position = Vector3(0.28, -0.22, -0.62)
	camera.add_child(weapon)

func _physics_process(delta: float) -> void:
	if not input_enabled:
		velocity = Vector3.ZERO
		return

	fire_cooldown = maxf(fire_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_vec := _desktop_move_vector()
	if mobile_move.length() > 0.05:
		input_vec = mobile_move
	input_vec = input_vec.limit_length(1.0)

	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	var wish_dir := (right * input_vec.x + forward * -input_vec.y).normalized()

	var sprinting := Input.is_key_pressed(KEY_SHIFT) and input_vec.y < -0.1
	var speed := SPRINT_SPEED if sprinting else WALK_SPEED
	velocity.x = move_toward(velocity.x, wish_dir.x * speed, 18.0 * delta)
	velocity.z = move_toward(velocity.z, wish_dir.z * speed, 18.0 * delta)

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if mobile_look != Vector2.ZERO:
		apply_look(mobile_look)
		mobile_look = Vector2.ZERO

	if mobile_fire_held or (not OS.has_feature("mobile") and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		shoot()

	move_and_slide()

func _desktop_move_vector() -> Vector2:
	var x := 0.0
	var y := 0.0
	if Input.is_key_pressed(KEY_A):
		x -= 1.0
	if Input.is_key_pressed(KEY_D):
		x += 1.0
	if Input.is_key_pressed(KEY_W):
		y -= 1.0
	if Input.is_key_pressed(KEY_S):
		y += 1.0
	return Vector2(x, y)

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_look(event.relative)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reload()

func apply_look(delta: Vector2) -> void:
	rotate_y(deg_to_rad(-delta.x * sensitivity))
	pitch = clampf(pitch - deg_to_rad(delta.y * sensitivity), deg_to_rad(-80.0), deg_to_rad(80.0))
	camera.rotation.x = pitch

func set_mobile_move(value: Vector2) -> void:
	mobile_move = value

func add_mobile_look(delta: Vector2) -> void:
	mobile_look += delta

func set_mobile_fire(held: bool) -> void:
	mobile_fire_held = held

func mobile_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func shoot() -> void:
	if fire_cooldown > 0.0 or not input_enabled:
		return
	if ammo <= 0:
		reload()
		return
	fire_cooldown = FIRE_INTERVAL
	ammo -= 1
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * SHOT_DISTANCE)
	query.exclude = [get_rid()]
	query.collide_with_areas = true
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var hit := false
	if not result.is_empty():
		var collider = result.get("collider")
		if collider != null and collider.has_method("take_damage"):
			collider.take_damage(SHOT_DAMAGE)
			hit = true
	GameState.record_shot(hit)
	stats_changed.emit(health, ammo, reserve_ammo)

func reload() -> void:
	if ammo >= MAG_SIZE or reserve_ammo <= 0 or not input_enabled:
		return
	var needed := MAG_SIZE - ammo
	var amount := mini(needed, reserve_ammo)
	ammo += amount
	reserve_ammo -= amount
	stats_changed.emit(health, ammo, reserve_ammo)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(health - max(amount, 0), 0)
	stats_changed.emit(health, ammo, reserve_ammo)
	if health == 0:
		input_enabled = false
		mobile_fire_held = false
		died.emit()

func add_ammo(amount: int) -> void:
	reserve_ammo += max(amount, 0)
	stats_changed.emit(health, ammo, reserve_ammo)

func heal(amount: int) -> void:
	health = mini(MAX_HEALTH, health + max(amount, 0))
	stats_changed.emit(health, ammo, reserve_ammo)

func is_dead() -> bool:
	return health <= 0
