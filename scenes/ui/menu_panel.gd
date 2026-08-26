extends CanvasLayer

signal chosen(id: String)
signal closed()

@onready var title_label: Label = $Root/Centre/Panel/Margin/Rows/Title
@onready var note_label: Label = $Root/Centre/Panel/Margin/Rows/Note
@onready var options_box: VBoxContainer = $Root/Centre/Panel/Margin/Rows/Options
@onready var hint_label: Label = $Root/Centre/Panel/Margin/Rows/Hint

var _options: Array = []
var _selected := 0
var _open := false

func _ready() -> void:
	hide()

func is_open() -> bool:
	return _open

func open(title: String, note: String, options: Array) -> void:
	title_label.text = title
	note_label.text = note
	note_label.visible = note != ""
	_options = options
	_selected = 0
	_open = true
	GameState.dialogue_open = true
	_build()
	show()

func close() -> void:
	if not _open:
		return
	_open = false
	hide()
	GameState.dialogue_open = false
	closed.emit()

func refresh(note: String, options: Array) -> void:
	note_label.text = note
	note_label.visible = note != ""
	_options = options
	_selected = mini(_selected, maxi(_options.size() - 1, 0))
	_build()

func _build() -> void:
	for c in options_box.get_children():
		options_box.remove_child(c)
		c.queue_free()
	for i in range(_options.size()):
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 8)
		options_box.add_child(l)
	_paint()

func _paint() -> void:
	for i in range(mini(options_box.get_child_count(), _options.size())):
		var opt: Dictionary = _options[i]
		var l: Label = options_box.get_child(i)
		var locked: bool = bool(opt.get("locked", false))
		var picked: bool = i == _selected
		l.text = ("> " if picked else "  ") + str(opt["text"])
		var col := Color(0.42, 0.45, 0.42)
		if not locked:
			col = Color(1, 0.86, 0.45) if picked else Color(0.76, 0.79, 0.76)
		elif picked:
			col = Color(0.62, 0.55, 0.42)
		l.add_theme_color_override("font_color", col)
	hint_label.text = "W/S  choose      E  select      Esc  leave"

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_up"):
		_selected = posmod(_selected - 1, _options.size())
		_paint()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_selected = posmod(_selected + 1, _options.size())
		_paint()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("cast"):
		var opt: Dictionary = _options[_selected]
		if bool(opt.get("locked", false)):
			GameState.say(str(opt.get("locked_note", "Not yet")))
		else:
			chosen.emit(str(opt["id"]))
		get_viewport().set_input_as_handled()
