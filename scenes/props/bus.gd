extends StaticBody2D

## Boarding point for the ride out of the orchard. Needs a clipped-in ticket,
## bought from the driver; hands off to the BusRide cutscene which spends it.

const RIDE := preload("res://scenes/cutscenes/BusRide.tscn")

@onready var zone: Area2D = $InteractZone

var _near: bool = false
var _riding: bool = false


func _ready() -> void:
	zone.body_entered.connect(_on_entered)
	zone.body_exited.connect(_on_exited)


func _on_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near = true
	if GameState.has_ticket:
		GameState.say("Press E to board the bus")
	else:
		GameState.say("You need a ticket from the driver")


func _on_exited(body: Node2D) -> void:
	if body.name == "Player":
		_near = false


func _unhandled_input(event: InputEvent) -> void:
	if not _near or _riding or GameState.dialogue_open or SceneLoader.is_busy():
		return
	if not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if not GameState.has_ticket:
		GameState.say("You need a ticket from the driver")
		return
	_riding = true
	get_tree().current_scene.add_child(RIDE.instantiate())
