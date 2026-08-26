extends CharacterBody2D

const DIRECTION_NAMES := ["east", "south_east", "south", "south_west", "west", "north_west", "north", "north_east"]

@export var speed: float = 24.0
@export var walk_seconds: Vector2 = Vector2(0.7, 2.0)
@export var rest_seconds: Vector2 = Vector2(0.8, 2.6)
@export var roam_radius: float = 130.0

var _home: Vector2
var _heading: Vector2 = Vector2.DOWN
var _timer: float = 0.0
var _walking: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_home = global_position
	_rest()

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _walking:
		velocity = _heading * speed
		move_and_slide()
		if get_slide_collision_count() > 0:
			_turn_around()
		elif global_position.distance_to(_home) > roam_radius:
			_heading = global_position.direction_to(_home)
			_snap_heading()
	else:
		velocity = Vector2.ZERO
	if _timer <= 0.0:
		if _walking:
			_rest()
		else:
			_wander()
	_refresh()

func _wander() -> void:
	_walking = true
	_timer = randf_range(walk_seconds.x, walk_seconds.y)
	_heading = Vector2.RIGHT.rotated(randf() * TAU)
	_snap_heading()

func _rest() -> void:
	_walking = false
	_timer = randf_range(rest_seconds.x, rest_seconds.y)

func _turn_around() -> void:
	_heading = -_heading.rotated(randf_range(-0.8, 0.8))
	_snap_heading()

func _snap_heading() -> void:
	var step := posmod(roundi(_heading.angle() / (PI / 4.0)), 8)
	_heading = Vector2.RIGHT.rotated(float(step) * PI / 4.0)

func _refresh() -> void:
	var facing: String = DIRECTION_NAMES[posmod(roundi(_heading.angle() / (PI / 4.0)), 8)]
	var anim := "%s_%s" % ["walk" if _walking else "stand", facing]
	if sprite.animation == anim:
		return
	sprite.animation = anim
	if _walking:
		sprite.play(anim)
	else:
		sprite.stop()
		sprite.frame = 0
