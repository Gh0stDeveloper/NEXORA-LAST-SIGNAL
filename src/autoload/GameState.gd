extends Node

signal session_started
signal session_finished(summary: Dictionary)

var in_session := false
var run_stats := {
    "kills": 0,
    "coins": 0,
    "xp": 0,
    "wave": 0,
    "shots": 0,
    "hits": 0,
}

func begin_session() -> void:
    in_session = true
    run_stats = {
        "kills": 0,
        "coins": 0,
        "xp": 0,
        "wave": 0,
        "shots": 0,
        "hits": 0,
    }
    session_started.emit()

func record_kill(coins: int, xp: int) -> void:
    run_stats.kills += 1
    run_stats.coins += coins
    run_stats.xp += xp
    SaveSystem.award(coins, xp)

func record_shot(hit := false) -> void:
    run_stats.shots += 1
    if hit:
        run_stats.hits += 1

func set_wave(wave: int) -> void:
    run_stats.wave = max(run_stats.wave, wave)

func finish_session() -> Dictionary:
    in_session = false
    SaveSystem.register_best_wave(int(run_stats.wave))
    SaveSystem.flush()
    var summary := run_stats.duplicate(true)
    session_finished.emit(summary)
    return summary
