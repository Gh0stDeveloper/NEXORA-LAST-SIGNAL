extends SceneTree

func _initialize()->void:
	call_deferred("_run")

func _run()->void:
	var game:=root.get_node_or_null("Game")
	if game==null:
		_fail("Game autoload missing")
		return
	game.call("start_local_session")
	if not bool(game.call("is_local_session")) or not bool(game.call("is_simulation_authority")):
		_fail("Local authority was not established")
		return
	if bool(game.call("is_network_client")) or bool(game.call("is_dedicated_server")):
		_fail("Offline Game exposed an online session mode")
		return

	var player_scene:=load("res://src/player/Player.tscn") as PackedScene
	var player:=player_scene.instantiate() as CharacterBody3D
	if player==null:
		_fail("Player scene failed to instantiate")
		return
	root.add_child(player)
	await process_frame
	var health:=player.get_node_or_null("Health")
	if health==null:
		_fail("Player Health missing")
		return
	var before:=float(health.get("current_health"))
	var DamageEventScript:=load("res://src/core/damage/DamageEvent.gd") as Script
	var event=DamageEventScript.new()
	event.attacker_id=999
	event.victim_id=1
	event.weapon_id=&"ci_test"
	event.amount=20.0
	event.damage_type=DamageEventScript.DamageType.BULLET
	event.body_part=DamageEventScript.BodyPart.CHEST
	if not bool(game.get("authority").call("resolve_damage",event)):
		_fail("LocalAuthority rejected valid local damage")
		return
	if float(health.get("current_health"))>=before:
		_fail("Local damage did not change health")
		return

	var InventoryScript:=load("res://src/offline/Inventory.gd") as Script
	var inventory:=InventoryScript.new()
	if int(inventory.call("add_item",&"medkit",2))!=2 or not bool(inventory.call("has_item",&"medkit",2)):
		_fail("Local inventory contract failed")
		return
	if not bool(inventory.call("consume_item",&"medkit",1)):
		_fail("Local inventory consumption failed")
		return
	inventory.free()

	var Rules:=load("res://src/horde/HordeRules.gd") as Script
	if int(Rules.wave_total(1,1))!=6 or int(Rules.wave_total(5,1))<=6:
		_fail("Horde scaling contract failed")
		return

	var Modes:=load("res://src/modes/ModeCatalog.gd") as Script
	for mode_id in ["campaign","waves","endless"]:
		if Dictionary(Modes.find(mode_id)).is_empty() or bool(Modes.is_pvp(mode_id)):
			_fail("Offline mode catalog contract failed: %s" % mode_id)
			return

	var External:=load("res://src/assets/ExternalModelCatalog.gd") as Script
	if bool(External.model_exists(External.character(&"operator_01"))):
		_fail("Objetos3D external dependency unexpectedly enabled")
		return

	var Store:=load("res://src/campaign/CampaignSaveStore.gd") as Script
	var slot:="ci_offline_contract"
	Store.clear_progress(slot)
	if not bool(Store.save_progress(slot,{"mission_id":"ci","objective_index":2,"checkpoint_id":"gate"})):
		_fail("Campaign checkpoint save failed")
		return
	var restored:Dictionary=Store.load_progress(slot)
	Store.clear_progress(slot)
	if int(restored.get("objective_index",-1))!=2 or String(restored.get("checkpoint_id",""))!="gate":
		_fail("Campaign checkpoint restore failed")
		return

	player.free()
	print("NEXORA: LAST SIGNAL offline gameplay smoke test passed")
	quit(0)

func _fail(message:String)->void:
	push_error(message)
	quit(1)
