extends CanvasLayer

@onready var money_label: Label = $Root/Money
@onready var bag_label: Label = $Root/Bag
@onready var notice_label: Label = $Root/Notice
@onready var effects_label: Label = $Root/Effects
@onready var pouch: CanvasLayer = $Pouch

var _notice_time := 0.0

func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.inventory_changed.connect(_refresh)
	GameState.notice.connect(_on_notice)
	GameState.effects_changed.connect(_refresh)
	pouch.chosen.connect(_on_pouch_chosen)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("bag"):
		return
	if pouch.is_open():
		pouch.close()
	elif not GameState.dialogue_open:
		pouch.open("Pouch", _pouch_note(), _pouch_options())
	get_viewport().set_input_as_handled()


func _pouch_note() -> String:
	if GameState.active_effects.is_empty():
		return "Nothing active"
	var parts: Array = []
	for kind in GameState.active_effects.keys():
		var slot: Dictionary = GameState.active_effects[kind]
		parts.append("%s %ds" % [slot["name"], int(slot["left"])])
	return "Active:  " + "   ".join(parts)


func _pouch_options() -> Array:
	var out: Array = []
	for p in GameState.held_peptides():
		out.append({"text": "%s  x%d" % [p.display_name, GameState.peptides_held(p)], "id": p.resource_path})
	if out.is_empty():
		out.append({"text": "No peptides", "id": "none", "locked": true, "locked_note": "Buy some at the shack"})
	out.append({"text": "Close", "id": "close"})
	return out


func _on_pouch_chosen(id: String) -> void:
	if id == "close" or id == "none":
		pouch.close()
		return
	var item := load(id)
	if item != null and GameState.use_peptide(item):
		pouch.refresh(_pouch_note(), _pouch_options())


func _process(delta: float) -> void:
	if pouch.is_open():
		pouch.refresh(_pouch_note(), _pouch_options())
	if _notice_time > 0.0:
		_notice_time -= delta
		if _notice_time <= 0.0:
			notice_label.text = ""

func _on_money_changed(_total: int) -> void:
	_refresh()

func _on_notice(text: String) -> void:
	notice_label.text = text
	_notice_time = 2.2

func _refresh() -> void:
	money_label.text = "$ %d" % GameState.money
	bag_label.text = "Bag  %d / %d" % [GameState.backpack.size(), GameState.capacity]
	if GameState.active_effects.is_empty():
		effects_label.text = ""
		return
	var parts: Array = []
	for kind in GameState.active_effects.keys():
		var slot: Dictionary = GameState.active_effects[kind]
		parts.append("%s %ds" % [slot["name"], int(slot["left"])])
	effects_label.text = "   ".join(parts)
