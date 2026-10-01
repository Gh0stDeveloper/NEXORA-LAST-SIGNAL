extends Node

signal wave_changed(wave: int, alive: int, remaining: int)
signal score_changed(kills: int, run_coins: int, run_xp: int)

const ZombieScript = preload("res://src/enemies/Zombie.gd")
const KINDS := ["walker", "walker", "walker", "runner", "crawler", "screamer", "tank"]

var world: Node3D
var player: CharacterBody3D
var wave := 0
var remaining_to_spawn := 0
var alive := 0
var spawn_timer := 0.0
var intermission := 1.0
var active := true

func setup(game_world: Node3D, local_player: CharacterBody3D) -> void:
    world = game_world
    player = local_player

func _process(delta: float) -> void:
    if not active or world == null or player == null:
        return
    if wave == 0:
        intermission -= delta
        if intermission <= 0.0:
            _start_next_wave()
        return

    if remaining_to_spawn > 0:
        spawn_timer -= delta
        if spawn_timer <= 0.0:
            spawn_timer = maxf(0.22, 0.85 - wave * 0.025)
            if alive < mini(18, 6 + wave):
                _spawn_one()
                remaining_to_spawn -= 1
                wave_changed.emit(wave, alive, remaining_to_spawn)
    elif alive <= 0:
        intermission -= delta
        if intermission <= 0.0:
            _start_next_wave()

func _start_next_wave() -> void:
    wave += 1
    GameState.set_wave(wave)
    remaining_to_spawn = 4 + wave * 2
    alive = 0
    intermission = 3.0
    spawn_timer = 0.15
    wave_changed.emit(wave, alive, remaining_to_spawn)

func _spawn_one() -> void:
    if not is_instance_valid(player):
        return
    var zombie := ZombieScript.new()
    var kind := _pick_kind()
    zombie.configure(kind, player)
    var angle := randf_range(0.0, TAU)
    var radius := randf_range(13.0, 24.0)
    zombie.position = player.position + Vector3(cos(angle) * radius, 0.2, sin(angle) * radius)
    zombie.killed.connect(_on_zombie_killed)
    world.add_child(zombie)
    alive += 1

func _pick_kind() -> String:
    if wave <= 2:
        return "walker" if randf() < 0.75 else "runner"
    if wave <= 5:
        var early := ["walker", "walker", "runner", "crawler", "screamer"]
        return early[randi() % early.size()]
    return KINDS[randi() % KINDS.size()]

func _on_zombie_killed(_zombie: CharacterBody3D, coins: int, xp: int) -> void:
    alive = maxi(alive - 1, 0)
    GameState.record_kill(coins, xp)
    score_changed.emit(int(GameState.run_stats.kills), int(GameState.run_stats.coins), int(GameState.run_stats.xp))
    wave_changed.emit(wave, alive, remaining_to_spawn)
    if remaining_to_spawn <= 0 and alive <= 0:
        intermission = 3.0
