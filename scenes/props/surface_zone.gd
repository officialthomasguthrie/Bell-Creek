extends Area2D

## Overrides the area's footstep material while the player is standing inside.
## Used for wooden structures sitting on top of a grass area, like the bridge.
@export var surface: StringName = &"wood"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("push_surface"):
		body.push_surface(surface)


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("pop_surface"):
		body.pop_surface(surface)
