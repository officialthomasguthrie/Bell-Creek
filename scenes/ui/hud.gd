extends CanvasLayer

@onready var money_label: Label = $Root/Money
@onready var bag_label: Label = $Root/Bag
@onready var notice_label: Label = $Root/Notice

var _notice_time := 0.0

func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.inventory_changed.connect(_refresh)
	GameState.notice.connect(_on_notice)
	_refresh()

func _process(delta: float) -> void:
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
