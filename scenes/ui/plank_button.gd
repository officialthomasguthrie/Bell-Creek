extends TextureButton

const SFX_MOVE := preload("res://assets/audio/sfx/text_blip.wav")
const SFX_PICK := preload("res://assets/audio/sfx/equip.wav")

const PLANK_IDLE := Color(0.92, 0.92, 0.92)
const PLANK_LIT := Color(1.24, 1.16, 1.02)
const CARVED := Color(0.87, 0.8, 0.66)
const CARVED_EDGE := Color(0.05, 0.03, 0.02, 0.85)
const LIT_TEXT := Color(1.0, 0.92, 0.72)
const LIT_EDGE := Color(0.06, 0.03, 0.02, 0.9)

@export var text: String = "":
	set(value):
		text = value
		if label != null:
			label.text = value

@onready var label: Label = $Label

var _armed: bool = false

func _ready() -> void:
	label.text = text
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(func(): _paint(false))
	mouse_entered.connect(_on_mouse_entered)
	button_down.connect(func(): _shift(1))
	button_up.connect(func(): _shift(0))
	pressed.connect(func(): AudioManager.play_sfx(SFX_PICK, 1.0, -9.0))
	_paint(has_focus())
	await get_tree().process_frame
	_armed = true

func _on_mouse_entered() -> void:
	if not has_focus():
		grab_focus()

func _on_focus_entered() -> void:
	_paint(true)
	if _armed:
		AudioManager.play_sfx(SFX_MOVE, randf_range(0.96, 1.06), -14.0)

func _paint(lit: bool) -> void:
	modulate = PLANK_LIT if lit else PLANK_IDLE
	label.add_theme_color_override("font_color", LIT_TEXT if lit else CARVED)
	label.add_theme_color_override("font_shadow_color", LIT_EDGE if lit else CARVED_EDGE)

func _shift(pixels: int) -> void:
	label.offset_top = pixels
	label.offset_bottom = pixels
