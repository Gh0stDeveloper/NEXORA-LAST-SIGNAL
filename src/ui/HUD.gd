extends CanvasLayer

signal pause_requested
signal exit_requested

var player: CharacterBody3D
var director: Node
var health_label: Label
var ammo_label: Label
var wave_label: Label
var score_label: Label
var overlay: ColorRect
var overlay_title: Label
var overlay_body: Label
var resume_button: Button

func _ready() -> void:
    _build_ui()

func bind(local_player: CharacterBody3D, horde_director: Node) -> void:
    player = local_player
    director = horde_director
    player.stats_changed.connect(_on_player_stats)
    director.wave_changed.connect(_on_wave_changed)
    director.score_changed.connect(_on_score_changed)
    _on_player_stats(player.health, player.ammo, player.reserve_ammo)
    _on_wave_changed(0, 0, 0)
    _on_score_changed(0, 0, 0)

func _build_ui() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(root)

    health_label = Label.new()
    health_label.position = Vector2(28, 24)
    health_label.add_theme_font_size_override("font_size", 30)
    root.add_child(health_label)

    ammo_label = Label.new()
    ammo_label.position = Vector2(28, 62)
    ammo_label.add_theme_font_size_override("font_size", 26)
    root.add_child(ammo_label)

    wave_label = Label.new()
    wave_label.position = Vector2(28, 100)
    wave_label.add_theme_font_size_override("font_size", 24)
    root.add_child(wave_label)

    score_label = Label.new()
    score_label.position = Vector2(28, 136)
    score_label.add_theme_font_size_override("font_size", 20)
    root.add_child(score_label)

    var crosshair := Label.new()
    crosshair.text = "+"
    crosshair.add_theme_font_size_override("font_size", 28)
    crosshair.set_anchors_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-8, -18)
    root.add_child(crosshair)

    var pause := Button.new()
    pause.text = "II"
    pause.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    pause.position = Vector2(-94, 24)
    pause.size = Vector2(64, 54)
    pause.mouse_filter = Control.MOUSE_FILTER_STOP
    pause.pressed.connect(func(): pause_requested.emit())
    root.add_child(pause)

    overlay = ColorRect.new()
    overlay.color = Color(0.02, 0.025, 0.035, 0.88)
    overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.visible = false
    root.add_child(overlay)

    var panel := VBoxContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.position = Vector2(-240, -160)
    panel.size = Vector2(480, 320)
    panel.alignment = BoxContainer.ALIGNMENT_CENTER
    overlay.add_child(panel)

    overlay_title = Label.new()
    overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    overlay_title.add_theme_font_size_override("font_size", 40)
    panel.add_child(overlay_title)

    overlay_body = Label.new()
    overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    overlay_body.add_theme_font_size_override("font_size", 22)
    panel.add_child(overlay_body)

    resume_button = Button.new()
    resume_button.text = "Continuar"
    resume_button.custom_minimum_size = Vector2(320, 56)
    panel.add_child(resume_button)

    var exit := Button.new()
    exit.text = "Volver al menú"
    exit.custom_minimum_size = Vector2(320, 56)
    exit.pressed.connect(func(): exit_requested.emit())
    panel.add_child(exit)

func show_pause(on_resume: Callable) -> void:
    overlay.visible = true
    overlay_title.text = "PAUSA"
    overlay_body.text = "La partida está detenida localmente."
    resume_button.visible = true
    for connection in resume_button.pressed.get_connections():
        resume_button.pressed.disconnect(connection.callable)
    resume_button.pressed.connect(on_resume)

func show_game_over(summary: Dictionary) -> void:
    overlay.visible = true
    overlay_title.text = "FIN DE LA PARTIDA"
    overlay_body.text = "Oleada %d
Bajas: %d
XP: +%d
NXC: +%d" % [
        int(summary.get("wave", 0)), int(summary.get("kills", 0)), int(summary.get("xp", 0)), int(summary.get("coins", 0))
    ]
    resume_button.visible = false

func hide_overlay() -> void:
    overlay.visible = false

func _on_player_stats(health: int, ammo: int, reserve: int) -> void:
    health_label.text = "VIDA  %03d" % health
    ammo_label.text = "MUNICIÓN  %02d / %03d" % [ammo, reserve]

func _on_wave_changed(wave: int, alive: int, remaining: int) -> void:
    wave_label.text = "OLEADA %02d   ENEMIGOS %02d" % [wave, alive + remaining]

func _on_score_changed(kills: int, coins: int, xp: int) -> void:
    score_label.text = "BAJAS %d   NXC +%d   XP +%d" % [kills, coins, xp]
