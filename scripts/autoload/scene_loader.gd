extends Node

signal arrived()

const FADE_TIME := 0.30

var spawn_point: String = ""

var _fade: ColorRect
var _busy: bool = false

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.anchor_right = 1.0
	_fade.anchor_bottom = 1.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)

func is_busy() -> bool:
	return _busy

func go(scene_path: String, spawn: String = "") -> void:
	if _busy:
		return
	_busy = true
	spawn_point = spawn
	GameState.dialogue_open = true

	var out := create_tween()
	out.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	await out.finished

	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	_place_player()

	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, FADE_TIME)
	await back.finished

	GameState.dialogue_open = false
	_busy = false
	arrived.emit()

func _place_player() -> void:
	if spawn_point == "":
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var marker := scene.find_child(spawn_point, true, false)
	var player := scene.find_child("Player", true, false)
	if marker == null or player == null:
		return
	player.global_position = marker.global_position
	if "last_direction" in player:
		player.last_direction = Vector2.DOWN
