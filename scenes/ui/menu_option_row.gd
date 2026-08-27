extends Control

signal value_changed(value: float)

enum Kind { SLIDER, TOGGLE }

const SFX_MOVE := preload("res://assets/audio/sfx/text_blip.wav")
const SFX_TICK := preload("res://assets/audio/sfx/equip.wav")

const STEP := 0.05
const NAME_IDLE := Color(0.72, 0.66, 0.55)
const NAME_LIT := Color(1.0, 0.92, 0.72)
const TROUGH_IDLE := Color(0.88, 0.88, 0.88)
const TROUGH_LIT := Color(1.15, 1.1, 1.0)

@export var kind: Kind = Kind.SLIDER
@export var label_text: String = "":
	set(value):
		label_text = value
		if name_label != null:
			name_label.text = value

@onready var name_label: Label = $Name
@onready var value_label: Label = $Value
@onready var trough: NinePatchRect = $Trough
@onready var fill: TextureRect = $Trough/Fill

var value: float = 1.0
var _armed: bool = false

func _ready() -> void:
	name_label.text = label_text
	trough.visible = kind == Kind.SLIDER
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(func(): _paint(false))
	mouse_entered.connect(func(): if not has_focus(): grab_focus())
	resized.connect(refresh)
	_paint(has_focus())
	refresh()
	await get_tree().process_frame
	_armed = true

func set_value(v: float, notify: bool = false) -> void:
	var next := clampf(v, 0.0, 1.0)
	if is_equal_approx(next, value):
		return
	value = next
	refresh()
	if notify:
		value_changed.emit(value)

func refresh() -> void:
	if kind == Kind.TOGGLE:
		value_label.text = "‹ On ›" if value >= 0.5 else "‹ Off ›"
		return
	value_label.text = "%d%%" % roundi(value * 100.0)
	var inner := trough.size.x - 32.0
	fill.size = Vector2(maxf(0.0, roundf(inner * value)), fill.size.y)
	fill.visible = fill.size.x >= 1.0

func _gui_input(event: InputEvent) -> void:
	var dir := 0
	if event.is_action_pressed("ui_right", true) or event.is_action_pressed("move_right", true):
		dir = 1
	elif event.is_action_pressed("ui_left", true) or event.is_action_pressed("move_left", true):
		dir = -1
	elif kind == Kind.TOGGLE and event.is_action_pressed("ui_accept"):
		dir = 1 if value < 0.5 else -1
	if dir == 0:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_grab_from_mouse(event.position)
			accept_event()
		elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_grab_from_mouse(event.position)
			accept_event()
		return
	accept_event()
	var before := value
	if kind == Kind.TOGGLE:
		set_value(0.0 if value >= 0.5 else 1.0, true)
	else:
		set_value(value + STEP * dir, true)
	if not is_equal_approx(before, value):
		AudioManager.play_sfx(SFX_TICK, 1.0 + value * 0.12, -18.0)

func _grab_from_mouse(local: Vector2) -> void:
	if kind == Kind.TOGGLE:
		set_value(0.0 if value >= 0.5 else 1.0, true)
		AudioManager.play_sfx(SFX_TICK, 1.0, -18.0)
		return
	grab_focus()
	var inner := trough.size.x - 32.0
	if inner <= 0.0:
		return
	set_value((local.x - trough.position.x - 16.0) / inner, true)

func _on_focus_entered() -> void:
	_paint(true)
	if _armed:
		AudioManager.play_sfx(SFX_MOVE, randf_range(0.96, 1.06), -14.0)

func _paint(lit: bool) -> void:
	name_label.add_theme_color_override("font_color", NAME_LIT if lit else NAME_IDLE)
	value_label.add_theme_color_override("font_color", NAME_LIT if lit else NAME_IDLE)
	trough.modulate = TROUGH_LIT if lit else TROUGH_IDLE
