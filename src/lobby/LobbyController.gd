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
const ModeCatalog = preload("res://src/modes/ModeCatalog.gd")
const Cosmetics = preload("res://src/customization/CosmeticCatalog.gd")
const LOBBY_ART: Texture2D = preload("res://assets/ui/quarantine_hangar.webp")
const APP_VERSION := "1.0.0rc"

var selected_game_mode := "campaign"
var selected_mode: PartyMode = PartyMode.SOLO
var selected_difficulty := "normal"
var selected_mission: StringName = &"mission_01_first_signal"
var selected_primary: StringName = &"nxr_rifle_01"
var selected_secondary: StringName = &"nxr_pistol_01"

var _safe_root: Control
var _username_label: Label
var _profile_icon: TextureRect
var _wallet_button: Button
var _status_label: Label
var _game_mode_button: Button
var _difficulty_button: Button
var _mode_buttons: Dictionary = {}
var _operation_mode_buttons: Dictionary = {}
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
	selected_primary = GuestIdentity.selected_primary
	selected_secondary = GuestIdentity.selected_secondary
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
	if GuestIdentity.has_signal("gender_changed"):
		GuestIdentity.gender_changed.connect(_on_identity_gender_changed)
	if GuestIdentity.has_signal("appearance_changed"):
		GuestIdentity.appearance_changed.connect(_on_identity_appearance_changed)
	if GuestIdentity.has_signal("profile_icon_changed"):
		GuestIdentity.profile_icon_changed.connect(_on_identity_profile_icon_changed)
	if Progress.has_signal("progress_changed"):
		Progress.progress_changed.connect(_on_progress_changed)
	AudioDirector.set_context(&"lobby")

	var polish := VisualPolishScript.new()
	polish.name = "LobbyVisualPolish"
	add_child(polish)

func _build_background() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.006, 0.016, 0.024, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var hangar := TextureRect.new()
	hangar.name = "HangarBackdrop"
	hangar.texture = LOBBY_ART
	hangar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hangar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hangar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hangar.modulate = Color(0.50, 0.62, 0.68, 0.48)
	hangar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(hangar)

	var wash := ColorRect.new()
	wash.name = "LobbyWash"
	wash.color = Color(0.003, 0.014, 0.022, 0.56)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(wash)

	var backdrop := Backdrop.new()
	backdrop.name = "TacticalBackdrop"
	background.add_child(backdrop)

	var red := ColorRect.new()
	red.name = "RedAccent"
	red.anchor_left = 0.64
	red.anchor_top = 0.0
	red.anchor_right = 1.0
	red.anchor_bottom = 1.0
	red.color = Color(0.92, 0.055, 0.075, 0.18)
	red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(red)

	var lower_gradient := ColorRect.new()
	lower_gradient.name = "LowerShade"
	lower_gradient.anchor_top = 0.74
	lower_gradient.anchor_right = 1.0
	lower_gradient.anchor_bottom = 1.0
	lower_gradient.color = Color(0.0, 0.0, 0.0, 0.30)
	lower_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(lower_gradient)

func _build_top_bar() -> void:
	var card := PanelContainer.new()
	card.name = "IdentityCard"
	card.add_theme_stylebox_override("panel", UI.style(Color(0.012, 0.045, 0.056, 0.95), Color(UI.CYAN.r, UI.CYAN.g, UI.CYAN.b, 0.48), 14))
	UI.place(card, _safe_root, Rect2(0.03, 0.025, 0.30, 0.105))
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 12)
	card.add_child(identity_row)
	_profile_icon = TextureRect.new()
	_profile_icon.custom_minimum_size = Vector2(76,76)
	_profile_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_profile_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_profile_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_row.add_child(_profile_icon)
	var card_box := VBoxContainer.new()
	card_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_box.add_theme_constant_override("separation", 0)
	identity_row.add_child(card_box)
	card_box.add_child(UI.label("N E X O R A   /   L A S T   S I G N A L", 18, UI.AMBER))
	_username_label = UI.label("", 28)
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

	var version_label := UI.label("v%s  ·  ANDROID ARM64" % APP_VERSION, 16, UI.MUTED)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI.place(version_label, _safe_root, Rect2(0.76, 0.055, 0.20, 0.035))

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
		["PERFIL", "operator", _open_profile],
		["INVENTARIO", "squad", _open_inventory],
		["TIENDA", "play", _open_shop],
		["ARSENAL", "rifle", _open_armory],
		["MODOS", "play", _open_mode_picker],
		["DIFICULTAD", "shield", _open_difficulty],
		["AJUSTES", "settings", _open_settings],
	]:
		var button := UI.button(item[0], item[2], false, item[1])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 42
		button.add_theme_font_size_override("font_size", 18)
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
	bar.add_theme_stylebox_override("panel", UI.style(Color(0.012, 0.032, 0.044, 0.96), Color(UI.CYAN.r, UI.CYAN.g, UI.CYAN.b, 0.34), 18))
	UI.place(bar, _safe_root, Rect2(0.21, 0.785, 0.76, 0.195))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	bar.add_child(row)
	var column := UI.column(row, 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var operation_modes := HBoxContainer.new()
	operation_modes.name = "GameModeDock"
	operation_modes.add_theme_constant_override("separation", 8)
	column.add_child(operation_modes)
	for definition in ModeCatalog.MODES:
		var game_mode_id := String(definition.id)
		var title := "CAMPAÑA" if game_mode_id == "campaign" else ("ASALTO · 10" if game_mode_id == "waves" else "ENDLESS")
		var button := UI.button(title, _select_game_mode_quick.bind(game_mode_id), false, "play")
		button.name = "Mode%s" % game_mode_id.capitalize()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(175, 46)
		button.tooltip_text = String(definition.description)
		operation_modes.add_child(button)
		_operation_mode_buttons[game_mode_id] = button

	_game_mode_button = UI.button("MODO / MISIÓN  ›", _open_mode_picker, false, "play")
	_game_mode_button.custom_minimum_size = Vector2(190, 46)
	_game_mode_button.add_theme_font_size_override("font_size", 18)
	operation_modes.add_child(_game_mode_button)

	_difficulty_button = UI.button("NORMAL", _open_difficulty, false, "shield")
	_difficulty_button.custom_minimum_size = Vector2(155, 46)
	_difficulty_button.add_theme_font_size_override("font_size", 18)
	operation_modes.add_child(_difficulty_button)

	var squad_modes := HBoxContainer.new()
	squad_modes.name = "SquadModeDock"
	squad_modes.add_theme_constant_override("separation", 10)
	column.add_child(squad_modes)
	for mode in [1, 2, 4]:
		var party_title := "SOLO" if mode == 1 else ("DÚO IA" if mode == 2 else "ESCUADRA IA")
		var party_button := UI.button(party_title, _set_mode.bind(mode), false, "operator" if mode == 1 else "squad")
		party_button.custom_minimum_size.x = 145 if mode != 4 else 190
		party_button.toggle_mode = true
		squad_modes.add_child(party_button)
		_mode_buttons[mode] = party_button

	_start_button = UI.button("INICIAR SOLO", _on_start_pressed, true, "play")
	_start_button.custom_minimum_size.x = 300
	_start_button.add_theme_font_size_override("font_size", 28)
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

func _open_profile() -> void:
	var box := _new_overlay("PERFIL OFFLINE")
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	box.add_child(header)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(120,120)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(Cosmetics.profile_icon_asset(GuestIdentity.profile_icon)) as Texture2D
	header.add_child(icon)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identity)
	identity.add_child(UI.label(_display_username(), 34, UI.AMBER))
	identity.add_child(UI.label("PERFIL LOCAL · SIN CUENTA EN LÍNEA", 20, UI.CYAN))
	var progress: Dictionary = Progress.snapshot()
	identity.add_child(UI.label("NIVEL %d  ·  %d XP  ·  %d NXC" % [
		int(progress.get("level",1)),
		int(progress.get("xp",0)),
		int(progress.get("coins",0))
	], 22, UI.MUTED))

	var username_row := HBoxContainer.new()
	username_row.add_theme_constant_override("separation", 12)
	box.add_child(username_row)
	var username_edit := LineEdit.new()
	username_edit.text = GuestIdentity.username
	username_edit.placeholder_text = "Nombre del superviviente"
	username_edit.max_length = 16
	username_edit.custom_minimum_size = Vector2(440,58)
	username_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	username_row.add_child(username_edit)
	username_row.add_child(UI.button("GUARDAR NOMBRE", func() -> void:
		if GuestIdentity.set_username(username_edit.text):
			_refresh_identity()
			_close_overlay()
			_open_profile()
	, true, "operator"))

	box.add_child(UI.label("GÉNERO DEL PERSONAJE", 24, UI.CYAN))
	var gender_row := HBoxContainer.new()
	gender_row.add_theme_constant_override("separation", 12)
	box.add_child(gender_row)
	for option in [["female","FEMENINO"],["male","MASCULINO"]]:
		var active: bool = GuestIdentity.gender == String(option[0])
		var button := UI.button(String(option[1]), _set_profile_gender.bind(String(option[0])), active, "operator")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gender_row.add_child(button)

	var preview := Stage.new()
	preview.custom_minimum_size.y = 280
	box.add_child(preview)
	preview.set_members([{
		"guest_id":GuestIdentity.guest_id,
		"selected_character":_selected_character,
		"appearance":GuestIdentity.appearance_snapshot(),
	}],1)

	box.add_child(UI.label("ICONO DE PERFIL", 24, UI.CYAN))
	var icons := GridContainer.new()
	icons.columns = 3
	icons.add_theme_constant_override("h_separation", 10)
	icons.add_theme_constant_override("v_separation", 10)
	box.add_child(icons)
	for item in Cosmetics.items_for_gender(GuestIdentity.gender, "profile_icon"):
		var item_id := StringName(String(item.get("id","")))
		var owned := Progress.owns_cosmetic(item_id)
		var selected := item_id == GuestIdentity.profile_icon
		var caption := "EQUIPADO" if selected else (String(item.get("name","ICONO")) if owned else "%s · %d NXC" % [String(item.get("name","ICONO")), int(item.get("price",0))])
		var icon_button := UI.button(caption, _select_profile_icon.bind(item_id) if owned else _open_shop, selected, "operator")
		icon_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var asset := String(item.get("asset",""))
		if not asset.is_empty():
			icon_button.icon = load(asset) as Texture2D
			icon_button.expand_icon = true
			icon_button.add_theme_constant_override("icon_max_width", 48)
		icons.add_child(icon_button)

func _open_inventory() -> void:
	var box := _new_overlay("INVENTARIO · VESTUARIO")
	box.add_child(UI.label("Elige la apariencia del personaje. Las prendas se guardan por género y funcionan completamente offline.", 21, UI.MUTED))
	var preview := Stage.new()
	preview.custom_minimum_size.y = 260
	box.add_child(preview)
	preview.set_members([{
		"guest_id":GuestIdentity.guest_id,
		"selected_character":_selected_character,
		"appearance":GuestIdentity.appearance_snapshot(),
	}],1)
	var equipped := GuestIdentity.get_equipped_cosmetics()
	for category in Cosmetics.CATEGORIES:
		box.add_child(UI.label(Cosmetics.category_label(category), 24, UI.CYAN))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		box.add_child(grid)
		var any_owned := false
		for item in Cosmetics.items_for_gender(GuestIdentity.gender, category):
			var item_id := StringName(String(item.get("id","")))
			if not Progress.owns_cosmetic(item_id):
				continue
			any_owned = true
			var selected := String(equipped.get(category,"")) == String(item_id)
			var button := UI.button(
				"EQUIPADO · %s" % String(item.get("name","")) if selected else String(item.get("name","")),
				_equip_cosmetic.bind(category,item_id),
				selected,
				"operator"
			)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(button)
		if not any_owned:
			grid.add_child(UI.label("Sin objetos. Visita la tienda.", 19, UI.MUTED))

func _open_shop() -> void:
	var box := _new_overlay("TIENDA · NEXORA")
	var balance := Progress.get_coins()
	box.add_child(UI.label("%d NXC DISPONIBLES" % balance, 32, UI.AMBER))
	box.add_child(UI.label("Las compras son locales. Las monedas se ganan jugando partidas, oleadas y misiones.", 21, UI.MUTED))
	var available := 0
	for category in Cosmetics.CATEGORIES + ["profile_icon"]:
		var items := Cosmetics.items_for_gender(GuestIdentity.gender, category)
		var unowned: Array = []
		for item in items:
			if not Progress.owns_cosmetic(StringName(String(item.get("id","")))):
				unowned.append(item)
		if unowned.is_empty():
			continue
		available += unowned.size()
		box.add_child(UI.label(Cosmetics.category_label(category), 24, UI.CYAN))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		box.add_child(grid)
		for item in unowned:
			var item_id := StringName(String(item.get("id","")))
			var price := int(item.get("price",0))
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UI.style())
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(card)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			card.add_child(row)
			var copy := VBoxContainer.new()
			copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(copy)
			copy.add_child(UI.label(String(item.get("name","COSMÉTICO")), 22))
			copy.add_child(UI.label("%s · %s" % [Cosmetics.category_label(category), "UNISEX" if String(item.get("gender","any")) == "any" else ("MASCULINO" if String(item.get("gender","")) == "male" else "FEMENINO")], 17, UI.MUTED))
			var buy := UI.button("COMPRAR · %d NXC" % price, _buy_cosmetic.bind(item_id), balance >= price, "play")
			buy.disabled = balance < price
			row.add_child(buy)
	if available == 0:
		box.add_child(UI.label("TODO EL CATÁLOGO COMPATIBLE YA ESTÁ EN TU INVENTARIO.", 24, UI.CYAN))

func _set_profile_gender(value: String) -> void:
	GuestIdentity.set_gender(value)
	_close_overlay()
	_open_profile()

func _select_profile_icon(item_id: StringName) -> void:
	if not Progress.owns_cosmetic(item_id):
		return
	if GuestIdentity.set_profile_icon(item_id):
		_refresh_identity()
		_close_overlay()
		_open_profile()

func _equip_cosmetic(category: String, item_id: StringName) -> void:
	if not Progress.owns_cosmetic(item_id):
		return
	if GuestIdentity.equip_cosmetic(category,item_id):
		_refresh_mode()
		_close_overlay()
		_open_inventory()

func _buy_cosmetic(item_id: StringName) -> void:
	var result: Dictionary = Progress.purchase_cosmetic(item_id)
	if bool(result.get("ok",false)):
		_refresh_wallet()
		AudioDirector.play_ui(&"ui_confirm")
		_close_overlay()
		_open_shop()
	else:
		AudioDirector.play_ui(&"ui_error")
		_status_label.text = "NXC INSUFICIENTES PARA ESA COMPRA"

func _open_armory() -> void:
	var box := _new_overlay("ARSENAL")
	box.add_child(UI.label("Configura el armamento inicial. El loadout queda guardado en este dispositivo.", 22, UI.MUTED))

	var preview := Stage.new()
	preview.custom_minimum_size.y = 250
	box.add_child(preview)
	preview.show_weapon(selected_primary)

	var name_label := UI.label("", 30, UI.AMBER)
	box.add_child(name_label)

	var WeaponCatalog := preload("res://src/weapons/WeaponCatalog.gd")
	var primary_label := UI.label("ARMA PRINCIPAL", 22, UI.CYAN)
	box.add_child(primary_label)
	var primary_row := HBoxContainer.new()
	primary_row.add_theme_constant_override("separation", 10)
	box.add_child(primary_row)
	for definition in WeaponCatalog.all_for_slot("primary"):
		var id := StringName(definition.id)
		var button := UI.button(String(definition.name), func() -> void:
			selected_primary = id
			GuestIdentity.set_loadout(selected_primary, selected_secondary)
			preview.show_weapon(id)
			name_label.text = "%s  /  %s" % [String(definition.name), String(definition.role)]
		, id == selected_primary, "rifle")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		primary_row.add_child(button)

	var secondary_label := UI.label("ARMA SECUNDARIA", 22, UI.CYAN)
	box.add_child(secondary_label)
	var secondary_row := HBoxContainer.new()
	secondary_row.add_theme_constant_override("separation", 10)
	box.add_child(secondary_row)
	for definition in WeaponCatalog.all_for_slot("secondary"):
		var id := StringName(definition.id)
		var button := UI.button(String(definition.name), func() -> void:
			selected_secondary = id
			GuestIdentity.set_loadout(selected_primary, selected_secondary)
			preview.show_weapon(id)
			name_label.text = "%s  /  %s" % [String(definition.name), String(definition.role)]
		, id == selected_secondary, "rifle")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		secondary_row.add_child(button)

	var melee := UI.button("MACHETE", func() -> void:
		preview.show_weapon(&"machete")
		name_label.text = "MACHETE  /  COMBATE CUERPO A CUERPO"
	, false, "rifle")
	box.add_child(melee)
	var current := WeaponCatalog.get_definition(selected_primary)
	name_label.text = "%s  /  %s" % [String(current.name), String(current.role)]
	box.add_child(UI.label("Principal: %s   ·   Secundaria: %s   ·   Machete siempre disponible." % [
		String(WeaponCatalog.get_definition(selected_primary).name),
		String(WeaponCatalog.get_definition(selected_secondary).name)
	], 20, UI.MUTED))

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
			[&"mission_03_blackout","MISIÓN 03 · BLACKOUT"],
			[&"mission_04_final_signal","MISIÓN 04 · SEÑAL FINAL"],
		]:
			var selected: bool = selected_mission == StringName(mission[0])
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
	var definition := ModeCatalog.find(value)
	if definition.is_empty():
		return
	selected_game_mode = value
	if selected_game_mode != "campaign":
		selected_mission = &"mission_01_first_signal"
	_close_overlay()
	_refresh_mode()

func _select_game_mode_quick(value: String) -> void:
	var definition := ModeCatalog.find(value)
	if definition.is_empty():
		return
	selected_game_mode = value
	if selected_game_mode != "campaign":
		selected_mission = &"mission_01_first_signal"
	_refresh_mode()
	_status_label.text = "%s · %s" % [String(definition.title), selected_difficulty.to_upper()]

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

	for game_mode_key in _operation_mode_buttons:
		var operation_button: Button = _operation_mode_buttons[game_mode_key]
		operation_button.set_pressed_no_signal(String(game_mode_key) == selected_game_mode)
		UI.skin_button(operation_button, operation_button.button_pressed)

	var title := "SOLO" if selected_mode == PartyMode.SOLO else ("DÚO IA" if selected_mode == PartyMode.DUO else "ESCUADRA IA")
	_party_title.text = "TU EQUIPO  /  %s" % title
	_start_button.text = "INICIAR %s" % title
	_status_label.text = "PREPARADO · SIN CONEXIÓN REQUERIDA"
	_game_mode_button.text = "MODO / MISIÓN  ›"
	_difficulty_button.text = selected_difficulty.to_upper()
	_briefing_tag.text = "OFFLINE"
	var campaign_title: String = String({
		&"mission_01_first_signal":"PRIMERA\nSEÑAL",
		&"mission_02_last_broadcast":"ÚLTIMA\nTRANSMISIÓN",
		&"mission_03_blackout":"BLACKOUT",
		&"mission_04_final_signal":"SEÑAL\nFINAL",
	}.get(selected_mission,"CAMPAÑA"))
	_briefing_title.text = campaign_title if selected_game_mode == "campaign" else {"waves":"ASALTO\n10 OLEADAS","endless":"RESISTENCIA\nINFINITA"}.get(selected_game_mode,"OPERACIÓN")
	_update_local_party()

func _update_local_party() -> void:
	var capacity := int(selected_mode)
	var roster := CharacterCatalog.all()
	var shown: Array = [{
		"guest_id":GuestIdentity.guest_id,
		"username":_display_username(),
		"selected_character":_selected_character,
		"appearance":GuestIdentity.appearance_snapshot(),
		"profile_icon":String(GuestIdentity.profile_icon),
		"leader":true,
	}]
	var ai_index := 0
	while shown.size() < capacity:
		var candidate: Dictionary = roster[ai_index % roster.size()]
		ai_index += 1
		if StringName(candidate.id) == _selected_character:
			continue
		var ai_slot := shown.size()
		shown.append({
			"guest_id":"ai_%d" % ai_slot,
			"username":"%s · IA" % String(candidate.name),
			"selected_character":candidate.id,
			"appearance":Cosmetics.ai_appearance(ai_slot),
			"leader":false,
		})

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
	if _profile_icon != null:
		var icon_path := Cosmetics.profile_icon_asset(GuestIdentity.profile_icon)
		_profile_icon.texture = load(icon_path) as Texture2D

func _refresh_wallet() -> void:
	var value: Dictionary = Progress.snapshot()
	_wallet_button.text = "Nv.%d   ·   %d NXC" % [int(value.get("level",1)), int(value.get("coins",0))]

func _display_username() -> String:
	return GuestIdentity.username if not GuestIdentity.username.is_empty() else "SUPERVIVIENTE"

func _refresh_character() -> void:
	_character_name.text = "OPERADOR UNIVERSAL"
	var gender_label := "MASCULINO" if GuestIdentity.gender == "male" else "FEMENINO"
	_character_role.text = "%s  /  ARRASTRA PARA GIRAR" % gender_label

func _on_identity_username_changed(_username: String) -> void:
	_refresh_identity()

func _on_identity_character_changed(character_id: StringName) -> void:
	_selected_character = character_id
	_refresh_character()
	_refresh_mode()

func _on_identity_gender_changed(_gender: String) -> void:
	_refresh_identity()
	_refresh_character()
	_refresh_mode()

func _on_identity_appearance_changed(_appearance: Dictionary) -> void:
	_refresh_identity()
	_refresh_character()
	_refresh_mode()

func _on_identity_profile_icon_changed(_icon_id: StringName) -> void:
	_refresh_identity()

func _on_progress_changed(_snapshot: Dictionary) -> void:
	_refresh_wallet()

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
		"primary_weapon_id":selected_primary,
		"secondary_weapon_id":selected_secondary,
		"appearance":GuestIdentity.appearance_snapshot(),
	}
	start_requested.emit(config)
	_start_operation(config)

func _start_operation(config: Dictionary) -> void:
	_close_overlay()
	_start_button.disabled = true
	_loading = LoadingScript.new()
	_loading.name = "MatchLoadingOverlay"
	add_child(_loading)
	_loading.begin(config)
	await get_tree().process_frame

	_loading.set_stage("Preparando ciudad, iluminación y navegación local…", 0.26)
	await get_tree().create_timer(0.28).timeout

	Game.start_local_session()
	_loading.set_stage("Inicializando infectados, loot y compañeros IA…", 0.52)
	_arena = ArenaScene.instantiate() as Node3D
	if _arena == null:
		_loading.show_error("No se pudo crear la operación local.")
		_start_button.disabled = false
		return

	_arena.process_mode = Node.PROCESS_MODE_DISABLED
	_arena.set("game_mode",String(config.get("mode","campaign")))
	_arena.set("mission_id",StringName(config.get("mission_id",&"mission_01_first_signal")))
	_arena.set("difficulty_id",String(config.get("difficulty","normal")))
	_arena.set("companion_count",int(config.get("companions",0)))
	_arena.set("character_id",StringName(config.get("character_id",&"operator_01")))
	_arena.set("primary_weapon_id",StringName(config.get("primary_weapon_id",&"nxr_rifle_01")))
	_arena.set("secondary_weapon_id",StringName(config.get("secondary_weapon_id",&"nxr_pistol_01")))
	_arena.set("appearance",Dictionary(config.get("appearance",{})))
	_arena.connect("return_to_lobby",Callable(self,"_on_return_to_lobby"))
	add_child(_arena)

	await get_tree().process_frame
	_loading.set_stage("Sincronizando HUD, armamento y estado de misión…", 0.78)
	await get_tree().create_timer(0.42).timeout
	_loading.set_stage("Zona lista. Confirmando inserción táctica…", 0.94)
	await get_tree().create_timer(0.38).timeout
	_loading.complete()
	await get_tree().create_timer(0.32).timeout

	visible = false
	_arena.process_mode = Node.PROCESS_MODE_INHERIT
	_start_button.disabled = false
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
