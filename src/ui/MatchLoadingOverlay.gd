class_name DeadfallMatchLoadingOverlay
extends CanvasLayer

signal return_requested()

const UI = preload("res://src/ui/TacticalTheme.gd")
const LOADING_ART: Texture2D = preload("res://assets/ui/quarantine_hangar.webp")

var _detail_label: Label
var _progress: ProgressBar

func _ready() -> void:
	layer = 90
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.apply(root)
	add_child(root)
	var background := TextureRect.new()
	background.texture = LOADING_ART
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0,0,0,0.42)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var box := VBoxContainer.new()
	box.anchor_left=0.08; box.anchor_top=0.72; box.anchor_right=0.92; box.anchor_bottom=0.92
	root.add_child(box)
	var title := Label.new()
	title.text="CARGANDO OPERACIÓN OFFLINE…"
	title.add_theme_font_size_override("font_size",32)
	box.add_child(title)
	_detail_label=Label.new()
	_detail_label.text="Preparando ciudad, IA, campaña y loot en este dispositivo…"
	box.add_child(_detail_label)
	_progress=ProgressBar.new()
	_progress.show_percentage=false
	_progress.value=35
	box.add_child(_progress)

func set_stage(text: String, progress_ratio: float) -> void:
	if _detail_label != null: _detail_label.text=text
	if _progress != null: _progress.value=clampf(progress_ratio,0,1)*100.0

func begin(_unused: String="") -> void:
	set_stage("Preparando simulación local…",0.15)

func complete() -> void:
	set_stage("LISTO · entrando a la zona",1.0)

func show_error(message: String) -> void:
	set_stage(message,0.0)
