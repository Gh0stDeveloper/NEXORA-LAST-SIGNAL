extends Node

const LobbyScene=preload("res://src/lobby/Lobby.tscn")
const ArenaScene=preload("res://src/maps/campaign/OutbreakDistrict.tscn")
const LoadingScript=preload("res://src/ui/MatchLoadingOverlay.gd")

var lobby:Control
var arena:Node3D
var loading:CanvasLayer

func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	Game.start_local_session()
	_show_lobby()

func _show_lobby()->void:
	get_tree().paused=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	AudioDirector.set_context(&"lobby")
	if lobby!=null and is_instance_valid(lobby):
		lobby.queue_free()
	lobby=LobbyScene.instantiate()
	lobby.start_requested.connect(_start_operation)
	add_child(lobby)

func _start_operation(config:Dictionary)->void:
	if lobby!=null and is_instance_valid(lobby):
		lobby.queue_free()
		lobby=null
	loading=LoadingScript.new()
	add_child(loading)
	loading.begin("")
	loading.set_stage("Cargando ciudad y sistemas locales…",0.45)
	call_deferred("_spawn_operation",config)

func _spawn_operation(config:Dictionary)->void:
	await get_tree().process_frame
	Game.start_local_session()
	arena=ArenaScene.instantiate() as Node3D
	arena.set("game_mode",String(config.get("mode","campaign")))
	arena.set("mission_id",StringName(config.get("mission_id",&"mission_01_first_signal")))
	arena.set("difficulty_id",String(config.get("difficulty","normal")))
	arena.set("companion_count",int(config.get("companions",2)))
	arena.set("character_id",StringName(config.get("character_id",&"operator_01")))
	arena.connect("return_to_lobby",Callable(self,"_on_return_to_lobby"))
	add_child(arena)
	if loading!=null and is_instance_valid(loading):
		loading.complete()
		loading.queue_free()
		loading=null

func _on_return_to_lobby(_summary:Dictionary={}) ->void:
	if arena!=null and is_instance_valid(arena):
		arena.queue_free()
	arena=null
	call_deferred("_show_lobby")
