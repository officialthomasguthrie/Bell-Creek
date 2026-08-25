extends Node2D

signal state_changed(new_state: int)

enum State { IDLE, CASTING, WAITING, BITE, MINIGAME }

const BOBBER_SCENE := preload("res://scenes/fishing/Bobber.tscn")
const MINIGAME_SCENE := preload("res://scenes/fishing/FishingMinigame.tscn")

@export var fish_table: Array[Resource] = []
@export var cast_time: float = 0.80
@export var min_wait: float = 1.2
@export var max_wait: float = 3.6
@export var bite_window: float = 0.9
@export var max_cast_tiles: int = 4

var state: int = State.IDLE

var _timer := 0.0
var _hooked: Resource = null
var _bobber: Node2D = null
var _game: CanvasLayer = null
var _layer: TileMapLayer = null

func _process(delta: float) -> void:
	match state:
		State.CASTING:
			_timer -= delta
			if _timer <= 0.0:
				_start_waiting()
		State.WAITING:
			_timer -= delta
			if _timer <= 0.0:
				_start_bite()
		State.BITE:
			_timer -= delta
			if _timer <= 0.0:
				_lose("It spat the hook")

func on_cast_pressed() -> void:
	match state:
		State.IDLE:
			_try_cast()
		State.WAITING:
			_reel_in()
		State.BITE:
			_open_minigame()
		State.MINIGAME:
			if _game != null and is_instance_valid(_game):
				_game.attempt()

func is_busy() -> bool:
	return state != State.IDLE

func animation_prefix() -> String:
	match state:
		State.CASTING:
			return "cast"
		State.WAITING, State.BITE, State.MINIGAME:
			return "fishing"
	return ""

func _try_cast() -> void:
	var target := _find_water()
	if target == Vector2.INF:
		GameState.say("You need to face the water")
		return
	if GameState.backpack.size() >= GameState.capacity:
		GameState.say("Your bag is full")
		return
	_hooked = _roll_fish()
	if _hooked == null:
		GameState.say("Nothing is biting here")
		return
	_bobber = BOBBER_SCENE.instantiate()
	get_parent().get_parent().add_child(_bobber)
	_bobber.global_position = target
	_set_state(State.CASTING)
	_timer = cast_time
	GameState.say("Casting...")

func _start_waiting() -> void:
	_set_state(State.WAITING)
	_timer = randf_range(min_wait, max_wait)
	GameState.say("Waiting for a bite")

func _start_bite() -> void:
	_set_state(State.BITE)
	_timer = bite_window
	if _bobber != null:
		_bobber.dip()
	GameState.say("BITE!  Press Space")

func _open_minigame() -> void:
	_set_state(State.MINIGAME)
	if _bobber != null:
		_bobber.settle()
	_game = MINIGAME_SCENE.instantiate()
	get_tree().current_scene.add_child(_game)
	_game.finished.connect(_on_minigame_finished)
	_game.setup(_hooked)

func _on_minigame_finished(success: bool) -> void:
	if success:
		var name_text: String = str(_hooked.display_name)
		if GameState.add_fish(_hooked):
			GameState.say("Caught a %s!  (+%d when sold)" % [name_text, int(_hooked.value)])
		else:
			GameState.say("Your bag is full")
	else:
		GameState.say("It got away")
	_clear()

func _reel_in() -> void:
	GameState.say("Reeled in")
	_clear()

func _lose(reason: String) -> void:
	GameState.say(reason)
	_clear()

func _clear() -> void:
	_game = null
	if _bobber != null:
		_bobber.queue_free()
		_bobber = null
	_hooked = null
	_timer = 0.0
	_set_state(State.IDLE)

func _set_state(s: int) -> void:
	state = s
	state_changed.emit(s)

func _roll_fish() -> Resource:
	if fish_table.is_empty():
		return null
	var total := 0.0
	for f in fish_table:
		total += float(f.rarity_weight)
	var roll := randf() * total
	for f in fish_table:
		roll -= float(f.rarity_weight)
		if roll <= 0.0:
			return f
	return fish_table[0]

func _find_water() -> Vector2:
	var layer := _ground_layer()
	if layer == null:
		return Vector2.INF
	var origin: Vector2 = get_parent().global_position
	var dir: Vector2 = get_parent().last_direction.normalized()
	for step in range(1, max_cast_tiles + 1):
		var probe: Vector2 = origin + dir * (float(step) * 32.0)
		var cell: Vector2i = layer.local_to_map(layer.to_local(probe))
		var data := layer.get_cell_tile_data(cell)
		if data != null and data.get_collision_polygons_count(0) > 0:
			return layer.to_global(layer.map_to_local(cell))
	return Vector2.INF

func _ground_layer() -> TileMapLayer:
	if _layer == null or not is_instance_valid(_layer):
		_layer = _search(get_tree().current_scene)
	return _layer

func _search(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node
	for c in node.get_children():
		var found := _search(c)
		if found != null:
			return found
	return null
