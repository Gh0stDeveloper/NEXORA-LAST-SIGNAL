extends Node3D

signal leave_to_menu(summary: Dictionary)

const PlayerScript = preload("res://src/player/Player.gd")
const HordeScript = preload("res://src/game/HordeDirector.gd")
const HUDScript = preload("res://src/ui/HUD.gd")
const MobileControlsScript = preload("res://src/ui/MobileControls.gd")

var player: CharacterBody3D
var director: Node
var hud: CanvasLayer
var mobile_controls: CanvasLayer
var ended := false
var paused_locally := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    randomize()
    GameState.begin_session()
    _build_environment()
    _spawn_player()
    _create_runtime_systems()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        toggle_pause()

func _build_environment() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.055, 0.065, 0.075)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.55, 0.62, 0.72)
    env.ambient_light_energy = 0.72
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment = env
    add_child(environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -28, 0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    add_child(sun)

    var ground := StaticBody3D.new()
    var ground_collision := CollisionShape3D.new()
    var ground_shape := BoxShape3D.new()
    ground_shape.size = Vector3(90, 1, 90)
    ground_collision.shape = ground_shape
    ground_collision.position.y = -0.5
    ground.add_child(ground_collision)
    var ground_mesh := MeshInstance3D.new()
    var ground_box := BoxMesh.new()
    ground_box.size = Vector3(90, 1, 90)
    ground_mesh.mesh = ground_box
    ground_mesh.position.y = -0.5
    var ground_mat := StandardMaterial3D.new()
    ground_mat.albedo_color = Color(0.12, 0.14, 0.13)
    ground_mesh.material_override = ground_mat
    ground.add_child(ground_mesh)
    add_child(ground)

    for i in 18:
        _add_ruin(i)

func _add_ruin(index: int) -> void:
    var angle := float(index) / 18.0 * TAU
    var radius := 18.0 + float(index % 4) * 5.0
    var size := Vector3(3.5 + float(index % 3), 2.8 + float(index % 4), 3.5 + float((index + 1) % 3))
    var body := StaticBody3D.new()
    body.position = Vector3(cos(angle) * radius, size.y * 0.5, sin(angle) * radius)
    var shape := CollisionShape3D.new()
    var box_shape := BoxShape3D.new()
    box_shape.size = size
    shape.shape = box_shape
    body.add_child(shape)
    var mesh_instance := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh_instance.mesh = box
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.16 + (index % 2) * 0.025, 0.15, 0.14)
    mesh_instance.material_override = material
    body.add_child(mesh_instance)
    add_child(body)

func _spawn_player() -> void:
    player = PlayerScript.new()
    player.position = Vector3(0, 0.1, 0)
    player.died.connect(_on_player_died)
    add_child(player)

func _create_runtime_systems() -> void:
    director = HordeScript.new()
    add_child(director)
    director.setup(self, player)

    hud = HUDScript.new()
    add_child(hud)
    hud.bind(player, director)
    hud.pause_requested.connect(toggle_pause)
    hud.exit_requested.connect(_exit_to_menu)

    var show_touch := OS.has_feature("mobile") and bool(SaveSystem.get_setting("show_mobile_controls", true))
    if show_touch:
        mobile_controls = MobileControlsScript.new()
        add_child(mobile_controls)
        mobile_controls.bind(player)

func toggle_pause() -> void:
    if ended:
        return
    paused_locally = not paused_locally
    get_tree().paused = paused_locally
    player.input_enabled = not paused_locally
    if paused_locally:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        hud.show_pause(_resume)
    else:
        _resume()

func _resume() -> void:
    paused_locally = false
    get_tree().paused = false
    if is_instance_valid(player):
        player.input_enabled = true
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    hud.hide_overlay()

func _on_player_died() -> void:
    if ended:
        return
    ended = true
    director.active = false
    var summary := GameState.finish_session()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    hud.show_game_over(summary)

func _exit_to_menu() -> void:
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    var summary := GameState.run_stats.duplicate(true) if ended else GameState.finish_session()
    leave_to_menu.emit(summary)
    queue_free()
