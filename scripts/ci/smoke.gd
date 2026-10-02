extends SceneTree

const REQUIRED := [
	"res://project.godot",
	"res://export_presets.cfg",
	"res://VERSION",
	"res://src/main/Boot.tscn",
	"res://src/lobby/Lobby.tscn",
	"res://src/maps/campaign/OutbreakDistrict.tscn",
	"res://src/player/Player.tscn",
	"res://src/zombies/base/Zombie.tscn",
	"res://src/campaign/data/mission_01_first_signal.tres",
	"res://src/campaign/data/mission_02_last_broadcast.tres",
	"res://assets/ui/quarantine_hangar.webp",
	"res://assets/audio/last_signal.ogg",
	"res://assets/audio/quarantine_wind.ogg",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for path in REQUIRED:
		if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			_fail("Missing required DEADFALL-port resource: %s" % path)
			return

	var scripts:Array[String]=[]
	_collect_scripts("res://src",scripts)
	for path in scripts:
		var resource:=load(path)
		if resource==null or not resource is Script or not (resource as Script).can_instantiate():
			_fail("Runtime script failed to compile: %s" % path)
			return

	for autoload_name in ["Game","Settings","AudioDirector","PerformanceTuner","GuestIdentity","Gore","Progress"]:
		if root.get_node_or_null(autoload_name) == null:
			_fail("Missing autoload: %s" % autoload_name)
			return

	var arena_scene := load("res://src/maps/campaign/OutbreakDistrict.tscn") as PackedScene
	if arena_scene == null:
		_fail("Offline campaign scene failed to load")
		return
	var arena := arena_scene.instantiate()
	if arena == null:
		_fail("Offline campaign scene failed to instantiate")
		return
	if arena.get_node_or_null("LocalPlayers") == null or arena.get_node_or_null("HordeDirector") == null or arena.get_node_or_null("CampaignDirector") == null:
		_fail("Offline campaign scene is missing local gameplay nodes")
		return
	if arena.get_node_or_null("NetworkSession") != null or arena.get_node_or_null("CampaignNetworkBridge") != null:
		_fail("Online nodes leaked into offline campaign scene")
		return
	arena.free()

	var boot_scene := load("res://src/main/Boot.tscn") as PackedScene
	if boot_scene == null:
		_fail("Boot.tscn failed to load")
		return
	var boot := boot_scene.instantiate()
	root.add_child(boot)
	await process_frame
	await process_frame
	if boot.get_child_count() == 0:
		_fail("Boot did not create offline lobby")
		return
	boot.free()

	print("NEXORA: LAST SIGNAL project smoke test passed; scripts=%d" % scripts.size())
	quit(0)

func _collect_scripts(path:String,out:Array[String])->void:
	var dir:=DirAccess.open(path)
	if dir==null:
		return
	dir.list_dir_begin()
	var name:=dir.get_next()
	while not name.is_empty():
		if name!="." and name!="..":
			var full:=path.path_join(name)
			if dir.current_is_dir():
				_collect_scripts(full,out)
			elif name.ends_with(".gd"):
				out.append(full)
		name=dir.get_next()
	dir.list_dir_end()

func _fail(message:String)->void:
	push_error(message)
	quit(1)
