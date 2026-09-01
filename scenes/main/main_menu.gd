extends Control

const AREA := "res://scenes/areas/Area01Orchard.tscn"
const PLANK := preload("res://scenes/ui/PlankButton.tscn")

const DRIFT := Vector2(26.0, 14.0)
const DRIFT_TIME := 15.0
const PAGE_FADE := 0.16

@onready var backdrop: TextureRect = $Backdrop
@onready var board: NinePatchRect = $Board
@onready var options_board: NinePatchRect = $OptionsBoard
@onready var play_button: TextureButton = $Board/Buttons/Play
@onready var options_button: TextureButton = $Board/Buttons/Options
@onready var quit_button: TextureButton = $Board/Buttons/Quit
@onready var music_row: Control = $OptionsBoard/Rows/Music
@onready var sound_row: Control = $OptionsBoard/Rows/Sound
@onready var fullscreen_row: Control = $OptionsBoard/Rows/Fullscreen
@onready var back_button: TextureButton = $OptionsBoard/Rows/Back
@onready var buttons_box: VBoxContainer = $Board/Buttons

var _on_options: bool = false
var _on_coop: bool = false
var _leaving: bool = false
var _swap_tween: Tween

var coop_button: TextureButton
var coop_board: NinePatchRect
var ip_edit: LineEdit
var host_button: TextureButton
var join_button: TextureButton
var coop_back: TextureButton

func _ready() -> void:
	GameState.dialogue_open = false
	get_tree().paused = false

	if OS.has_feature("web"):
		quit_button.hide()
		play_button.focus_neighbor_top = play_button.get_path_to(options_button)
		options_button.focus_neighbor_bottom = options_button.get_path_to(play_button)

	play_button.pressed.connect(_start_game)
	options_button.pressed.connect(_open_options)
	quit_button.pressed.connect(_quit)
	back_button.pressed.connect(_close_options)

	music_row.set_value(Settings.music)
	sound_row.set_value(Settings.sfx)
	fullscreen_row.set_value(1.0 if Settings.fullscreen else 0.0)
	music_row.value_changed.connect(func(v: float): Settings.set_music(v))
	sound_row.value_changed.connect(func(v: float): Settings.set_sfx(v))
	fullscreen_row.value_changed.connect(func(v: float): Settings.set_fullscreen(v >= 0.5))

	options_board.hide()
	options_board.modulate.a = 0.0
	_build_coop()
	_drift()
	play_button.grab_focus()

func _build_coop() -> void:
	coop_button = _plank("CO-OP")
	buttons_box.add_child(coop_button)
	buttons_box.move_child(coop_button, 1)
	coop_button.pressed.connect(_open_coop)

	# borrow the options board so the co-op page matchs the rest of the menu
	coop_board = options_board.duplicate()
	add_child(coop_board)
	var rows: VBoxContainer = coop_board.get_node("Rows")
	for c in rows.get_children():
		if c.name == "Heading":
			c.text = "CO-OP"
			continue
		rows.remove_child(c)
		c.queue_free()

	ip_edit = LineEdit.new()
	ip_edit.text = "127.0.0.1"
	ip_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip_edit.add_theme_font_size_override("font_size", 8)
	rows.add_child(ip_edit)

	host_button = _plank("HOST")
	join_button = _plank("JOIN")
	coop_back = _plank("BACK")
	for b in [host_button, join_button, coop_back]:
		rows.add_child(b)
	host_button.pressed.connect(func(): _dial(true))
	join_button.pressed.connect(func(): _dial(false))
	coop_back.pressed.connect(_close_coop)

	coop_board.hide()
	coop_board.modulate.a = 0.0


func _plank(caption: String) -> TextureButton:
	var b: TextureButton = PLANK.instantiate()
	b.text = caption
	return b


# host, or dial out to whatevers in the ip box
func _dial(serving: bool) -> void:
	var ok := Net.host() if serving else Net.join(ip_edit.text.strip_edges())
	if ok:
		_start_game()


func _drift() -> void:
	var home := backdrop.position
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(backdrop, "position", home + DRIFT, DRIFT_TIME)
	tween.tween_property(backdrop, "position", home - DRIFT, DRIFT_TIME * 2.0)
	tween.tween_property(backdrop, "position", home, DRIFT_TIME)

func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	var backing := event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")
	if backing and (_on_options or _on_coop):
		get_viewport().set_input_as_handled()
		if _on_options:
			_close_options()
		else:
			_close_coop()
		return
	var step := 0
	if event.is_action_pressed("move_down") and not event.is_action("ui_down"):
		step = 1
	elif event.is_action_pressed("move_up") and not event.is_action("ui_up"):
		step = -1
	if step == 0:
		return
	get_viewport().set_input_as_handled()
	_step_focus(step)

func _step_focus(step: int) -> void:
	var items := _page_items()
	var at := items.find(get_viewport().gui_get_focus_owner())
	if at < 0:
		at = 0 if step > 0 else items.size() - 1
	else:
		at = posmod(at + step, items.size())
	items[at].grab_focus()

func _page_items() -> Array:
	if _on_coop:
		return [host_button, join_button, coop_back]
	if _on_options:
		return [music_row, sound_row, fullscreen_row, back_button]
	var items: Array = [play_button, coop_button, options_button]
	if quit_button.visible:
		items.append(quit_button)
	return items

func _open_options() -> void:
	_on_options = true
	_swap(board, options_board)
	music_row.grab_focus()

func _close_options() -> void:
	_on_options = false
	_swap(options_board, board)
	options_button.grab_focus()


func _open_coop() -> void:
	_on_coop = true
	_swap(board, coop_board)
	host_button.grab_focus()


func _close_coop() -> void:
	_on_coop = false
	_swap(coop_board, board)
	coop_button.grab_focus()

func _swap(out_panel: Control, in_panel: Control) -> void:
	if _swap_tween != null and _swap_tween.is_valid():
		_swap_tween.kill()
	out_panel.process_mode = Node.PROCESS_MODE_DISABLED
	in_panel.modulate.a = 0.0
	in_panel.show()
	in_panel.process_mode = Node.PROCESS_MODE_INHERIT
	_swap_tween = create_tween().set_parallel()
	_swap_tween.tween_property(out_panel, "modulate:a", 0.0, PAGE_FADE)
	_swap_tween.tween_property(in_panel, "modulate:a", 1.0, PAGE_FADE)
	_swap_tween.chain().tween_callback(func() -> void:
		out_panel.hide()
		out_panel.modulate.a = 1.0
		in_panel.modulate.a = 1.0)

func _start_game() -> void:
	if _leaving:
		return
	_leaving = true
	SceneLoader.go(AREA)

func _quit() -> void:
	if _leaving:
		return
	_leaving = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.tween_callback(get_tree().quit)
