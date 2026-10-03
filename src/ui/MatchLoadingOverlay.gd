class_name DeadfallMatchLoadingOverlay
extends CanvasLayer

signal return_requested()

const UI = preload("res://src/ui/TacticalTheme.gd")
const LOADING_ART: Texture2D = preload("res://assets/ui/quarantine_hangar.webp")
const ModeCatalog = preload("res://src/modes/ModeCatalog.gd")
const APP_VERSION := "1.0.0rc"

var _status_label: Label
var _detail_label: Label
var _progress: ProgressBar
var _return_button: Button
var _mode_title: Label
var _mission_label: Label
var _difficulty_label: Label
var _squad_label: Label
var _progress_value := 0.0
var _target_progress := 0.0

func _ready() -> void:
	layer = 90
	_build_ui()
	set_process(true)

func _process(delta: float) -> void:
	_progress_value = move_toward(_progress_value, _target_progress, maxf(0.0, delta) * 0.82)
	if _progress != null:
		_progress.value = _progress_value * 100.0

func begin(context: Variant = {}) -> void:
	_progress_value = 0.04
	_target_progress = 0.16
	if _progress != null:
		_progress.value = _progress_value * 100.0
	if _status_label != null:
		_status_label.text = "DESPLEGANDO OPERACIÓN…"
	if _detail_label != null:
		_detail_label.text = "Reuniendo al equipo y preparando la simulación local…"
	if _return_button != null:
		_return_button.visible = false
	_apply_context(context)

func set_stage(text: String, progress_ratio: float) -> void:
	_target_progress = clampf(progress_ratio, _target_progress, 0.98)
	if _status_label != null:
		_status_label.text = "CARGANDO…"
	if _detail_label != null:
		_detail_label.text = text

func complete() -> void:
	_target_progress = 1.0
	_progress_value = 1.0
	if _progress != null:
		_progress.value = 100.0
	if _status_label != null:
		_status_label.text = "OPERACIÓN LISTA"
	if _detail_label != null:
		_detail_label.text = "Entrando a la zona de supervivencia…"

func show_error(message: String) -> void:
	_target_progress = maxf(_target_progress, 0.18)
	if _status_label != null:
		_status_label.text = "NO SE PUDO CARGAR"
	if _detail_label != null:
		_detail_label.text = message
	if _return_button != null:
		_return_button.visible = true

func _apply_context(context: Variant) -> void:
	if not context is Dictionary:
		return
	var config: Dictionary = context
	var mode_id := String(config.get("mode", "campaign"))
	var definition := ModeCatalog.find(mode_id)
	if _mode_title != null:
		_mode_title.text = String(definition.get("title", "OPERACIÓN OFFLINE"))
	if _difficulty_label != null:
		_difficulty_label.text = "DIFICULTAD  %s" % String(config.get("difficulty", "normal")).to_upper()
	if _squad_label != null:
		var companions := int(config.get("companions", 0))
		_squad_label.text = "FORMACIÓN  %s" % ("SOLO" if companions <= 0 else ("%d COMPAÑERO%s IA" % [companions, "" if companions == 1 else "S"]))
	if _mission_label != null:
		if mode_id == "campaign":
			_mission_label.text = "MISIÓN  %s" % _mission_name(StringName(config.get("mission_id", &"mission_01_first_signal")))
		else:
			_mission_label.text = "OBJETIVO  %s" % String(definition.get("tag", "OFFLINE"))

func _mission_name(id: StringName) -> String:
	match id:
		&"mission_02_last_broadcast":
			return "02 · ÚLTIMA TRANSMISIÓN"
		&"mission_03_blackout":
			return "03 · BLACKOUT"
		&"mission_04_final_signal":
			return "04 · SEÑAL FINAL"
		_:
			return "01 · PRIMERA SEÑAL"

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.apply(root)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var background := TextureRect.new()
	background.texture = LOADING_ART
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(background)

	var darken := ColorRect.new()
	darken.color = Color(0.0, 0.0, 0.0, 0.28)
	darken.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	darken.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(darken)

	var top_fade := ColorRect.new()
	top_fade.color = Color(0.0, 0.0, 0.0, 0.28)
	top_fade.anchor_right = 1.0
	top_fade.anchor_bottom = 0.24
	top_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_fade)

	var brand := UI.label("N E X O R A   /   L A S T   S I G N A L", 24, UI.AMBER)
	brand.anchor_left = 0.055
	brand.anchor_top = 0.055
	brand.anchor_right = 0.70
	brand.anchor_bottom = 0.11
	root.add_child(brand)

	var offline := UI.label("OFFLINE // v%s // SIMULACIÓN LOCAL" % APP_VERSION, 16, UI.CYAN)
	offline.anchor_left = 0.62
	offline.anchor_top = 0.06
	offline.anchor_right = 0.945
	offline.anchor_bottom = 0.10
	offline.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(offline)

	var briefing := PanelContainer.new()
	briefing.anchor_left = 0.055
	briefing.anchor_top = 0.22
	briefing.anchor_right = 0.46
	briefing.anchor_bottom = 0.55
	briefing.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.020, 0.030, 0.84), Color(0.18, 0.62, 0.68, 0.52), 18))
	root.add_child(briefing)
	var briefing_margin := MarginContainer.new()
	briefing_margin.add_theme_constant_override("margin_left", 22)
	briefing_margin.add_theme_constant_override("margin_right", 22)
	briefing_margin.add_theme_constant_override("margin_top", 18)
	briefing_margin.add_theme_constant_override("margin_bottom", 18)
	briefing.add_child(briefing_margin)
	var briefing_box := VBoxContainer.new()
	briefing_box.add_theme_constant_override("separation", 9)
	briefing_margin.add_child(briefing_box)
	briefing_box.add_child(UI.label("BRIEFING LOCAL", 18, UI.CYAN))
	_mode_title = UI.label("ZOMBIS · CAMPAÑA", 34, UI.AMBER)
	_mode_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing_box.add_child(_mode_title)
	_mission_label = UI.label("MISIÓN  01 · PRIMERA SEÑAL", 20)
	briefing_box.add_child(_mission_label)
	_difficulty_label = UI.label("DIFICULTAD  NORMAL", 18, UI.MUTED)
	briefing_box.add_child(_difficulty_label)
	_squad_label = UI.label("FORMACIÓN  SOLO", 18, UI.MUTED)
	briefing_box.add_child(_squad_label)
	var guarantee := UI.label("SIN SERVIDORES · SIN MATCHMAKING · SIN INTERNET", 15, UI.CYAN)
	guarantee.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing_box.add_child(guarantee)

	var bottom := PanelContainer.new()
	bottom.anchor_left = 0.055
	bottom.anchor_top = 0.72
	bottom.anchor_right = 0.945
	bottom.anchor_bottom = 0.95
	bottom.add_theme_stylebox_override("panel", _panel_style(Color(0.010, 0.017, 0.024, 0.94), Color(0.18, 0.62, 0.68, 0.56), 18))
	root.add_child(bottom)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	bottom.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	_status_label = Label.new()
	_status_label.text = "DESPLEGANDO OPERACIÓN…"
	_status_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_status_label)
	_detail_label = Label.new()
	_detail_label.text = "Preparando ciudad, IA y campaña local…"
	_detail_label.add_theme_color_override("font_color", Color(0.72, 0.80, 0.84))
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_detail_label)
	_progress = ProgressBar.new()
	_progress.min_value = 0.0
	_progress.max_value = 100.0
	_progress.value = 0.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 18)
	_progress.add_theme_stylebox_override("background", _panel_style(Color(0.02, 0.04, 0.05, 0.96), Color(0.16, 0.30, 0.32, 0.65), 9))
	_progress.add_theme_stylebox_override("fill", _panel_style(UI.AMBER, Color(1.0, 0.33, 0.18, 0.95), 9))
	vbox.add_child(_progress)

	var hint := UI.label("Los recursos se cargan desde el APK. La partida no espera ninguna respuesta de red.", 15, UI.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

	_return_button = Button.new()
	_return_button.text = "VOLVER AL LOBBY"
	_return_button.visible = false
	_return_button.custom_minimum_size = Vector2(210, 48)
	_return_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_return_button.add_theme_stylebox_override("normal", _panel_style(Color(0.12, 0.035, 0.045, 0.98), Color(0.78, 0.10, 0.12, 0.86), 12))
	_return_button.add_theme_stylebox_override("hover", _panel_style(Color(0.22, 0.045, 0.055, 1.0), Color(1.0, 0.22, 0.18, 1.0), 12))
	_return_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.07, 0.025, 0.032, 1.0), Color(1.0, 0.30, 0.22, 1.0), 12))
	_return_button.pressed.connect(func() -> void: return_requested.emit())
	vbox.add_child(_return_button)

func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
