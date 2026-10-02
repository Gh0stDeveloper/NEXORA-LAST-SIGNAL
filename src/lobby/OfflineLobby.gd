class_name LastSignalOfflineLobby
extends Control

signal start_requested(config: Dictionary)

const UI=preload("res://src/ui/TacticalTheme.gd")
const Characters=preload("res://src/lobby/CharacterCatalog.gd")
const Modes=preload("res://src/modes/ModeCatalog.gd")
const ProceduralCharacters=preload("res://src/assets/ProceduralCharacterModel.gd")

var selected_mode:="campaign"
var selected_difficulty:="normal"
var companion_count:=2
var selected_mission: StringName=&"mission_01_first_signal"

var _mode_title:Label
var _mode_description:Label
var _mode_art:TextureRect
var _operator_name:Label
var _operator_role:Label
var _preview_turntable:Node3D
var _preview_model:Node3D
var _profile_label:Label
var _mission_selector:OptionButton

func _ready()->void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.apply(self)
	AudioDirector.set_context(&"lobby")
	_build_background()
	_build_header()
	_build_profile()
	_build_operator_stage()
	_build_modes()
	_build_launch_panel()
	_refresh_profile()
	_select_operator(GuestIdentity.selected_character)
	_select_mode("campaign")

func _build_background()->void:
	var image:=TextureRect.new()
	image.name="BackgroundArt"
	image.texture=preload("res://assets/ui/quarantine_hangar.webp")
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(image)
	var wash:=ColorRect.new()
	wash.color=Color(0.005,0.018,0.025,0.42)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	var top:=ColorRect.new()
	top.color=Color(0.01,0.04,0.05,0.88)
	top.anchor_right=1.0;top.anchor_bottom=0.12
	top.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(top)

func _build_header()->void:
	var title:=UI.label("NEXORA: LAST SIGNAL",42)
	title.anchor_left=0.035;title.anchor_top=0.026;title.anchor_right=0.55;title.anchor_bottom=0.09
	add_child(title)
	var status:=UI.label("OFFLINE // AUTORIDAD LOCAL // SIN INTERNET",16,UI.CYAN)
	status.anchor_left=0.62;status.anchor_top=0.038;status.anchor_right=0.965;status.anchor_bottom=0.075
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	add_child(status)

func _build_profile()->void:
	var panel:=PanelContainer.new()
	panel.anchor_left=0.035;panel.anchor_top=0.14;panel.anchor_right=0.275;panel.anchor_bottom=0.30
	panel.add_theme_stylebox_override("panel",UI.style(Color(0.012,0.04,0.052,0.94),Color(UI.CYAN.r,UI.CYAN.g,UI.CYAN.b,0.52),18))
	add_child(panel)
	var box:=VBoxContainer.new()
	box.add_theme_constant_override("separation",7)
	panel.add_child(box)
	var name:=UI.label(GuestIdentity.username,28)
	name.add_theme_color_override("font_color",UI.AMBER)
	box.add_child(name)
	_profile_label=UI.label("",18,UI.MUTED)
	box.add_child(_profile_label)
	var local:=UI.label("PERFIL GUARDADO EN ESTE DISPOSITIVO",13,UI.CYAN)
	box.add_child(local)

func _build_operator_stage()->void:
	var panel:=PanelContainer.new()
	panel.anchor_left=0.29;panel.anchor_top=0.14;panel.anchor_right=0.67;panel.anchor_bottom=0.88
	panel.add_theme_stylebox_override("panel",UI.style(Color(0.008,0.022,0.030,0.76),Color(0.82,0.06,0.08,0.55),18))
	add_child(panel)
	var root:=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(root)
	var label:=UI.label("OPERADOR",17,UI.CYAN)
	label.position=Vector2(18,14)
	root.add_child(label)

	var container:=SubViewportContainer.new()
	container.anchor_left=0.04;container.anchor_top=0.08;container.anchor_right=0.96;container.anchor_bottom=0.68
	container.stretch=true
	container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(container)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(600,700)
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var world:=Node3D.new()
	viewport.add_child(world)
	var camera:=Camera3D.new()
	camera.position=Vector3(0,1.05,3.45)
	camera.fov=31
	camera.current=true
	world.add_child(camera)
	camera.look_at(Vector3(0,0.88,0))
	var key:=DirectionalLight3D.new()
	key.rotation_degrees=Vector3(-36,-28,0)
	key.light_energy=1.6
	key.light_color=Color(0.80,0.93,0.96)
	key.shadow_enabled=true
	world.add_child(key)
	var rim:=OmniLight3D.new()
	rim.position=Vector3(-1.2,1.2,-0.8)
	rim.light_color=Color(0.88,0.05,0.07)
	rim.light_energy=3.4
	rim.omni_range=5.0
	world.add_child(rim)
	_preview_turntable=Node3D.new()
	world.add_child(_preview_turntable)

	_operator_name=UI.label("",30)
	_operator_name.anchor_left=0.05;_operator_name.anchor_top=0.69;_operator_name.anchor_right=0.95;_operator_name.anchor_bottom=0.75
	_operator_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_operator_name)
	_operator_role=UI.label("",16,UI.AMBER)
	_operator_role.anchor_left=0.05;_operator_role.anchor_top=0.75;_operator_role.anchor_right=0.95;_operator_role.anchor_bottom=0.80
	_operator_role.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_operator_role)

	var choices:=HBoxContainer.new()
	choices.anchor_left=0.04;choices.anchor_top=0.82;choices.anchor_right=0.96;choices.anchor_bottom=0.98
	choices.alignment=BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation",8)
	root.add_child(choices)
	for entry in Characters.all():
		var id:=StringName(entry.id)
		var button:=Button.new()
		button.custom_minimum_size=Vector2(112,62)
		button.text=String(entry.name)
		button.tooltip_text=String(entry.description)
		var avatar_path:=String(entry.get("avatar",""))
		if not avatar_path.is_empty() and ResourceLoader.exists(avatar_path):
			button.icon=load(avatar_path)
			button.expand_icon=true
			button.add_theme_constant_override("icon_max_width",34)
		UI.skin_button(button,false)
		button.pressed.connect(_select_operator.bind(id))
		choices.add_child(button)

func _process(delta:float)->void:
	if _preview_turntable!=null and _preview_model!=null and is_instance_valid(_preview_model):
		_preview_turntable.rotation.y=fposmod(_preview_turntable.rotation.y+delta*0.12,TAU)

func _select_operator(id:StringName)->void:
	GuestIdentity.set_selected_character(id)
	var entry:=Characters.get_character(id)
	_operator_name.text=String(entry.name)
	_operator_role.text="%s  //  %s" % [String(entry.role),String(entry.description)]
	if _preview_model!=null and is_instance_valid(_preview_model):
		_preview_model.queue_free()
	_preview_model=ProceduralCharacters.create_operator(id)
	_preview_model.name="LobbyOperator"
	_preview_turntable.add_child(_preview_model)

func _build_modes()->void:
	var panel:=PanelContainer.new()
	panel.anchor_left=0.69;panel.anchor_top=0.14;panel.anchor_right=0.965;panel.anchor_bottom=0.66
	panel.add_theme_stylebox_override("panel",UI.style(Color(0.010,0.032,0.042,0.94),Color(UI.CYAN.r,UI.CYAN.g,UI.CYAN.b,0.42),18))
	add_child(panel)
	var box:=VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	panel.add_child(box)
	box.add_child(UI.label("OPERACIÓN",22,UI.CYAN))
	_mode_art=TextureRect.new()
	_mode_art.custom_minimum_size=Vector2(0,150)
	_mode_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	_mode_art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	box.add_child(_mode_art)
	_mode_title=UI.label("",25)
	box.add_child(_mode_title)
	_mode_description=UI.label("",16,UI.MUTED)
	_mode_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_mode_description.custom_minimum_size.y=55
	box.add_child(_mode_description)
	for mode in Modes.MODES:
		var id:=String(mode.id)
		var b:=UI.button(String(mode.title),_select_mode.bind(id),id=="campaign")
		b.custom_minimum_size.y=48
		box.add_child(b)

func _select_mode(id:String)->void:
	selected_mode=id
	var mode:=Modes.find(id)
	_mode_title.text=String(mode.title)
	_mode_description.text=String(mode.description)
	var art:=String(mode.get("image",""))
	if ResourceLoader.exists(art):
		_mode_art.texture=load(art)
	if _mission_selector!=null:
		_mission_selector.visible=id=="campaign"

func _build_launch_panel()->void:
	var panel:=PanelContainer.new()
	panel.anchor_left=0.69;panel.anchor_top=0.68;panel.anchor_right=0.965;panel.anchor_bottom=0.94
	panel.add_theme_stylebox_override("panel",UI.style(Color(0.012,0.030,0.038,0.96),Color(UI.AMBER.r,UI.AMBER.g,UI.AMBER.b,0.48),18))
	add_child(panel)
	var box:=VBoxContainer.new()
	box.add_theme_constant_override("separation",6)
	panel.add_child(box)
	var difficulty:=OptionButton.new()
	for item in ["HISTORIA","NORMAL","DIFÍCIL","PESADILLA"]:
		difficulty.add_item(item)
	difficulty.selected=1
	difficulty.item_selected.connect(func(index:int): selected_difficulty=["story","normal","hard","nightmare"][index])
	box.add_child(difficulty)

	var row:=HBoxContainer.new()
	box.add_child(row)
	row.add_child(UI.label("COMPAÑEROS IA",16,UI.MUTED))
	var companions:=SpinBox.new()
	companions.min_value=0;companions.max_value=3;companions.step=1;companions.value=2
	companions.value_changed.connect(func(value:float): companion_count=int(value))
	companions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(companions)

	_mission_selector=OptionButton.new()
	_mission_selector.add_item("MISIÓN 01 · PRIMERA SEÑAL")
	_mission_selector.add_item("MISIÓN 02 · ÚLTIMA TRANSMISIÓN")
	_mission_selector.item_selected.connect(func(index:int): selected_mission=&"mission_02_last_broadcast" if index==1 else &"mission_01_first_signal")
	box.add_child(_mission_selector)

	var launch:=UI.button("INICIAR PARTIDA OFFLINE",_launch,true,"play")
	launch.custom_minimum_size.y=68
	box.add_child(launch)

func _launch()->void:
	start_requested.emit({
		"mode":selected_mode,
		"difficulty":selected_difficulty,
		"companions":companion_count,
		"mission_id":selected_mission,
		"character_id":GuestIdentity.selected_character,
	})

func _refresh_profile()->void:
	var snapshot:Dictionary=Progress.snapshot()
	_profile_label.text="NIVEL %d   ·   %d NXC\nMEJOR OLEADA %d   ·   %d PARTIDAS" % [
		int(snapshot.get("level",1)),int(snapshot.get("coins",0)),
		int(snapshot.get("best_wave",0)),int(snapshot.get("runs",0))]
