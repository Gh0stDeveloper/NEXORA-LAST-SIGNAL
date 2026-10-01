extends CharacterBody3D

signal killed(zombie: CharacterBody3D, coins: int, xp: int)

var target: CharacterBody3D
var kind := "walker"
var health := 70
var move_speed := 2.5
var attack_damage := 9
var attack_interval := 1.0
var attack_cooldown := 0.0
var reward_coins := 7
var reward_xp := 18
var gravity := 9.8

func configure(zombie_kind: String, player: CharacterBody3D) -> void:
    kind = zombie_kind
    target = player
    match kind:
        "runner":
            health = 55; move_speed = 4.6; attack_damage = 7; reward_coins = 8; reward_xp = 20
        "tank":
            health = 230; move_speed = 1.55; attack_damage = 22; reward_coins = 22; reward_xp = 55
        "crawler":
            health = 45; move_speed = 3.2; attack_damage = 6; reward_coins = 6; reward_xp = 16
        "screamer":
            health = 85; move_speed = 2.8; attack_damage = 12; reward_coins = 13; reward_xp = 30
        _:
            health = 70; move_speed = 2.5; attack_damage = 9; reward_coins = 7; reward_xp = 18

func _ready() -> void:
    gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
    _build_visual()

func _build_visual() -> void:
    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42 if kind != "tank" else 0.58
    shape.height = 1.7 if kind != "crawler" else 0.9
    collision.shape = shape
    collision.position.y = shape.height * 0.5
    add_child(collision)

    var body := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = shape.radius
    mesh.height = shape.height
    body.mesh = mesh
    body.position.y = shape.height * 0.5
    var material := StandardMaterial3D.new()
    match kind:
        "runner": material.albedo_color = Color(0.58, 0.18, 0.12)
        "tank": material.albedo_color = Color(0.25, 0.23, 0.20)
        "crawler": material.albedo_color = Color(0.36, 0.42, 0.18)
        "screamer": material.albedo_color = Color(0.50, 0.30, 0.48)
        _: material.albedo_color = Color(0.30, 0.43, 0.25)
    body.material_override = material
    add_child(body)

func _physics_process(delta: float) -> void:
    if target == null or not is_instance_valid(target) or health <= 0:
        return
    attack_cooldown = maxf(attack_cooldown - delta, 0.0)
    if not is_on_floor():
        velocity.y -= gravity * delta

    var offset := target.global_position - global_position
    var horizontal := Vector3(offset.x, 0.0, offset.z)
    var distance := horizontal.length()
    if distance > 1.45:
        var dir := horizontal.normalized()
        velocity.x = dir.x * move_speed
        velocity.z = dir.z * move_speed
        look_at(global_position + dir, Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
        if attack_cooldown <= 0.0 and target.has_method("take_damage"):
            attack_cooldown = attack_interval
            target.take_damage(attack_damage)
    move_and_slide()

func take_damage(amount: int) -> void:
    if health <= 0:
        return
    health -= max(amount, 0)
    if health <= 0:
        killed.emit(self, reward_coins, reward_xp)
        queue_free()
