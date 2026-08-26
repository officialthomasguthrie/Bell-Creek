extends StaticBody2D

const TICKET_PRICE := 200

@onready var zone: Area2D = $InteractZone
@onready var dialogue: CanvasLayer = $DialogueBox

var _near: bool = false
var _talking: bool = false

func _ready() -> void:
	zone.body_entered.connect(_on_entered)
	zone.body_exited.connect(_on_exited)
	dialogue.chosen.connect(_on_chosen)
	dialogue.closed.connect(_on_closed)

func _on_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near = true
	GameState.say("Press E to talk to the driver")

func _on_exited(body: Node2D) -> void:
	if body.name == "Player":
		_near = false

func _unhandled_input(event: InputEvent) -> void:
	if _talking or not _near:
		return
	if event.is_action_pressed("interact"):
		_talking = true
		_menu("Standing about, are we?")
		get_viewport().set_input_as_handled()

func _menu(line: String) -> void:
	dialogue.show_dialogue("Bus Driver", line, [
		{"text": "Buy ticket  ($%d)" % TICKET_PRICE, "id": "ticket"},
		{"text": "Ask why he's so late", "id": "late"},
		{"text": "Close", "id": "close"},
	])

func _on_chosen(id: String) -> void:
	match id:
		"ticket":
			if GameState.has_ticket:
				_menu("You've already got one, mate. Hang onto it.")
			elif GameState.money < TICKET_PRICE:
				_menu("Two hundred, mate. Come back when you're not short.")
			else:
				GameState.spend(TICKET_PRICE)
				GameState.has_ticket = true
				_menu("Right you are. Bus leaves when it leaves.")
		"late":
			_menu("Didn't get the memo mate!")
		"close":
			dialogue.close()

func _on_closed() -> void:
	_talking = false
