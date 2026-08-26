extends CanvasLayer

signal chosen(id: String)
signal closed()

@onready var speaker_label: Label = $Root/Panel/Speaker
@onready var body_label: Label = $Root/Panel/Body
@onready var options_box: VBoxContainer = $Root/Panel/Options

var _open: bool = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_dialogue(speaker: String, body: String, options: Array) -> void:
	speaker_label.text = speaker
	body_label.text = body
	for child in options_box.get_children():
		child.queue_free()
	for opt in options:
		var b := Button.new()
		b.text = str(opt["text"])
		b.focus_mode = Control.FOCUS_ALL
		var id := str(opt["id"])
		b.pressed.connect(func(): _pick(id))
		options_box.add_child(b)
	visible = true
	if not _open:
		_open = true
		get_tree().paused = true
	await get_tree().process_frame
	if options_box.get_child_count() > 0:
		options_box.get_child(0).grab_focus()

func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	get_tree().paused = false
	closed.emit()

func is_open() -> bool:
	return _open

func _pick(id: String) -> void:
	chosen.emit(id)

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
