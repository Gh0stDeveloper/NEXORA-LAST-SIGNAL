class_name LastSignalInventoryHUD
extends CanvasLayer

var player: Node
var inventory: Node
var panel: PanelContainer
var contents: Label

func bind(local_player: Node) -> void:
	player=local_player
	inventory=player.get_node_or_null("Inventory") if player!=null else null
	_build()
	if inventory!=null and inventory.has_signal("changed"):
		inventory.connect("changed",Callable(self,"_refresh"))
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_I:
		_toggle()

func _build()->void:
	layer=32
	var root:=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preload("res://src/ui/TacticalTheme.gd").apply(root)
	add_child(root)
	var button:=Button.new()
	button.text="INVENTARIO"
	button.anchor_left=0.0; button.anchor_top=1.0; button.anchor_right=0.0; button.anchor_bottom=1.0
	button.offset_left=24; button.offset_top=-118; button.offset_right=188; button.offset_bottom=-58
	button.mouse_filter=Control.MOUSE_FILTER_STOP
	preload("res://src/ui/TacticalTheme.gd").skin_button(button,false)
	button.pressed.connect(_toggle)
	root.add_child(button)
	panel=PanelContainer.new()
	panel.anchor_left=0.5; panel.anchor_top=0.5; panel.anchor_right=0.5; panel.anchor_bottom=0.5
	panel.offset_left=-290; panel.offset_top=-220; panel.offset_right=290; panel.offset_bottom=220
	panel.visible=false
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel",preload("res://src/ui/TacticalTheme.gd").style(Color(0.018,0.035,0.045,0.98),Color(0.20,0.70,0.73,0.75),22))
	root.add_child(panel)
	var box:=VBoxContainer.new()
	box.add_theme_constant_override("separation",12)
	panel.add_child(box)
	var title:=Label.new()
	title.text="INVENTARIO LOCAL"
	title.add_theme_font_size_override("font_size",30)
	box.add_child(title)
	contents=Label.new()
	contents.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	contents.add_theme_font_size_override("font_size",20)
	box.add_child(contents)
	var medkit:=Button.new()
	medkit.text="USAR BOTIQUÍN"
	preload("res://src/ui/TacticalTheme.gd").skin_button(medkit,true)
	medkit.pressed.connect(_use_medkit)
	box.add_child(medkit)
	var close:=Button.new()
	close.text="CERRAR"
	preload("res://src/ui/TacticalTheme.gd").skin_button(close,false)
	close.pressed.connect(_toggle)
	box.add_child(close)

func _toggle()->void:
	if panel==null:return
	panel.visible=not panel.visible
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if panel.visible else (Input.MOUSE_MODE_VISIBLE if OS.has_feature("mobile") else Input.MOUSE_MODE_CAPTURED)

func _use_medkit()->void:
	if inventory==null or player==null:return
	if not bool(inventory.call("consume_item",&"medkit",1)):
		AudioDirector.play_ui(&"ui_error")
		return
	var health:=player.get_node_or_null("Health")
	if health!=null and health.has_method("heal_authoritative"):
		health.call("heal_authoritative",45.0)
	AudioDirector.play_ui(&"ui_confirm")
	_refresh()

func _refresh(_snapshot:Dictionary={})->void:
	if contents==null or inventory==null:return
	var snap:Dictionary=inventory.call("snapshot")
	var items:Dictionary=snap.get("items",{})
	var weapons:Array=snap.get("weapons",[])
	var lines:=PackedStringArray()
	lines.append("ARMAS")
	for weapon in weapons: lines.append("  • %s" % String(weapon).to_upper())
	lines.append("")
	lines.append("LOOT")
	if items.is_empty():
		lines.append("  Sin objetos")
	else:
		for key in items: lines.append("  • %s ×%d" % [String(key).replace("_"," ").to_upper(),int(items[key])])
	contents.text="\n".join(lines)
