extends Node2D

signal chosen(id: String)
signal finished()

const CHARS_PER_SECOND := 34.0
const BLIP_EVERY := 2

@export var bubble_width: int = 168

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/Margin/Rows/Speaker
@onready var body_label: Label = $Panel/Margin/Rows/Body
@onready var options_box: VBoxContainer = $Panel/Margin/Rows/Options
@onready var hint_label: Label = $Panel/Margin/Rows/Hint
@onready var tail: Polygon2D = $Tail
@onready var blip: AudioStreamPlayer = $Blip

var _lines: Array = []
var _line_index := 0
var _options: Array = []
var _selected := 0
var _revealed := 0.0
var _typing := false
var _active := false

func _ready() -> void:
	hide()
	panel.custom_minimum_size.x = bubble_width

func is_active() -> bool:
	return _active

func speak(speaker: String, lines: Array, options: Array = []) -> void:
	speaker_label.text = speaker
	_lines = lines
	_options = options
	_line_index = 0
	_selected = 0
	_active = true
	show()
	_start_line()

func dismiss() -> void:
	_active = false
	_typing = false
	hide()
	finished.emit()

func _start_line() -> void:
	body_label.text = str(_lines[_line_index])
	body_label.visible_characters = 0
	_revealed = 0.0
	_typing = true
	options_box.hide()
	hint_label.text = ""
	_layout()

func _process(delta: float) -> void:
	if not _active:
		return
	if _typing:
		var before := int(_revealed)
		_revealed = minf(_revealed + CHARS_PER_SECOND * delta, float(body_label.text.length()))
		var now := int(_revealed)
		if now > before:
			body_label.visible_characters = now
			if now % BLIP_EVERY == 0 and body_label.text[now - 1] != " ":
				blip.pitch_scale = randf_range(0.94, 1.10)
				blip.play()
			_layout()
		if _revealed >= float(body_label.text.length()):
			_finish_typing()
	_layout()

func _finish_typing() -> void:
	_typing = false
	body_label.visible_characters = -1
	if _line_index < _lines.size() - 1:
		hint_label.text = "[E]  more"
	elif _options.is_empty():
		hint_label.text = "[E]  close"
	else:
		_show_options()
	_layout()

func _show_options() -> void:
	hint_label.text = ""
	for c in options_box.get_children():
		options_box.remove_child(c)
		c.queue_free()
	for i in range(_options.size()):
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 8)
		options_box.add_child(l)
	options_box.show()
	await get_tree().process_frame
	_paint_options()

func _paint_options() -> void:
	for i in range(mini(options_box.get_child_count(), _options.size())):
		var l: Label = options_box.get_child(i)
		var picked: bool = i == _selected
		l.text = ("> " if picked else "  ") + str(_options[i]["text"])
		l.add_theme_color_override("font_color", Color(1, 0.86, 0.45) if picked else Color(0.72, 0.75, 0.72))
	_layout()

func _layout() -> void:
	panel.position = Vector2(-panel.size.x * 0.5, -panel.size.y - 10.0)
	tail.position = Vector2(0, -10)

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	var confirm := event.is_action_pressed("interact") or event.is_action_pressed("cast")
	if _typing:
		if confirm:
			_revealed = float(body_label.text.length())
			body_label.visible_characters = -1
			_finish_typing()
			get_viewport().set_input_as_handled()
		return
	if not options_box.visible:
		if confirm:
			if _line_index < _lines.size() - 1:
				_line_index += 1
				_start_line()
			else:
				dismiss()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("move_up"):
		_selected = posmod(_selected - 1, _options.size())
		_paint_options()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_selected = posmod(_selected + 1, _options.size())
		_paint_options()
		get_viewport().set_input_as_handled()
	elif confirm:
		chosen.emit(str(_options[_selected]["id"]))
		get_viewport().set_input_as_handled()
