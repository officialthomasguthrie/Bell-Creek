extends CharacterBody2D

const DIRECTION_NAMES := ["east", "south_east", "south", "south_west", "west", "north_west", "north", "north_east"]

@export var max_speed: float = 92.0
@export var acceleration: float = 130.0
@export var drag: float = 70.0
@export var turn_rate: float = 5.0
@export var seat_offset: Vector2 = Vector2(0, -14)

var occupied: bool = false
var facing: Vector2 = Vector2.UP

var _rider: Node2D = null
var _layer: TileMapLayer = null
var _water: int = -1
var _near: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var zone: Area2D = $InteractZone

func _ready() -> void:
	zone.body_entered.connect(_on_entered)
	zone.body_exited.connect(_on_exited)
	_refresh_sprite()

func _on_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near = true
	if not occupied:
		GameState.say("Press E to get in the boat")

func _on_exited(body: Node2D) -> void:
	if body.name == "Player":
		_near = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if occupied:
		_disembark()
	elif _near:
		_board(zone.get_overlapping_bodies())

func _physics_process(delta: float) -> void:
	if not occupied:
		return

	if _rider != null and _rider.fishing.is_busy():
		velocity = velocity.move_toward(Vector2.ZERO, drag * 2.0 * delta)
		_drift(delta)
		_seat_rider()
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		velocity = velocity.move_toward(input * max_speed, acceleration * delta)
		facing = facing.slerp(input.normalized(), clampf(turn_rate * delta, 0.0, 1.0))
	else:
		velocity = velocity.move_toward(Vector2.ZERO, drag * delta)
	_drift(delta)
	_refresh_sprite()
	_seat_rider()

func _drift(delta: float) -> void:
	var step := velocity * delta
	if step == Vector2.ZERO:
		return
	if _sailable(global_position + step):
		global_position += step
		return
	if _sailable(global_position + Vector2(step.x, 0.0)):
		global_position += Vector2(step.x, 0.0)
		velocity.y = 0.0
		return
	if _sailable(global_position + Vector2(0.0, step.y)):
		global_position += Vector2(0.0, step.y)
		velocity.x = 0.0
		return
	velocity = Vector2.ZERO

func _seat_rider() -> void:
	if _rider == null:
		return
	_rider.global_position = global_position + seat_offset
	_rider.last_direction = facing


func _refresh_sprite() -> void:
	var anim: String = DIRECTION_NAMES[posmod(roundi(facing.angle() / (PI / 4.0)), 8)]
	if sprite.animation != anim:
		sprite.play(anim)

func _board(bodies: Array) -> void:
	for b in bodies:
		if b.name != "Player":
			continue
		occupied = true
		_rider = b
		b.riding = true
		b.z_index = 1
		b.get_node("CollisionShape2D").set_deferred("disabled", true)
		b.last_direction = facing
		b.global_position = global_position + seat_offset
		velocity = Vector2.ZERO
		GameState.say("Rowing  -  Space to fish, E near land to get out")
		return

func _disembark() -> void:
	if _rider != null and _rider.fishing.is_busy():
		GameState.say("Reel in first")
		return
	var shore := _find_shore()
	if shore == Vector2.INF:
		GameState.say("Row closer to land to get out")
		return
	occupied = false
	velocity = Vector2.ZERO
	_rider.riding = false
	_rider.z_index = 0
	_rider.get_node("CollisionShape2D").set_deferred("disabled", false)
	_rider.global_position = shore
	_rider = null
	GameState.say("Back on dry land")

func _find_shore() -> Vector2:
	var layer := _ground()
	if layer == null:
		return Vector2.INF
	var here := layer.local_to_map(layer.to_local(global_position))
	var best := Vector2.INF
	var best_d := 1e20
	for ring in range(1, 4):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if absi(dx) != ring and absi(dy) != ring:
					continue
				var cell := here + Vector2i(dx, dy)
				var td := layer.get_cell_tile_data(cell)
				if td == null or td.get_collision_polygons_count(0) > 0:
					continue
				var world := layer.to_global(layer.map_to_local(cell))
				var d := world.distance_to(global_position)
				if d < best_d:
					best_d = d
					best = world
		if best != Vector2.INF:
			return best
	return best

func _sailable(pos: Vector2) -> bool:
	var layer := _ground()
	if layer == null:
		return false
	var cell := layer.local_to_map(layer.to_local(pos))
	var td := layer.get_cell_tile_data(cell)
	if td == null:
		return false
	if td.terrain_set < 0:
		return true
	var n := 0
	for nb in [TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
			TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER]:
		if td.get_terrain_peering_bit(nb) == _water:
			n += 1
	return n >= 3

func _ground() -> TileMapLayer:
	if _layer == null or not is_instance_valid(_layer):
		_layer = _search(get_tree().current_scene)
		if _layer != null:
			var ts := _layer.tile_set
			for i in range(ts.get_terrains_count(0)):
				if ts.get_terrain_name(0, i).to_lower().contains("water"):
					_water = i
	return _layer

func _search(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node
	for c in node.get_children():
		var found := _search(c)
		if found != null:
			return found
	return null
