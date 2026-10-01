extends SceneTree

const REQUIRED_FILES := [
	"res://project.godot",
	"res://export_presets.cfg",
	"res://VERSION",
	"res://src/main/Boot.tscn",
	"res://src/main/Boot.gd",
	"res://src/autoload/GameState.gd",
	"res://src/autoload/SaveSystem.gd",
	"res://src/game/GameWorld.gd",
	"res://src/game/HordeDirector.gd",
	"res://src/player/Player.gd",
	"res://src/enemies/Zombie.gd",
	"res://src/ui/HUD.gd",
	"res://src/ui/MobileControls.gd",
]

const COMPILE_SCRIPTS := [
	"res://src/main/Boot.gd",
	"res://src/autoload/GameState.gd",
	"res://src/autoload/SaveSystem.gd",
	"res://src/game/GameWorld.gd",
	"res://src/game/HordeDirector.gd",
	"res://src/player/Player.gd",
	"res://src/enemies/Zombie.gd",
	"res://src/ui/HUD.gd",
	"res://src/ui/MobileControls.gd",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for path in REQUIRED_FILES:
		if not FileAccess.file_exists(path):
			_fail("Missing required project file: %s" % path)
			return

	for path in COMPILE_SCRIPTS:
		var resource := load(path)
		if resource == null or not resource is Script or not (resource as Script).can_instantiate():
			_fail("GDScript could not compile: %s" % path)
			return

	if root.get_node_or_null("SaveSystem") == null:
		_fail("SaveSystem autoload is missing")
		return
	if root.get_node_or_null("GameState") == null:
		_fail("GameState autoload is missing")
		return

	var boot_scene := load("res://src/main/Boot.tscn") as PackedScene
	if boot_scene == null:
		_fail("Boot.tscn could not be loaded")
		return
	var boot := boot_scene.instantiate()
	if boot == null:
		_fail("Boot.tscn could not be instantiated")
		return
	root.add_child(boot)
	await process_frame
	await process_frame
	if boot.get_child_count() == 0:
		_fail("Boot scene did not create its menu")
		return
	boot.free()

	print("NEXORA: LAST SIGNAL smoke test passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
