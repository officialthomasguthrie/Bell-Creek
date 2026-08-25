extends CharacterBody2D

@export var move_speed: float = 90.0

var can_move: bool = true

var last_direction: Vector2 = Vector2.DOWN

@onready var sprite = $Sprite2D


func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = direction * move_speed
	move_and_slide()

	if direction != Vector2.ZERO:
		last_direction = direction

	_update_animation(direction)


func _update_animation(direction: Vector2) -> void:
	var moving := direction != Vector2.ZERO
	var facing := last_direction

	if absf(facing.x) > absf(facing.y):
		sprite.flip_h = facing.x < 0.0
		_play("walk_side" if moving else "idle_side")
	elif facing.y < 0.0:
		sprite.flip_h = false
		_play("walk_up" if moving else "idle_up")
	else:
		sprite.flip_h = false
		_play("walk_down" if moving else "idle_down")


func _play(anim_name: String) -> void:
	if sprite is AnimatedSprite2D and sprite.sprite_frames != null:
		if sprite.sprite_frames.has_animation(anim_name) and sprite.animation != anim_name:
			sprite.play(anim_name)
