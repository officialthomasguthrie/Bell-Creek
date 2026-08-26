extends StaticBody2D

@export_enum("shop", "cash") var kind: String = "shop"
@export var label: String = "Counter"

@onready var zone: Area2D = $InteractZone

var _near: bool = false

func _ready() -> void:
	zone.body_entered.connect(_on_entered)
	zone.body_exited.connect(_on_exited)

func _on_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near = true
	GameState.say("Press E  -  %s" % label)

func _on_exited(body: Node2D) -> void:
	if body.name == "Player":
		_near = false

func _unhandled_input(event: InputEvent) -> void:
	if not _near or GameState.dialogue_open or SceneLoader.is_busy():
		return
	if not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	match kind:
		"shop":
			var shop := get_tree().current_scene.find_child("ShopPanel", true, false)
			if shop != null:
				shop.open()
		"cash":
			var count := GameState.backpack.size()
			if count == 0:
				GameState.say("Nothing to cash in")
				return
			var earned := GameState.sell_all()
			GameState.say("Sold %d fish for $%d" % [count, earned])
