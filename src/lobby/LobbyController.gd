class_name DeadfallLobbyController
extends Control

signal start_requested(config: Dictionary)

enum PartyMode { SOLO = 1, DUO = 2, SQUAD = 4 }

const UI = preload("res://src/ui/TacticalTheme.gd")
const Backdrop = preload("res://src/ui/TacticalBackdrop.gd")
const Stage = preload("res://src/lobby/TacticalStage.gd")
const SafeAreaScript = preload("res://src/mobile/SafeArea.gd")
const CharacterCatalog = preload("res://src/lobby/CharacterCatalog.gd")
const PartyAvatarScript = preload("res://src/lobby/LobbyPartyAvatar.gd")
const VisualPolishScript = preload("res://src/lobby/LobbyVisualPolish.gd")
const LoadingScript = preload("res://src/ui/MatchLoadingOverlay.gd")
const ArenaScene = preload("res://src/maps/campaign/OutbreakDistrict.tscn")

var selected_game_mode := "campaign"
var selected_mode: PartyMode = PartyMode.SOLO
var selected_difficulty := "normal"
var selected_mission: StringName = &"mission_01_first_signal"

var _safe_root: Control
var _username_label: Label
var _wallet_button: Button
var _status_label: Label
var _game_mode_button: Button
var _difficulty_button: Button
var _mode_buttons: Dictionary = {}
var _party_labels: Array[Label] = []
var _party_avatars: Array[Control] = []
var _party_slots: Array[Control] = []
var _party_title: Label
var _character_name: Label
var _character_role: Label
var _start_button: Button
var _selected_character: StringName = &"operator_01"
var _stage_view: Control
var _overlay: PanelContainer
var _stage_info: Control
var _briefing_tag: Label
var _briefing_title: Label
var _loading: CanvasLayer
var _arena: Node3D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.apply(self)
	_build_background()
	_safe_root = SafeAreaScript.new()
	_safe_root.name = "SafeArea"
	_safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_safe_root)
	_safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_selected_character = GuestIdentity.selected_character
	_build_top_bar()
	_build_stage()
	_build_navigation()
	_build_party_rail()
	_build_bottom_bar()
	_refresh_identity()
	_refresh_character()
	_refresh_mode()
	_refresh_wallet()

	GuestIdentity.username_changed.connect(_on_identity_username_changed)
	GuestIdentity.selected_character_changed.connect(_on_identity_character_changed)
	AudioDirector.set_context(&"lobby")

	var polish := VisualPolishScript.new()
	polish.name = "LobbyVisualPolish"
	add_child(polish)

func _build_background() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.010, 0.035, 0.046, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var backdrop := Backdrop.new()
	backdrop.name = "TacticalBackdrop"
	background.add_child(backdrop)
	var red := ColorRect.new()
	red.name = "RedAccent"
	red.anchor_left = 0.64
	red.anchor_top = 0.0
	red.anchor_right = 1.0
	red.anchor_bottom = 1.0
	red.color = Color(0.92, 0.055, 0.075, 0.14)
	red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(red)

func _build_top_bar() -> void:
	var card := PanelContainer.new()
	card.name = "IdentityCard"
	card.add_theme_stylebox_override("panel", UI.style(Color(0.012, 0.045, 0.056, 0.95), Color(UI.CYAN.r, UI.CYAN.g, UI.CYAN.b, 0.48), 14))
	UI.place(card, _safe_root, Rect2(0.03, 0.025, 0.30, 0.105))
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 0)
	card.add_child(card_box)
	card_box.add_child(UI.label("N E X O R A   /   L A S T   S I G N A L", 20, UI.AMBER))
	_username_label = UI.label("", 32)
	card_box.add_child(_username_label)

	_wallet_button = UI.button("NIVEL 1   ·   0 NXC", _open_progress, false)
	_wallet_button.icon = preload("res://assets/ui/icons/nexora_coin.svg")
	_wallet_button.expand_icon = true
	_wallet_button.add_theme_constant_override("icon_max_width", 32)
	_wallet_button.add_theme_font_size_override("font_size", 23)
	UI.place(_wallet_button, _safe_root, Rect2(0.34, 0.025, 0.32, 0.06))

	_status_label = UI.label("OFFLINE · AUTORIDAD LOCAL", 20, UI.CYAN)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UI.place(_status_label, _safe_root, Rect2(0.25, 0.095, 0.49, 0.04))

func _build_stage() -> void:
	var stage_panel := PanelContainer.new()
	stage_panel.name = "OperatorStage"
	stage_panel.add_theme_stylebox_override("panel", UI.style(Color(0.018, 0.028, 0.036, 0.72), Color(0.92, 0.055, 0.075, 0.42), 18))
	UI.place(stage_panel, _safe_root, Rect2(0.20, 0.14, 0.55, 0.65))
	_stage_view = Stage.new()
	_stage_view.name = "StageContent"
	stage_panel.add_child(_stage_view)

	var info := VBoxContainer.new()
	_stage_info = info
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 0)
	UI.place(info, _safe_root, Rect2(0.24, 0.70, 0.40, 0.10))
	_character_name = UI.label("", 46)
	info.add_child(_character_name)
	_character_role = UI.label("", 22, UI.AMBER)
	info.add_child(_character_role)

func _build_navigation() -> void:
	var briefing := PanelContainer.new()
	briefing.name = "Briefing"
	briefing.add_theme_stylebox_override("panel", UI.style())
	UI.place(briefing, _safe_root, Rect2(0.03, 0.18, 0.17, 0.19))
	var copy := UI.column(briefing, 2)
	_briefing_tag = UI.label("OFFLINE", 21, UI.CYAN)
	copy.add_child(_briefing_tag)
	_briefing_title = UI.label("PRIMERA\nSEÑAL", 36)
	copy.add_child(_briefing_title)
	copy.add_child(UI.label("Distrito del brote", 23, UI.MUTED))

	var nav_panel := PanelContainer.new()
	nav_panel.name = "Navigation"
	nav_panel.add_theme_stylebox_override("panel", UI.style())
	UI.place(nav_panel, _safe_root, Rect2(0.03, 0.42, 0.17, 0.34))
	var nav := VBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	nav_panel.add_child(nav)
	for item in [
		["OPERADORES", "operator", _open_character_panel],
		["ARSENAL", "rifle", _open_armory],
		["DIFICULTAD", "shield", _open_difficulty],
		["AJUSTES", "settings", _open_settings],
	]:
		var button := UI.button(item[0], item[2], false, item[1])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 52
		nav.add_child(button)

func _build_party_rail() -> void:
	var rail := PanelContainer.new()
	rail.name = "PartyRail"
	rail.add_theme_stylebox_override("panel", UI.style())
	UI.place(rail, _safe_root, Rect2(0.77, 0.18, 0.20, 0.59))
	var column := UI.column(rail, 10)
	_party_title = UI.label("TU EQUIPO", 30)
	column.add_child(_party_title)
	column.add_child(UI.label("SUPERVIVIENTES LOCALES", 18, UI.CYAN))
	for index in range(4):
		var slot := PanelContainer.new()
		slot.name = "PartySlot%d" % (index + 1)
		slot.custom_minimum_size.y = 104
		slot.add_theme_stylebox_override("panel", UI.style(Color(0.04, 0.10, 0.13, 0.86), Color(0.3, 0.6, 0.65, 0.22), 10))
		column.add_child(slot)
		_party_slots.append(slot)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		slot.add_child(row)
		var avatar := PartyAvatarScript.new()
		avatar.custom_minimum_size = Vector2(74, 74)
		row.add_child(avatar)
		_party_avatars.append(avatar)
		var label := UI.label("", 20)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(label)
		_party_labels.append(label)

func _build_bottom_bar() -> void:
	var bar := PanelContainer.new()
	bar.name = "MatchControls"
	bar.add_theme_stylebox_override("panel", UI.style())
	UI.place(bar, _safe_root, Rect2(0.23, 0.80, 0.74, 0.17))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	bar.add_child(row)
	var column := UI.column(row, 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selectors := HBoxContainer.new()
	selectors.add_theme_constant_override("separation", 8)
	column.add_child(selectors)
	_game_mode_button = UI.button("ZOMBIS · CAMPAÑA  ›", _open_mode_picker)
	_game_mode_button.custom_minimum_size.y = 46
	_game_mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_mode_button.add_theme_font_size_override("font_size", 22)
	selectors.add_child(_game_mode_button)
	_difficulty_button = UI.button("NORMAL", _open_difficulty)
	_difficulty_button.custom_minimum_size = Vector2(180, 46)
	_difficulty_button.add_theme_font_size_override("font_size", 20)
	selectors.add_child(_difficulty_button)

	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 10)
	column.add_child(modes)
	for mode in [1, 2, 4]:
		var title := "SOLO" if mode == 1 else ("DÚO IA" if mode == 2 else "ESCUADRA IA")
		var button := UI.button(title, _set_mode.bind(mode), false, "operator" if mode == 1 else "squad")
		button.custom_minimum_size.x = 145 if mode != 4 else 190
		button.toggle_mode = true
		modes.add_child(button)
		_mode_buttons[mode] = button

	_start_button = UI.button("INICIAR SOLO", _on_start_pressed, true, "play")
	_start_button.custom_minimum_size.x = 290
	_start_button.add_theme_font_size_override("font_size", 30)
	row.add_child(_start_button)

func _new_overlay(title: String) -> VBoxContainer:
	if is_instance_valid(_overlay):
		_overlay.free()
	set_stage_covered(true)
	_overlay = PanelContainer.new()
	_overlay.name = "TacticalOverlay"
	_overlay.add_theme_stylebox_override("panel", UI.style(Color(0.02, 0.04, 0.06, 0.99), UI.CYAN, 26))
	UI.place(_overlay, _safe_root, Rect2(0.20, 0.14, 0.77, 0.65))
	var box := UI.column(_overlay, 16)
	var header := HBoxContainer.new()
	box.add_child(header)
	var label := UI.label(title, 38)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	header.add_child(UI.button("VOLVER", _close_overlay, false, "back"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var content := UI.column(scroll, 16)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return content

func _open_character_panel() -> void:
	var content := _new_overlay("OPERADORES")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	content.add_child(grid)
	for character in CharacterCatalog.all():
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(450, 350)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UI.style())
		grid.add_child(card)
		var box := UI.column(card, 8)
		var preview := Stage.new()
		preview.custom_minimum_size = Vector2(300, 220)
		box.add_child(preview)
		preview.set_members([{"guest_id":"local","selected_character":character.id}], 1)
		box.add_child(UI.label(character.name, 30, character.accent))
		box.add_child(UI.label(character.role, 20, UI.MUTED))
		var desc := UI.label(character.description, 19)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(desc)
		var selected: bool = GuestIdentity.selected_character == character.id
		box.add_child(UI.button("EQUIPADO" if selected else "EQUIPAR", _select_character.bind(character.id), not selected, "operator"))

func _open_armory() -> void:
	var box := _new_overlay("ARSENAL")
	box.add_child(UI.label("Equipo de supervivencia almacenado localmente", 22, UI.MUTED))
	var preview := Stage.new()
	preview.custom_minimum_size.y = 270
	box.add_child(preview)
	preview.show_weapon(&"nxr_rifle_01")
	var name_label := UI.label("NXR-4  /  FUSIL DE ASALTO", 32, UI.AMBER)
	box.add_child(name_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	for item in [
		["nxr_rifle_01", "NXR-4", "FUSIL DE ASALTO"],
		["nxr_pistol_01", "NXR-9", "ARMA SECUNDARIA"],
		["machete", "MACHETE", "COMBATE CUERPO A CUERPO"],
	]:
		var button := UI.button(item[1], func() -> void:
			preview.show_weapon(StringName(item[0]))
			name_label.text = "%s  /  %s" % [item[1], item[2]]
		, false, "rifle")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
	box.add_child(UI.label("El inventario y el loot se procesan y guardan solo en este dispositivo.", 20, UI.MUTED))

func _open_difficulty() -> void:
	var box := _new_overlay("DIFICULTAD")
	box.add_child(UI.label("Ajusta salud, daño y presión de aparición de los infectados.", 22, UI.MUTED))
	var options := [
		["story", "HISTORIA", "Menor presión y daño. Prioriza campaña y exploración."],
		["normal", "NORMAL", "Balance base del combate DEADFALL."],
		["hard", "DIFÍCIL", "Más salud, daño y presión de horda."],
		["nightmare", "PESADILLA", "Máxima presión local y bosses más resistentes."],
	]
	for option in options:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UI.style())
		box.add_child(card)
		var row := HBoxContainer.new()
		card.add_child(row)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(copy)
		copy.add_child(UI.label(option[1], 28, UI.AMBER if option[0] == selected_difficulty else Color.WHITE))
		var desc := UI.label(option[2], 19, UI.MUTED)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(desc)
		row.add_child(UI.button("ACTIVO" if option[0] == selected_difficulty else "ELEGIR", _select_difficulty.bind(option[0]), option[0] == selected_difficulty, "shield"))

func _open_settings() -> void:
	var box := _new_overlay("AJUSTES")
	_add_slider(box, "Volumen general", Settings.master_volume, Settings.set_master_volume)
	_add_slider(box, "Música", Settings.music_volume, Settings.set_music_volume)
	for bus in ["SFX", "UI", "Ambience"]:
		var title: String = {"SFX":"Combate y enemigos","UI":"Interfaz","Ambience":"Ambiente"}[bus]
		_add_slider(box, title, Settings.get_audio_volume(bus), Settings.set_audio_volume.bind(bus))
	_add_slider(box, "Sensibilidad", Settings.camera_sensitivity, Settings.set_camera_sensitivity, 0.10)
	var row := HBoxContainer.new()
	box.add_child(row)
	var label := UI.label("Calidad gráfica", 26)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var quality := OptionButton.new()
	quality.custom_minimum_size = Vector2(320, 60)
	for value in ["Fluida", "Estándar", "Ultra", "Ultra HD"]:
		quality.add_item(value)
	quality.select(int(Settings.quality_tier))
	quality.item_selected.connect(Settings.set_quality_tier)
	row.add_child(quality)
	box.add_child(UI.label("Los cambios se guardan localmente. El HUD se personaliza durante la partida.", 20, UI.MUTED))

func _open_progress() -> void:
	var box := _new_overlay("PROGRESO LOCAL")
	var snapshot: Dictionary = Progress.snapshot()
	box.add_child(UI.label("NIVEL %d" % int(snapshot.get("level",1)), 36, UI.AMBER))
	box.add_child(UI.label("%d XP   ·   %d NXC" % [int(snapshot.get("xp",0)), int(snapshot.get("coins",0))], 28))
	box.add_child(UI.label("MEJOR OLEADA  %d" % int(snapshot.get("best_wave",0)), 24, UI.CYAN))
	box.add_child(UI.label("PARTIDAS  %d" % int(snapshot.get("runs",0)), 22, UI.MUTED))
	var missions: Array = snapshot.get("missions_completed",[])
	box.add_child(UI.label("MISIONES COMPLETADAS  %d" % missions.size(), 22, UI.MUTED))

func _open_mode_picker() -> void:
	var box := _new_overlay("ELIGE TU PARTIDA")
	_overlay.anchor_left = 0.03
	_overlay.anchor_top = 0.10
	_overlay.anchor_right = 0.97
	_overlay.anchor_bottom = 0.96
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	box.add_child(grid)
	for definition in preload("res://src/modes/ModeCatalog.gd").MODES:
		var card := PanelContainer.new()
		card.custom_minimum_size.x = 500
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", UI.style(Color(0.025,0.07,0.09,0.96), UI.AMBER if definition.id == selected_game_mode else UI.CYAN, 20))
		grid.add_child(card)
		var content := UI.column(card, 8)
		var image := TextureRect.new()
		image.texture = load(String(definition.image))
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.custom_minimum_size.y = 120
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(image)
		content.add_child(UI.label(String(definition.tag), 18, UI.CYAN))
		content.add_child(UI.label(String(definition.title), 26, UI.AMBER))
		var description := UI.label(String(definition.description), 20, UI.MUTED)
		description.custom_minimum_size = Vector2(420, 58)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(description)
		content.add_child(UI.button("SELECCIONADO" if definition.id == selected_game_mode else "SELECCIONAR", _select_game_mode.bind(String(definition.id)), definition.id == selected_game_mode))

	if selected_game_mode == "campaign":
		box.add_child(UI.label("MISIÓN", 26, UI.CYAN))
		var mission_row := HBoxContainer.new()
		mission_row.add_theme_constant_override("separation", 12)
		box.add_child(mission_row)
		for mission in [
			[&"mission_01_first_signal","MISIÓN 01 · PRIMERA SEÑAL"],
			[&"mission_02_last_broadcast","MISIÓN 02 · ÚLTIMA TRANSMISIÓN"],
		]:
			var selected := selected_mission == mission[0]
			var button := UI.button(mission[1], _select_mission.bind(mission[0]), selected)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mission_row.add_child(button)

func _add_slider(box: Control, title: String, value: float, callback: Callable, minimum: float = 0.0) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 54
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	var label := UI.label(title, 26)
	label.custom_minimum_size.x = 270
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var amount := UI.label("%d%%" % roundi(value * 100), 26, UI.AMBER)
	amount.custom_minimum_size.x = 72
	row.add_child(amount)
	slider.value_changed.connect(func(next: float) -> void:
		callback.call(next)
		amount.text = "%d%%" % roundi(next * 100)
	)

func _close_overlay() -> void:
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	set_stage_covered(false)

func set_stage_covered(covered: bool) -> void:
	if is_instance_valid(_stage_view):
		_stage_view.visible = not covered
	if is_instance_valid(_stage_info):
		_stage_info.visible = not covered

func _select_character(character_id: StringName) -> void:
	GuestIdentity.set_selected_character(character_id)
	_selected_character = character_id
	_close_overlay()
	_refresh_character()
	_refresh_mode()
	_status_label.text = "OPERADOR EQUIPADO · GUARDADO LOCALMENTE"

func _select_difficulty(value: String) -> void:
	selected_difficulty = value
	_close_overlay()
	_refresh_mode()
	_status_label.text = "DIFICULTAD %s" % value.to_upper()

func _select_mission(value: StringName) -> void:
	selected_mission = value
	_close_overlay()
	_refresh_mode()

func _select_game_mode(value: String) -> void:
	var definition := preload("res://src/modes/ModeCatalog.gd").find(value)
	if definition.is_empty():
		return
	selected_game_mode = value
	if selected_game_mode != "campaign":
		selected_mission = &"mission_01_first_signal"
	_close_overlay()
	_refresh_mode()

func _set_mode(mode: int) -> void:
	if mode not in [1,2,4]:
		return
	selected_mode = mode as PartyMode
	_refresh_mode()

func _refresh_mode() -> void:
	for key in _mode_buttons:
		var button: Button = _mode_buttons[key]
		button.set_pressed_no_signal(int(key) == int(selected_mode))
		UI.skin_button(button, button.button_pressed)

	var title := "SOLO" if selected_mode == PartyMode.SOLO else ("DÚO IA" if selected_mode == PartyMode.DUO else "ESCUADRA IA")
	_party_title.text = "TU EQUIPO  /  %s" % title
	_start_button.text = "INICIAR %s" % title
	_status_label.text = "PREPARADO · SIN CONEXIÓN REQUERIDA"
	_game_mode_button.text = "%s  ›" % preload("res://src/modes/ModeCatalog.gd").find(selected_game_mode).get("title","CAMPAÑA")
	_difficulty_button.text = selected_difficulty.to_upper()
	_briefing_tag.text = "OFFLINE"
	_briefing_title.text = {"campaign":"PRIMERA\nSEÑAL" if selected_mission == &"mission_01_first_signal" else "ÚLTIMA\nTRANSMISIÓN","waves":"ASALTO\n10 OLEADAS","endless":"RESISTENCIA\nINFINITA"}.get(selected_game_mode,"OPERACIÓN")
	_update_local_party()

func _update_local_party() -> void:
	var capacity := int(selected_mode)
	var roster := CharacterCatalog.all()
	var shown: Array = [{"guest_id":GuestIdentity.guest_id,"username":_display_username(),"selected_character":_selected_character,"leader":true}]
	var ai_index := 0
	while shown.size() < capacity:
		var candidate: Dictionary = roster[ai_index % roster.size()]
		ai_index += 1
		if StringName(candidate.id) == _selected_character:
			continue
		shown.append({"guest_id":"ai_%d" % shown.size(),"username":"%s · IA" % String(candidate.name),"selected_character":candidate.id,"leader":false})

	_stage_view.call("set_members", shown, capacity)
	for index in range(_party_slots.size()):
		var visible_slot := index < capacity
		_party_slots[index].visible = visible_slot
		if not visible_slot:
			continue
		if index < shown.size():
			var member: Dictionary = shown[index]
			_party_labels[index].text = "%s\n%s" % [String(member.username), "LÍDER" if bool(member.leader) else "COMPAÑERO IA"]
			_party_avatars[index].call("set_member", member, index)
		else:
			_party_labels[index].text = "PLAZA VACÍA"
			_party_avatars[index].call("set_empty", index)

	if capacity > 1:
		_character_name.text = "JUNTOS SOBREVIVIMOS"
		_character_name.add_theme_font_size_override("font_size", 34)
		_character_role.text = "%d / %d SUPERVIVIENTES · IA LOCAL" % [shown.size(), capacity]
	else:
		_character_name.add_theme_font_size_override("font_size", 46)
		_refresh_character()

func _refresh_identity() -> void:
	_username_label.text = "%s   /   LOCAL" % _display_username()

func _refresh_wallet() -> void:
	var value: Dictionary = Progress.snapshot()
	_wallet_button.text = "Nv.%d   ·   %d NXC" % [int(value.get("level",1)), int(value.get("coins",0))]

func _display_username() -> String:
	return GuestIdentity.username if not GuestIdentity.username.is_empty() else "SUPERVIVIENTE"

func _refresh_character() -> void:
	var character := CharacterCatalog.get_character(_selected_character)
	_character_name.text = character.name
	_character_role.text = "%s  /  ARRASTRA PARA GIRAR" % character.role

func _on_identity_username_changed(_username: String) -> void:
	_refresh_identity()

func _on_identity_character_changed(character_id: StringName) -> void:
	_selected_character = character_id
	_refresh_character()
	_refresh_mode()

func _on_start_pressed() -> void:
	if _arena != null:
		return
	_status_label.text = "PREPARANDO OPERACIÓN LOCAL"
	var config := {
		"mode":selected_game_mode,
		"difficulty":selected_difficulty,
		"companions":maxi(0,int(selected_mode)-1),
		"mission_id":selected_mission,
		"character_id":_selected_character,
	}
	start_requested.emit(config)
	_start_operation(config)

func _start_operation(config: Dictionary) -> void:
	_close_overlay()
	_loading = LoadingScript.new()
	_loading.name = "MatchLoadingOverlay"
	add_child(_loading)
	_loading.begin("")
	_loading.set_stage("Preparando ciudad y navegación local…",0.34)
	await get_tree().process_frame
	_loading.set_stage("Inicializando infectados, loot y compañeros IA…",0.66)
	Game.start_local_session()
	_arena = ArenaScene.instantiate() as Node3D
	if _arena == null:
		_loading.show_error("No se pudo crear la operación local.")
		return
	_arena.set("game_mode",String(config.get("mode","campaign")))
	_arena.set("mission_id",StringName(config.get("mission_id",&"mission_01_first_signal")))
	_arena.set("difficulty_id",String(config.get("difficulty","normal")))
	_arena.set("companion_count",int(config.get("companions",0)))
	_arena.set("character_id",StringName(config.get("character_id",&"operator_01")))
	_arena.connect("return_to_lobby",Callable(self,"_on_return_to_lobby"))
	add_child(_arena)
	_loading.complete()
	await get_tree().process_frame
	visible = false
	if is_instance_valid(_loading):
		_loading.queue_free()
		_loading = null

func _on_return_to_lobby(_summary: Dictionary = {}) -> void:
	if _arena != null and is_instance_valid(_arena):
		_arena.queue_free()
	_arena = null
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.set_context(&"lobby")
	_refresh_wallet()
	_refresh_mode()
