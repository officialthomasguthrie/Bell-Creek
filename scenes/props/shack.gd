extends StaticBody2D

@onready var zone: Area2D = $InteractZone

var _player_near := false

func _ready() -> void:
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	GameState.inventory_changed.connect(_prompt)

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_player_near = true
	_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		_player_near = false

func _prompt() -> void:
	if not _player_near:
		return
	var count := GameState.backpack.size()
	if count == 0:
		GameState.say("Fish Shack  -  nothing to sell")
		return
	var worth := 0
	for f in GameState.backpack:
		worth += int(f.value)
	GameState.say("Press E to sell %d fish for $%d" % [count, worth])

func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or GameState.dialogue_open:
		return
	if not event.is_action_pressed("interact"):
		return
	var count := GameState.backpack.size()
	if count == 0:
		GameState.say("Nothing to sell")
		return
	var earned := GameState.sell_all()
	GameState.say("Sold %d fish for $%d" % [count, earned])
