class_name LastSignalOutbreakDistrict
extends "res://src/maps/campaign/CityArena.gd"

signal return_to_lobby(summary: Dictionary)

const PlayerScene=preload("res://src/player/Player.tscn")
const MobileHUDScene=preload("res://src/mobile/MobileHUD.tscn")
const HordeHUDScene=preload("res://src/horde/HordeHUD.tscn")
const Mission1=preload("res://src/campaign/data/mission_01_first_signal.tres")
const Mission2=preload("res://src/campaign/data/mission_02_last_broadcast.tres")
const InventoryScript=preload("res://src/offline/Inventory.gd")
const InventoryHUDScript=preload("res://src/offline/InventoryHUD.gd")
const LootDirectorScript=preload("res://src/offline/LootDirector.gd")
const DifficultyScript=preload("res://src/offline/DifficultyDirector.gd")
const BossScript=preload("res://src/offline/BossDirector.gd")
const SquadScript=preload("res://src/offline/OfflineSquadDirector.gd")
const ResultScript=preload("res://src/offline/RunResultOverlay.gd")

@export var game_mode:="campaign"
@export var mission_id:StringName=&"mission_01_first_signal"
@export var difficulty_id:="normal"
@export_range(0,3,1) var companion_count:=2
@export var character_id:StringName=&"operator_01"

@onready var players_root:Node3D=$LocalPlayers
@onready var player_spawns:Node3D=$PlayerSpawnPoints
@onready var horde:Node=$HordeDirector
@onready var campaign:Node=$CampaignDirector
@onready var campaign_hud:CanvasLayer=$CampaignHUD
@onready var zombies_root:Node3D=$HordeZombies
@onready var pickups_root:Node3D=$WorldPickups

var local_player:Node3D
var _ended:=false
var _mission_completed:=false
var _result:CanvasLayer
var _squad:Node

func _ready()->void:
	add_to_group("deadfall_match_flow")
	Game.start_local_session()
	super._ready()
	AudioDirector.set_context(&"match")
	var selected:=Mission2 if mission_id==&"mission_02_last_broadcast" else Mission1
	campaign.set("mission",selected)
	if horde.has_method("set_authority_override"):
		horde.call("set_authority_override",Game.authority)
	if campaign.has_method("set_authority_override"):
		campaign.call("set_authority_override",Game.authority)
	horde.connect("game_over",Callable(self,"_on_game_over"))
	horde.connect("wave_completed",Callable(self,"_on_wave_completed"))
	campaign.connect("mission_completed",Callable(self,"_on_mission_completed"))
	_spawn_local_player()
	_setup_offline_systems()
	if game_mode=="campaign":
		campaign.call_deferred("start_mission",selected,true)
	else:
		campaign.set_process(false)
		campaign_hud.hide()
	horde.call_deferred("start_run")
	print("LAST_SIGNAL_OFFLINE_READY mode=%s difficulty=%s companions=%d mission=%s" % [game_mode,difficulty_id,companion_count,String(mission_id)])

func _spawn_local_player()->void:
	if players_root.get_child_count()>0:
		return
	var player:=PlayerScene.instantiate() as Node3D
	if player==null:
		return
	player.name="Player_1"
	player.set("player_entity_id",1)
	player.set("control_mode",0)
	player.get_node("Health").set("entity_id",1)
	player.get_node("PrimaryWeapon").set("shooter_entity_id",1)
	player.get_node("SecondaryWeapon").set("shooter_entity_id",1)
	player.get_node("MacheteWeapon").set("shooter_entity_id",1)
	var inventory:=InventoryScript.new()
	inventory.name="Inventory"
	player.add_child(inventory)
	players_root.add_child(player)
	if player_spawns.get_child_count()>0:
		player.global_transform=(player_spawns.get_child(0) as Node3D).global_transform
	local_player=player
	if horde.has_method("register_player"):
		horde.call("register_player",player)
	var presenter:=player.get_node_or_null("VisualRoot/ModelPresenter")
	if presenter!=null and presenter.has_method("configure_character"):
		presenter.call_deferred("configure_character",character_id)
	_build_local_huds(player)

func _setup_offline_systems()->void:
	var difficulty:=DifficultyScript.new()
	difficulty.name="DifficultyDirector"
	add_child(difficulty)
	difficulty.setup(horde,difficulty_id)

	var boss:=BossScript.new()
	boss.name="BossDirector"
	add_child(boss)
	boss.setup(horde,difficulty_id)

	var loot:=LootDirectorScript.new()
	loot.name="LootDirector"
	add_child(loot)
	loot.setup(zombies_root,pickups_root)

	_squad=SquadScript.new()
	_squad.name="OfflineSquadDirector"
	add_child(_squad)
	_squad.setup(players_root,local_player,horde,companion_count)

func _build_local_huds(player:Node3D)->void:
	if DisplayServer.get_name()=="headless":
		return
	var mobile:=MobileHUDScene.instantiate()
	mobile.name="MobileHUD"
	mobile.set("player_path",NodePath("../LocalPlayers/Player_1"))
	add_child(mobile)
	if not OS.has_feature("mobile"):
		mobile.set("show_on_desktop",false)

	var horde_hud:=HordeHUDScene.instantiate()
	horde_hud.name="HordeHUD"
	horde_hud.set("director_path",NodePath("../HordeDirector"))
	add_child(horde_hud)

	var inventory_hud:=InventoryHUDScript.new()
	inventory_hud.name="InventoryHUD"
	add_child(inventory_hud)
	inventory_hud.bind(player)

func leave_current_match()->void:
	_finish_run("PARTIDA ABANDONADA",false)

func request_restart()->void:
	if _ended:
		return
	if horde.has_method("restart_run"):
		horde.call("restart_run")
	if game_mode=="campaign" and campaign.has_method("restart_mission"):
		campaign.call("restart_mission",false)

func _on_game_over(wave:int,score:int,kills:int)->void:
	if _ended:
		return
	_finish_run("EQUIPO ELIMINADO",false,wave,kills,score)

func _on_wave_completed(wave:int,_bonus:int)->void:
	if _ended:
		return
	if game_mode=="waves" and wave>=10:
		_finish_run("OPERACIÓN COMPLETADA",true)

func _on_mission_completed(completed_id:StringName)->void:
	if _ended or game_mode!="campaign":
		return
	_mission_completed=true
	mission_id=completed_id
	_finish_run("MISIÓN COMPLETADA",true)

func _finish_run(outcome:String,completed:bool,wave_override:int=-1,kills_override:int=-1,score_override:int=-1)->void:
	if _ended:
		return
	_ended=true
	var status:Dictionary=horde.call("get_status_snapshot") if horde!=null else {}
	var wave:=wave_override if wave_override>=0 else int(status.get("wave",0))
	var kills:=kills_override if kills_override>=0 else int(status.get("kills",0))
	var score:=score_override if score_override>=0 else int(status.get("score",0))
	if horde!=null and horde.has_method("stop_run"):
		horde.call("stop_run","run_finished")
	var reward:Dictionary=Progress.award_run(wave,kills,score,mission_id,completed and game_mode=="campaign")
	var summary:={
		"outcome":outcome,
		"completed":completed,
		"mode":game_mode,
		"difficulty":difficulty_id,
		"mission_id":String(mission_id),
		"wave":wave,
		"kills":kills,
		"score":score,
		"reward":reward,
	}
	_show_result(summary)

func _show_result(summary:Dictionary)->void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var mobile:=get_node_or_null("MobileHUD")
	if mobile!=null and mobile.has_method("set_gameplay_controls_enabled"):
		mobile.call("set_gameplay_controls_enabled",false)
	_result=ResultScript.new()
	_result.name="RunResultOverlay"
	_result.lobby_requested.connect(func(): return_to_lobby.emit(summary))
	add_child(_result)
	_result.show_result(summary)
