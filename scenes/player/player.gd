extends CharacterBody2D

const DIRECTION_NAMES := ["east", "south_east", "south", "south_west", "west", "north_west", "north", "north_east"]

@export var move_speed: float = 120.0
@export var run_speed: float = 195.0

var can_move: bool = true
var riding: bool = false
var last_direction: Vector2 = Vector2.DOWN

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fishing: Node2D = $FishingComponent


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cast"):
		fishing.on_cast_pressed()


func _physics_process(_delta: float) -> void:
	can_move = not fishing.is_busy() and not riding

	if riding:
		velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO)
		return

	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation(Vector2.ZERO)
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := Input.is_action_pressed("sprint") and direction != Vector2.ZERO

	velocity = direction * (run_speed if running else move_speed)
	move_and_slide()

	sprite.speed_scale = 1.55 if running else 1.0

	if direction != Vector2.ZERO:
		last_direction = direction

	_update_animation(direction)


func _update_animation(direction: Vector2) -> void:
	var facing := _direction_name(last_direction)
	var prefix := "walk" if direction != Vector2.ZERO else "idle"
	if fishing != null:
		var fishing_prefix: String = fishing.animation_prefix()
		if fishing_prefix != "":
			prefix = fishing_prefix

	var anim := "%s_%s" % [prefix, facing]
	if not sprite.sprite_frames.has_animation(anim):
		anim = "idle_%s" % facing

	if sprite.animation != anim:
		sprite.play(anim)
	elif not sprite.is_playing() and sprite.sprite_frames.get_animation_loop(anim):
		sprite.play(anim)


func _direction_name(direction: Vector2) -> String:
	return DIRECTION_NAMES[posmod(roundi(direction.angle() / (PI / 4.0)), 8)]
