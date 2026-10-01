extends Node

const GameWorldScript = preload("res://src/game/GameWorld.gd")

var menu: Control
var world: Node3D
var profile_label: Label

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _show_menu()

func _show_menu() -> void:
    if is_instance_valid(menu):
        menu.queue_free()
    menu = Control.new()
    menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(menu)

    var bg := ColorRect.new()
    bg.color = Color(0.018, 0.023, 0.031)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu.add_child(bg)

    var title := Label.new()
    title.text = "NEXORA: LAST SIGNAL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 56)
    title.set_anchors_preset(Control.PRESET_CENTER_TOP)
    title.position = Vector2(-420, 110)
    title.size = Vector2(840, 90)
    bg.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "SURVIVAL OFFLINE · 100% LOCAL"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 22)
    subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
    subtitle.position = Vector2(-320, 200)
    subtitle.size = Vector2(640, 50)
    bg.add_child(subtitle)

    var box := VBoxContainer.new()
    box.set_anchors_preset(Control.PRESET_CENTER)
    box.position = Vector2(-220, -80)
    box.size = Vector2(440, 360)
    box.add_theme_constant_override("separation", 14)
    bg.add_child(box)

    profile_label = Label.new()
    profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    profile_label.add_theme_font_size_override("font_size", 20)
    box.add_child(profile_label)
    _refresh_profile()

    var play := Button.new()
    play.text = "JUGAR SOLO"
    play.custom_minimum_size = Vector2(440, 64)
    play.pressed.connect(_start_game)
    box.add_child(play)

    var settings := Button.new()
    settings.text = "AJUSTES"
    settings.custom_minimum_size = Vector2(440, 56)
    settings.pressed.connect(_show_settings)
    box.add_child(settings)

    var quit := Button.new()
    quit.text = "SALIR"
    quit.custom_minimum_size = Vector2(440, 56)
    quit.pressed.connect(func(): get_tree().quit())
    box.add_child(quit)

    var note := Label.new()
    note.text = "No requiere cuenta, Internet, servidor, matchmaking ni API."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    note.position = Vector2(-360, -100)
    note.size = Vector2(720, 60)
    bg.add_child(note)

func _refresh_profile() -> void:
    if profile_label == null:
        return
    profile_label.text = "NIVEL %d   ·   %d NXC   ·   MEJOR OLEADA %d" % [
        int(SaveSystem.data.get("level", 1)),
        int(SaveSystem.data.get("coins", 0)),
        int(SaveSystem.data.get("best_wave", 0)),
    ]

func _start_game() -> void:
    if is_instance_valid(menu):
        menu.queue_free()
    world = GameWorldScript.new()
    world.leave_to_menu.connect(_on_world_left)
    add_child(world)

func _on_world_left(_summary: Dictionary) -> void:
    world = null
    call_deferred("_show_menu")

func _show_settings() -> void:
    var popup := AcceptDialog.new()
    popup.title = "Ajustes locales"
    popup.dialog_text = "Sensibilidad de cámara"
    popup.size = Vector2i(520, 260)
    menu.add_child(popup)

    var slider := HSlider.new()
    slider.min_value = 0.05
    slider.max_value = 0.5
    slider.step = 0.01
    slider.value = float(SaveSystem.get_setting("sensitivity", 0.16))
    slider.position = Vector2(24, 92)
    slider.size = Vector2(450, 42)
    slider.value_changed.connect(func(value): SaveSystem.set_setting("sensitivity", value))
    popup.add_child(slider)

    var touch := CheckBox.new()
    touch.text = "Mostrar controles táctiles en Android"
    touch.button_pressed = bool(SaveSystem.get_setting("show_mobile_controls", true))
    touch.position = Vector2(24, 142)
    touch.toggled.connect(func(value): SaveSystem.set_setting("show_mobile_controls", value))
    popup.add_child(touch)
    popup.popup_centered()
