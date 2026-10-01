extends CanvasLayer

var player: CharacterBody3D
var move_touch := -1
var look_touch := -1
var move_origin := Vector2.ZERO
var move_current := Vector2.ZERO
var last_look := Vector2.ZERO
var stick_base: ColorRect
var stick_knob: ColorRect

func _ready() -> void:
	layer = 10
	_build_ui()

func bind(local_player: CharacterBody3D) -> void:
	player = local_player

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	stick_base = ColorRect.new()
	stick_base.color = Color(1, 1, 1, 0.12)
	stick_base.size = Vector2(180, 180)
	stick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stick_base.position = Vector2(64, -244)
	stick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stick_base)

	stick_knob = ColorRect.new()
	stick_knob.color = Color(1, 1, 1, 0.28)
	stick_knob.size = Vector2(72, 72)
	stick_knob.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stick_knob.position = Vector2(118, -190)
	stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stick_knob)

	_add_hold_button(root, "DISPARAR", Vector2(-260, -190), Vector2(190, 100))
	_add_button(root, "RECARGAR", Vector2(-470, -105), Vector2(180, 72), func():
		if player:
			player.reload()
	)
	_add_button(root, "SALTAR", Vector2(-255, -320), Vector2(160, 72), func():
		if player:
			player.mobile_jump()
	)

func _add_hold_button(root: Control, text: String, offset: Vector2, button_size: Vector2) -> void:
	var button := Button.new()
	button.text = text
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position = offset
	button.size = button_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.button_down.connect(func():
		if player:
			player.set_mobile_fire(true)
	)
	button.button_up.connect(func():
		if player:
			player.set_mobile_fire(false)
	)
	root.add_child(button)

func _add_button(root: Control, text: String, offset: Vector2, button_size: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	button.position = offset
	button.size = button_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(callback)
	root.add_child(button)

func _input(event: InputEvent) -> void:
	if player == null:
		return
	var screen := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < screen.x * 0.46 and move_touch == -1:
				move_touch = event.index
				move_origin = event.position
				move_current = event.position
			elif look_touch == -1:
				look_touch = event.index
				last_look = event.position
		else:
			if event.index == move_touch:
				move_touch = -1
				player.set_mobile_move(Vector2.ZERO)
				_reset_stick()
			elif event.index == look_touch:
				look_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == move_touch:
			move_current = event.position
			var delta := (move_current - move_origin) / 90.0
			delta = delta.limit_length(1.0)
			player.set_mobile_move(delta)
			stick_knob.position = Vector2(118, -190) + delta * 48.0
		elif event.index == look_touch:
			var look_delta := event.position - last_look
			last_look = event.position
			player.add_mobile_look(look_delta * 0.65)

func _exit_tree() -> void:
	if player:
		player.set_mobile_fire(false)
		player.set_mobile_move(Vector2.ZERO)

func _reset_stick() -> void:
	stick_knob.position = Vector2(118, -190)
