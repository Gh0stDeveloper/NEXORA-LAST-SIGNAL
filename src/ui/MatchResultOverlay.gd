class_name DeadfallMatchResultOverlay
extends CanvasLayer

signal return_requested()
signal play_again_requested()
const UI = preload("res://src/ui/TacticalTheme.gd")
const AUTO_RETURN_SECONDS := 12.0
var _title: Label
var _summary: Label
var _reward: Label
var _countdown: Label
var _return_button: Button
var _participants: HBoxContainer
var _timer: Timer
var _remaining := AUTO_RETURN_SECONDS
var _result: Dictionary = {}
var _settled := false

func _ready() -> void:
	layer = 95
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	UI.apply(root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.045, 0.92)
	UI.place(shade, root, Rect2(0, 0, 1, 1))
	var safe := preload("res://src/mobile/SafeArea.gd").new()
	root.add_child(safe)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.style(Color(0.025, 0.055, 0.085, 0.98), UI.CYAN, 24))
	UI.place(panel, safe, Rect2(0.16, 0.12, 0.68, 0.76))
	var box := UI.column(panel, 16)
	box.add_child(UI.label("NEXORA / INFORME DE MISIÓN", 23, UI.CYAN))
	_title = UI.label("PARTIDA FINALIZADA", 44, UI.AMBER)
	box.add_child(_title)
	_summary = UI.label("", 27)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_summary)
	box.add_child(HSeparator.new())
	_reward = UI.label("Guardando recompensas…", 28, UI.AMBER)
	_reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_reward)
	_participants = HBoxContainer.new()
	box.add_child(_participants)
	_countdown = UI.label("", 21, UI.MUTED)
	box.add_child(_countdown)
	var actions := HBoxContainer.new()
	box.add_child(actions)
	_return_button = UI.button("VOLVER AL LOBBY", _request_return)
	actions.add_child(_return_button)
	actions.add_child(UI.button("JUGAR OTRA VEZ", func() -> void:
		_timer.stop()
		play_again_requested.emit()
	, true))
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	SocialClient.result_loaded.connect(_on_settled_result)

func present(result: Dictionary) -> void:
	_result = result.duplicate(true)
	_remaining = AUTO_RETURN_SECONDS
	var outcome := String(result.get("outcome", "ABORTED"))
	_title.text = String({"VICTORY": "VICTORIA", "DEFEAT": "DERROTA", "DRAW": "EMPATE"}.get(outcome, "PARTIDA FINALIZADA"))
	var personal := Dictionary(result.get("personal_stats", {}))
	var seconds := int(result.get("uptime_seconds", 0))
	_summary.text = "TUS BAJAS  %d    DAÑO  %d    TIEMPO  %02d:%02d\nOLEADA  %d    PUNTOS DEL EQUIPO  %d" % [int(personal.get("kills", result.get("kills", 0))), int(personal.get("damage", 0)), seconds / 60, seconds % 60, int(result.get("wave", 0)), int(result.get("score", 0))]
	for member in Array(result.get("participants", [])):
		var id := String(member.get("public_id", ""))
		if id.is_empty(): continue
		_participants.add_child(UI.button(String(member.get("username", "Jugador")), _open_profile.bind(id)))
	if bool(result.get("local_only", false)):
		_reward.text = "Práctica local · sin recompensas de cuenta"
		_settled = true
	elif SocialClient.has_session():
		SocialClient.load_match_result(String(result.get("match_id", "")))
	_update_countdown()
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_timer.start()

func _on_settled_result(response: Dictionary) -> void:
	var entry := Dictionary(response.get("result", {}))
	if entry.is_empty() or String(entry.get("match_id", "")) != String(_result.get("match_id", "")): return
	_settled = true
	var rewards := Dictionary(entry.get("rewards", {}))
	_reward.text = "+%d XP    +%d NEXORA COINS" % [int(rewards.get("xp", 0)), int(rewards.get("coins", 0))]
	if int(rewards.get("level_after", 1)) > int(rewards.get("level_before", 1)):
		_reward.text += "\nNIVEL %d ALCANZADO" % int(rewards.level_after)
	var unlocks := Array(rewards.get("unlocked", []))
	if not unlocks.is_empty(): _reward.text += "\nDESBLOQUEADO · " + ", ".join(unlocks)
	if not Array(rewards.get("missions_completed", [])).is_empty(): _reward.text += "\nBonificación de misiones incluida"

func _on_tick() -> void:
	_remaining = maxf(0.0, _remaining - 1.0)
	if not _settled and SocialClient.has_session(): SocialClient.load_match_result(String(_result.get("match_id", "")))
	_update_countdown()
	if _remaining <= 0.0: _request_return()

func _update_countdown() -> void:
	_countdown.text = "Regreso al lobby en %d s · Consulta después el historial" % ceili(_remaining)

func _request_return() -> void:
	_timer.stop()
	return_requested.emit()

func _open_profile(id: String) -> void:
	_timer.stop()
	var hub := preload("res://src/lobby/SocialHub.gd").new()
	hub.target_id = id
	add_child(hub)
	hub.closed.connect(func() -> void: _timer.start())
