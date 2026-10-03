extends SceneTree

const REQUIRED := [
	"res://project.godot",
	"res://export_presets.cfg",
	"res://VERSION",
	"res://src/main/Boot.tscn",
	"res://src/lobby/Lobby.tscn",
	"res://src/maps/campaign/OutbreakDistrict.tscn",
	"res://src/player/Player.tscn",
	"res://src/customization/CosmeticCatalog.gd",
	"res://src/assets/UniversalAnimationLibrary.gd",
	"res://src/zombies/base/Zombie.tscn",
	"res://src/campaign/data/mission_01_first_signal.tres",
	"res://src/campaign/data/mission_02_last_broadcast.tres",
	"res://src/campaign/data/mission_03_blackout.tres",
	"res://src/campaign/data/mission_04_final_signal.tres",
	"res://src/weapons/data/nxr_rifle_01.tres",
	"res://src/weapons/data/nxr_smg_01.tres",
	"res://src/weapons/data/nxr_dmr_01.tres",
	"res://src/weapons/data/nxr_lmg_01.tres",
	"res://src/weapons/data/nxr_pistol_01.tres",
	"res://src/weapons/data/nxr_pistol_02.tres",
	"res://assets/ui/quarantine_hangar.webp",
	"res://assets/branding/last_signal_icon.svg",
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
	for target in ["PowerStation","GeneratorConsole","SupplyDepot","NorthGate","BeaconYard","BeaconConsole","FinalEvac"]:
		if arena.get_node_or_null("CampaignTargets/" + target) == null:
			_fail("Expanded campaign target missing: %s" % target)
			return
	arena.free()

	var animation_library = load("res://src/assets/UniversalAnimationLibrary.gd")
	if animation_library == null:
		_fail("Universal supplied animation library failed to load")
		return
	for clip_name in [&"Idle_Loop",&"Walk_Loop",&"Sprint_Loop",&"Crouch_Fwd_Loop",&"Jump_Start",&"Jump_Land",&"Pistol_Shoot",&"Pistol_Reload",&"Sword_Attack",&"Death01"]:
		if not animation_library.has_clip(clip_name):
			_fail("Required supplied animation clip missing: %s" % String(clip_name))
			return
	if String(animation_library.SOURCE_SHA256) != "42f16a4ed61d1e9f5fc7c2526894c5487148ac6ba82b64281ceb7943570f3c37":
		_fail("Animation library source hash changed unexpectedly")
		return

	var cosmetic_catalog = load("res://src/customization/CosmeticCatalog.gd")
	if cosmetic_catalog == null:
		_fail("Cosmetic catalog failed to load")
		return
	for gender in ["female","male"]:
		var wardrobe: Dictionary = cosmetic_catalog.default_loadout(gender)
		for category in cosmetic_catalog.CATEGORIES:
			var item = cosmetic_catalog.get_item(StringName(String(wardrobe.get(category,""))))
			if item.is_empty() or not cosmetic_catalog.is_compatible(item,gender):
				_fail("Default wardrobe is invalid for %s / %s" % [gender,category])
				return
	if not Progress.owns_cosmetic(cosmetic_catalog.default_profile_icon("female")) or not Progress.owns_cosmetic(cosmetic_catalog.default_profile_icon("male")):
		_fail("Starter offline profile icons are not owned")
		return

	var operator_factory = load("res://src/assets/ProceduralCharacterModel.gd")
	var operator = operator_factory.create_operator(&"operator_01",0,GuestIdentity.appearance_snapshot())
	if operator == null or not operator.has_method("animate_pose"):
		_fail("Universal offline operator failed to build")
		return
	operator.call("animate_pose",0.0,0.0,&"idle")
	operator.call("animate_pose",0.2,3.0,&"walk")
	operator.call("animate_pose",0.4,6.2,&"run")
	operator.call("animate_pose",0.6,0.0,&"reload")
	operator.free()

	var boot_scene := load("res://src/main/Boot.tscn") as PackedScene
	if boot_scene == null:
		_fail("DEADFALL-style Boot.tscn failed to load")
		return

	var lobby_scene := load("res://src/lobby/Lobby.tscn") as PackedScene
	if lobby_scene == null:
		_fail("DEADFALL-style lobby failed to load")
		return
	var lobby := lobby_scene.instantiate()
	root.add_child(lobby)
	await process_frame
	await process_frame
	if String(ProjectSettings.get_setting("application/config/icon", "")) != "res://assets/branding/last_signal_icon.svg":
		_fail("Application icon setting is missing")
		return
	var preset_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	for icon_path in [
		"res://assets/branding/android_main_icon.svg",
		"res://assets/branding/android_adaptive_foreground.svg",
		"res://assets/branding/android_adaptive_background.svg",
		"res://assets/branding/android_adaptive_monochrome.svg",
	]:
		if not preset_text.contains(icon_path):
			_fail("Android launcher icon preset is missing: %s" % icon_path)
			return
	if String(ProjectSettings.get_setting("application/config/version", "")) != "1.0.0rc":
		_fail("Unexpected public version")
		return
	if lobby.find_child("GameModeDock", true, false) == null:
		_fail("Persistent game-mode dock is missing from lobby")
		return
	for path in ["SafeArea/OperatorStage","SafeArea/PartyRail","SafeArea/MatchControls"]:
		if lobby.get_node_or_null(path) == null:
			_fail("DEADFALL lobby structure missing: %s" % path)
			return
	lobby.free()

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
