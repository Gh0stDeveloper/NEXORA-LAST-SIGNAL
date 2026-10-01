extends SceneTree

var PlayerScript: Script
var ZombieScript: Script
var HordeScript: Script

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	var save_system := root.get_node_or_null("SaveSystem")
	if game_state == null or save_system == null:
		_fail("Required autoloads are missing")
		return

	# Load gameplay scripts only after project autoloads are registered.
	PlayerScript = load("res://src/player/Player.gd") as Script
	ZombieScript = load("res://src/enemies/Zombie.gd") as Script
	HordeScript = load("res://src/game/HordeDirector.gd") as Script
	for script in [PlayerScript, ZombieScript, HordeScript]:
		if script == null or not script.can_instantiate():
			_fail("Gameplay script could not compile after autoload initialization")
			return

	game_state.begin_session()

	# Keep this smoke test synchronous: validate contracts without relying on
	# physics/render frames so the headless CI step is deterministic.
	var player := PlayerScript.new() as CharacterBody3D
	if player == null:
		_fail("Player could not be instantiated")
		return
	if player.health != 100 or player.ammo != 30 or player.reserve_ammo != 150:
		_fail("Player initial combat state mismatch")
		return
	player.take_damage(25)
	if player.health != 75:
		_fail("Player damage contract failed")
		return
	player.heal(10)
	if player.health != 85:
		_fail("Player healing contract failed")
		return

	var reward_state := {"received": false}
	var zombie := ZombieScript.new() as CharacterBody3D
	if zombie == null:
		_fail("Zombie could not be instantiated")
		return
	zombie.configure("tank", player)
	zombie.killed.connect(func(_enemy, coins, xp):
		if coins == 22 and xp == 55:
			reward_state.received = true
	)
	zombie.take_damage(999)
	if not bool(reward_state.received):
		_fail("Zombie death reward contract failed")
		return

	var director: Node = HordeScript.new()
	if director == null:
		_fail("HordeDirector could not be instantiated")
		return
	director.call("_start_next_wave")
	if int(director.wave) != 1 or int(director.remaining_to_spawn) != 6:
		_fail("Wave 1 scaling contract failed")
		return
	if String(director.call("_pick_kind")) not in ["walker", "runner"]:
		_fail("Early wave zombie selection contract failed")
		return

	player.free()
	director.free()
	print("NEXORA: LAST SIGNAL gameplay smoke test passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
