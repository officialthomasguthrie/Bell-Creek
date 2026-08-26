extends Node2D

@export var camera_bounds: Rect2 = Rect2()
@export var camera_zoom: float = 1.0
@export var exit_scene: String = ""
@export var exit_spawn: String = ""
## Footstep material for this area, matched against AudioManager.STEPS.
@export var footstep_surface: StringName = &"grass"

func _ready() -> void:
	var cam := find_child("Camera2D", true, false)
	if cam == null:
		return
	if camera_zoom != 1.0:
		cam.zoom = Vector2(camera_zoom, camera_zoom)
	var r := camera_bounds
	if r.size == Vector2.ZERO:
		var layer := _first_layer(self)
		if layer == null or layer.tile_set == null:
			return
		var used := layer.get_used_rect()
		var ts := Vector2(layer.tile_set.tile_size)
		r = Rect2(Vector2(used.position) * ts, Vector2(used.size) * ts)
	cam.limit_left = int(r.position.x)
	cam.limit_top = int(r.position.y)
	cam.limit_right = int(r.position.x + r.size.x)
	cam.limit_bottom = int(r.position.y + r.size.y)

func _unhandled_input(event: InputEvent) -> void:
	if exit_scene == "":
		return
	if GameState.dialogue_open or SceneLoader.is_busy():
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		SceneLoader.go(exit_scene, exit_spawn)


func _first_layer(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node
	for c in node.get_children():
		var found := _first_layer(c)
		if found != null:
			return found
	return null
