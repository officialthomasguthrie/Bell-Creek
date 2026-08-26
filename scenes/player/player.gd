extends CharacterBody2D

const DIRECTION_NAMES := ["east", "south_east", "south", "south_west", "west", "north_west", "north", "north_east"]

@export var move_speed: float = 120.0
@export var run_speed: float = 195.0

var can_move: bool = true
var riding: bool = false
var last_direction: Vector2 = Vector2.DOWN

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fishing: Node2D = $FishingComponent

var _step_cooldown := 0.0
var _surface: StringName = &""


func _ready() -> void:
	sprite.frame_changed.connect(_on_frame_changed)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.dialogue_open:
		return
	if event.is_action_pressed("cast"):
		fishing.on_cast_pressed()
	elif event.is_action_pressed("teleport_shack"):
		_warp_to_shack()


func _physics_process(delta: float) -> void:
	_step_cooldown = maxf(_step_cooldown - delta, 0.0)
	can_move = not fishing.is_busy() and not riding and not GameState.dialogue_open

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

	if direction != Vector2.ZERO:
		last_direction = direction

	_update_animation(direction, running)


func _warp_to_shack() -> void:
	if fishing.is_busy():
		GameState.say("Reel in first")
		return
	if riding:
		GameState.say("Step off the boat first")
		return
	var shack := get_tree().current_scene.find_child("Shack", true, false)
	if shack == null:
		GameState.say("No shack in this area")
		return
	global_position = shack.global_position + Vector2(0, 34)
	last_direction = Vector2.UP
	velocity = Vector2.ZERO
	GameState.say("Back at the shack")


func _update_animation(direction: Vector2, running: bool = false) -> void:
	var facing := _direction_name(last_direction)
	var prefix := "idle"
	if direction != Vector2.ZERO:
		prefix = "run" if running else "walk"
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


func _on_frame_changed() -> void:
	if _step_cooldown > 0.0:
		return
	var anim: String = sprite.animation
	if anim.begins_with("run_"):
		if sprite.frame % 2 != 0:
			return
		AudioManager.play_footstep(true, _current_surface())
	elif anim.begins_with("walk_"):
		if sprite.frame % 3 != 0:
			return
		AudioManager.play_footstep(false, _current_surface())
	else:
		return
	_step_cooldown = 0.09


func _current_surface() -> StringName:
	if _surface != &"":
		return _surface
	_surface = &"grass"
	# Walk up to the owning area rather than trusting current_scene, so the
	# surface still resolves when the area is nested under another node.
	var node: Node = get_parent()
	while node != null:
		var value = node.get("footstep_surface")
		if value != null:
			_surface = StringName(value)
			break
		node = node.get_parent()
	return _surface


func _direction_name(direction: Vector2) -> String:
	return DIRECTION_NAMES[posmod(roundi(direction.angle() / (PI / 4.0)), 8)]
