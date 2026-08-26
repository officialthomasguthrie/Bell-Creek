extends StaticBody2D

const INTERIOR := "res://scenes/areas/ShackInterior.tscn"

@onready var zone: Area2D = $InteractZone

var _player_near := false

func _ready() -> void:
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_near = true
	GameState.say("Press E to go inside")

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		_player_near = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or GameState.dialogue_open or SceneLoader.is_busy():
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		SceneLoader.go(INTERIOR, "SpawnInside")
