extends StaticBody2D

const TICKET_PRICE := 200

@onready var zone: Area2D = $InteractZone
@onready var bubble: Node2D = $SpeechBubble

var _near: bool = false

func _ready() -> void:
	zone.body_entered.connect(_on_entered)
	zone.body_exited.connect(_on_exited)
	bubble.chosen.connect(_on_chosen)
	bubble.finished.connect(_on_finished)

func _on_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	_near = true
	GameState.say("Press E to talk to the driver")

func _on_exited(body: Node2D) -> void:
	if body.name == "Player":
		_near = false

func _unhandled_input(event: InputEvent) -> void:
	if not _near or GameState.dialogue_open:
		return
	if event.is_action_pressed("interact"):
		_greet()
		get_viewport().set_input_as_handled()

func _greet() -> void:
	GameState.dialogue_open = true
	bubble.speak("Bus Driver", [
		"Standing about, are we?",
		"Bus don't run itself, you know.",
	], _menu_options())

func _menu_options() -> Array:
	return [
		{"text": "Buy ticket  ($%d)" % TICKET_PRICE, "id": "ticket"},
		{"text": "Why are you so late?", "id": "late"},
		{"text": "Close", "id": "close"},
	]

func _reply(lines: Array) -> void:
	bubble.speak("Bus Driver", lines, _menu_options())

func _on_chosen(id: String) -> void:
	match id:
		"ticket":
			if GameState.has_ticket:
				_reply(["You've already got one, mate.", "Hang onto it."])
			elif GameState.money < TICKET_PRICE:
				_reply(["Two hundred, mate.", "Come back when you're not short."])
			else:
				GameState.spend(TICKET_PRICE)
				GameState.has_ticket = true
				_reply(["Right you are.", "Bus leaves when it leaves."])
		"late":
			_reply(["Didn't get the memo mate!"])
		"close":
			bubble.dismiss()

func _on_finished() -> void:
	GameState.dialogue_open = false
