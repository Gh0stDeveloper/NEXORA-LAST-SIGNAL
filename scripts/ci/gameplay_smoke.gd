extends SceneTree

const PlayerScript = preload("res://src/player/Player.gd")
const ZombieScript = preload("res://src/enemies/Zombie.gd")
const HordeScript = preload("res://src/game/HordeDirector.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GameState.begin_session()

	var arena := Node3D.new()
	root.add_child(arena)

	var player := PlayerScript.new() as CharacterBody3D
	arena.add_child(player)
	await process_frame
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
	zombie.configure("tank", player)
	zombie.killed.connect(func(_enemy, coins, xp):
		if coins == 22 and xp == 55:
			reward_state.received = true
	)
	arena.add_child(zombie)
	await process_frame
	zombie.take_damage(999)
	await process_frame
	if not bool(reward_state.received):
		_fail("Zombie death reward contract failed")
		return

	var director := HordeScript.new()
	arena.add_child(director)
	director.setup(arena, player)
	director.call("_start_next_wave")
	if int(director.wave) != 1 or int(director.remaining_to_spawn) != 6:
		_fail("Wave 1 scaling contract failed")
		return
	if String(director.call("_pick_kind")) not in ["walker", "runner"]:
		_fail("Early wave zombie selection contract failed")
		return

	arena.free()
	print("NEXORA: LAST SIGNAL gameplay smoke test passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
