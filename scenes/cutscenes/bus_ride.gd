extends CanvasLayer

## The bus ride out of the orchard. Four first-person shots, with the driver
## clipping your ticket as an interactive beat in the middle: guess which hole
## he punches and the fare comes with a kickback.
##
## Each shot draws `art` when that file exists and falls back to a labelled
## placeholder when it does not, so the sequence is playable before the art
## lands and needs no code change once it does.

signal finished()

const DEST_SCENE := "res://scenes/areas/Area02Desert.tscn"
const DEST_SPAWN := "SpawnFromBus"
const TICKET_ART := "res://assets/sprites/items/ticket.png"
const PUNCH_HOLE := preload("res://assets/sprites/items/punch_hole.png")

## The printed ticket is a ten-trip card. These boxes already carry a punch on
## the art, so they are spent - the driver can only clip one of the rest.
const TICKET_BOXES := 10
const PUNCHED_BOXES := [3, 4, 6, 8, 9]
const PRIZE := 50

const SHOT_APPROACH := 0
const SHOT_CLIP := 1
const SHOT_AISLE := 2
const SHOT_SEAT := 3

const SHOTS := [
	{"art": "res://assets/sprites/cutscene/bus_approach.png",
	 "title": "SHOT 1 of 4", "caption": "Walking up to the driver in his seat", "hold": 2.4},
	{"art": "res://assets/sprites/cutscene/bus_clip.png",
	 "title": "SHOT 2 of 4", "caption": "The driver takes your ticket to clip it", "hold": -1.0},
	{"art": "res://assets/sprites/cutscene/bus_aisle.png",
	 "title": "SHOT 3 of 4", "caption": "Walking down the aisle to a seat", "hold": 2.2},
	{"art": "res://assets/sprites/cutscene/bus_seat.png",
	 "title": "SHOT 4 of 4", "caption": "Sat in the seat behind the driver", "hold": 2.6},
]

## Where the ten-trip row sits on the ticket art, as fractions of the card.
## Retune if the ticket art is redrawn.
@export var row_origin: Vector2 = Vector2(12.0 / 304.0, 62.0 / 96.0)
@export var row_size: Vector2 = Vector2(280.0 / 304.0, 26.0 / 96.0)
@export var reveal_delay: float = 0.55

@onready var frame: TextureRect = $Root/Frame
@onready var placeholder: Control = $Root/Placeholder
@onready var ph_title: Label = $Root/Placeholder/Title
@onready var ph_caption: Label = $Root/Placeholder/Caption
@onready var ph_path: Label = $Root/Placeholder/Path
@onready var ticket: Control = $Root/Ticket
@onready var card: TextureRect = $Root/Ticket/Card
@onready var card_fill: ColorRect = $Root/Ticket/CardFill
@onready var spots_root: Control = $Root/Ticket/Spots
@onready var prompt: Label = $Root/Prompt
@onready var fade: ColorRect = $Root/Fade

var _shot := -1
var _waiting := false
var _picking := false
var _pick := 0            ## index into _free_boxes, not a box number
var _driver_pick := 0     ## index into _free_boxes
var _free_boxes: Array[int] = []
var _spots: Array[Control] = []
var _hole: TextureRect


func _ready() -> void:
	GameState.dialogue_open = true
	ticket.hide()
	fade.color.a = 1.0
	_build_spots()
	_run()


func _run() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.35)
	await tw.finished
	await _play(SHOT_APPROACH)
	await _play(SHOT_CLIP)
	await _play(SHOT_AISLE)
	await _play(SHOT_SEAT)
	await _leave()


func _play(index: int) -> void:
	_shot = index
	var shot: Dictionary = SHOTS[index]
	_show_art(str(shot["art"]), str(shot["title"]), str(shot["caption"]))
	if index == SHOT_CLIP:
		await _clip_ticket()
		return
	prompt.text = "Enter  continue"
	ticket.hide()
	await _hold(float(shot["hold"]))


## Draws the shot's art if it has been added, otherwise a placeholder naming
## the exact file to drop in.
func _show_art(path: String, title: String, caption: String) -> void:
	if ResourceLoader.exists(path):
		frame.texture = load(path)
		frame.show()
		placeholder.hide()
		return
	frame.hide()
	placeholder.show()
	ph_title.text = title
	ph_caption.text = caption
	ph_path.text = path.replace("res://", "") + "    (640 x 360)"


func _hold(seconds: float) -> void:
	_waiting = true
	var timer := get_tree().create_timer(seconds)
	timer.timeout.connect(func() -> void: _waiting = false)
	while _waiting:
		await get_tree().process_frame


func _build_spots() -> void:
	for c in spots_root.get_children():
		c.queue_free()
	_spots.clear()
	_free_boxes.clear()
	for n in range(1, TICKET_BOXES + 1):
		if not PUNCHED_BOXES.has(n):
			_free_boxes.append(n)
	for i in range(_free_boxes.size()):
		var cell := ColorRect.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spots_root.add_child(cell)
		_spots.append(cell)
	_hole = TextureRect.new()
	_hole.texture = PUNCH_HOLE
	_hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hole.hide()
	spots_root.add_child(_hole)
	_layout_spots()


## Rect of one printed box, in card-local pixels.
func _box_rect(box_number: int) -> Rect2:
	var card_px := card_fill.size
	var origin := Vector2(row_origin.x * card_px.x, row_origin.y * card_px.y)
	var span := Vector2(row_size.x * card_px.x, row_size.y * card_px.y)
	var cell_w := span.x / float(TICKET_BOXES)
	return Rect2(origin + Vector2(cell_w * float(box_number - 1), 0.0), Vector2(cell_w, span.y))


func _layout_spots() -> void:
	for i in range(_spots.size()):
		var r := _box_rect(_free_boxes[i])
		_spots[i].position = r.position + Vector2(1, 1)
		_spots[i].size = r.size - Vector2(2, 2)
	_paint_spots()


func _paint_spots() -> void:
	for i in range(_spots.size()):
		var cell: ColorRect = _spots[i]
		if _picking and i == _pick:
			cell.color = Color(1.0, 0.86, 0.45, 0.5)   # the box you are calling
		else:
			cell.color = Color(0.0, 0.0, 0.0, 0.0)     # untouched


func _reveal_punch(index: int) -> void:
	var r := _box_rect(_free_boxes[index])
	_hole.position = r.position + (r.size - _hole.texture.get_size()) * 0.5
	_hole.size = _hole.texture.get_size()
	_hole.show()


func _clip_ticket() -> void:
	if ResourceLoader.exists(TICKET_ART):
		card.texture = load(TICKET_ART)
		card.show()
		card_fill.color = Color(1, 1, 1, 0)
	else:
		card.hide()
		card_fill.color = Color(0.93, 0.89, 0.78, 1.0)
	ticket.show()
	await get_tree().process_frame
	_layout_spots()
	_hole.hide()
	_driver_pick = randi() % maxi(_free_boxes.size(), 1)
	_pick = 0
	_picking = true
	_paint_spots()
	_update_prompt()
	while _picking:
		await get_tree().process_frame


func _update_prompt() -> void:
	prompt.text = "Which one does he clip?    calling %d    A D  move    Enter  lock it in" % _free_boxes[_pick]


func _confirm_pick() -> void:
	_picking = false
	_paint_spots()
	AudioManager.play_sfx(preload("res://assets/audio/sfx/equip.wav"), 1.0, -8.0)
	await get_tree().create_timer(reveal_delay).timeout
	_reveal_punch(_driver_pick)
	var won: bool = _pick == _driver_pick
	if won:
		GameState.award(PRIZE)
		prompt.text = "Box %d.  Dead on - he slips you $%d." % [_free_boxes[_driver_pick], PRIZE]
		AudioManager.play_sfx(preload("res://assets/audio/sfx/buy.wav"), 1.0, -6.0)
	else:
		prompt.text = "Box %d.  He clips it and hands it back." % _free_boxes[_driver_pick]
		AudioManager.play_sfx(preload("res://assets/audio/sfx/deny.wav"), 1.0, -10.0)
	await get_tree().create_timer(1.6).timeout
	ticket.hide()


func _leave() -> void:
	prompt.text = ""
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.45)
	await tw.finished
	GameState.has_ticket = false
	GameState.dialogue_open = false
	finished.emit()
	SceneLoader.go(DEST_SCENE, DEST_SPAWN)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _picking:
		if event.is_action_pressed("move_left"):
			_pick = posmod(_pick - 1, _free_boxes.size())
			_paint_spots()
			_update_prompt()
		elif event.is_action_pressed("move_right"):
			_pick = posmod(_pick + 1, _free_boxes.size())
			_paint_spots()
			_update_prompt()
		elif event.is_action_pressed("interact") or event.is_action_pressed("cast"):
			_confirm_pick()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if _waiting and (event.is_action_pressed("interact") or event.is_action_pressed("cast")):
		_waiting = false
		get_viewport().set_input_as_handled()
