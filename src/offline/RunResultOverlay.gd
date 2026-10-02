class_name LastSignalRunResultOverlay
extends CanvasLayer

signal lobby_requested

func show_result(summary:Dictionary)->void:
	layer=80
	var root:=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_STOP
	preload("res://src/ui/TacticalTheme.gd").apply(root)
	add_child(root)
	var shade:=ColorRect.new()
	shade.color=Color(0.005,0.012,0.016,0.90)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var panel:=PanelContainer.new()
	panel.anchor_left=0.5;panel.anchor_top=0.5;panel.anchor_right=0.5;panel.anchor_bottom=0.5
	panel.offset_left=-330;panel.offset_top=-260;panel.offset_right=330;panel.offset_bottom=260
	panel.add_theme_stylebox_override("panel",preload("res://src/ui/TacticalTheme.gd").style(Color(0.015,0.035,0.045,0.98),Color(0.92,0.12,0.12,0.70),24))
	root.add_child(panel)
	var box:=VBoxContainer.new()
	box.alignment=BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation",12)
	panel.add_child(box)
	var title:=Label.new()
	title.text=String(summary.get("outcome","PARTIDA FINALIZADA"))
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",38)
	box.add_child(title)
	var body:=Label.new()
	body.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size",22)
	var reward:Dictionary=summary.get("reward",{})
	body.text="MODO  %s\nDIFICULTAD  %s\nOLEADA  %d\nBAJAS  %d\nPUNTUACIÓN  %d\n\nXP +%d   ·   NXC +%d" % [
		String(summary.get("mode","campaign")).to_upper(),
		String(summary.get("difficulty","normal")).to_upper(),
		int(summary.get("wave",0)),int(summary.get("kills",0)),int(summary.get("score",0)),
		int(reward.get("xp",0)),int(reward.get("coins",0))]
	box.add_child(body)
	var button:=Button.new()
	button.text="VOLVER AL LOBBY"
	button.custom_minimum_size=Vector2(360,64)
	preload("res://src/ui/TacticalTheme.gd").skin_button(button,true)
	button.pressed.connect(func(): lobby_requested.emit())
	box.add_child(button)
