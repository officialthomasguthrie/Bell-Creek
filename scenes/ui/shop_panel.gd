extends CanvasLayer

signal closed()

const SPIN_FPS := 12.0

const CATEGORIES := [
	{"name": "Rods",     "dir": "res://data/rods"},
	{"name": "Lines",    "dir": "res://data/lines"},
	{"name": "Bait",     "dir": "res://data/bait"},
	{"name": "Peptides", "dir": "res://data/peptides"},
]

const SFX_BUY := preload("res://assets/audio/sfx/buy.wav")
const SFX_DENY := preload("res://assets/audio/sfx/deny.wav")
const SFX_EQUIP := preload("res://assets/audio/sfx/equip.wav")

@onready var money_label: Label = $Root/Centre/Panel/Margin/Rows/Header/Money
@onready var tabs_box: HBoxContainer = $Root/Centre/Panel/Margin/Rows/Tabs
@onready var left_arrow: Label = $Root/Centre/Panel/Margin/Rows/Body/LeftArrow
@onready var right_arrow: Label = $Root/Centre/Panel/Margin/Rows/Body/RightArrow
@onready var showcase: TextureRect = $Root/Centre/Panel/Margin/Rows/Body/Showcase/Art
@onready var counter_label: Label = $Root/Centre/Panel/Margin/Rows/Body/Showcase/Counter
@onready var name_label: Label = $Root/Centre/Panel/Margin/Rows/Body/Detail/ItemName
@onready var price_label: Label = $Root/Centre/Panel/Margin/Rows/Body/Detail/Price
@onready var desc_label: Label = $Root/Centre/Panel/Margin/Rows/Body/Detail/Desc
@onready var stats_label: Label = $Root/Centre/Panel/Margin/Rows/Body/Detail/Stats

var _catalogue: Dictionary = {}
var _cat := 0
var _index := 0
var _open := false
var _spin_time := 0.0

var _tab_plain: StyleBoxFlat
var _tab_pick: StyleBoxFlat

func _ready() -> void:
	hide()
	_build_styles()
	_load_catalogue()
	GameState.money_changed.connect(_on_state_changed)
	GameState.inventory_changed.connect(_on_state_changed)
	for c in CATEGORIES:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 8)
		tabs_box.add_child(l)

func is_open() -> bool:
	return _open

func open() -> void:
	_open = true
	_cat = 0
	_index = 0
	_spin_time = 0.0
	GameState.dialogue_open = true
	show()
	_paint()

func close() -> void:
	if not _open:
		return
	_open = false
	hide()
	GameState.dialogue_open = false
	closed.emit()

func _process(delta: float) -> void:
	if not _open:
		return
	var item := current_item()
	if item == null or item.spin == null:
		return
	_spin_time += delta
	var frames: SpriteFrames = item.spin
	var names: PackedStringArray = frames.get_animation_names()
	if names.is_empty():
		return
	var anim: String = names[0]
	var count := frames.get_frame_count(anim)
	if count <= 1:
		return
	showcase.texture = frames.get_frame_texture(anim, int(_spin_time * SPIN_FPS) % count)

func _on_state_changed(_a = null) -> void:
	if _open:
		_paint()

func _build_styles() -> void:
	_tab_plain = StyleBoxFlat.new()
	_tab_plain.bg_color = Color(0.12, 0.14, 0.13, 1)
	_tab_plain.set_corner_radius_all(2)
	_tab_plain.content_margin_left = 5.0
	_tab_plain.content_margin_right = 5.0
	_tab_plain.content_margin_top = 2.0
	_tab_plain.content_margin_bottom = 2.0
	_tab_pick = _tab_plain.duplicate()
	_tab_pick.bg_color = Color(0.26, 0.22, 0.13, 1)

func _load_catalogue() -> void:
	for c in CATEGORIES:
		var list: Array = []
		var dir := DirAccess.open(str(c["dir"]))
		if dir != null:
			for fn in dir.get_files():
				if not fn.ends_with(".tres"):
					continue
				var r := load(str(c["dir"]) + "/" + fn)
				if r != null:
					list.append(r)
		list.sort_custom(func(a, b): return int(a.price) < int(b.price))
		_catalogue[str(c["name"])] = list

func _items() -> Array:
	return _catalogue[CATEGORIES[_cat]["name"]]

func current_item() -> Resource:
	var list := _items()
	if list.is_empty():
		return null
	return list[clampi(_index, 0, list.size() - 1)]

func _paint() -> void:
	money_label.text = "$%d" % GameState.money
	for i in range(tabs_box.get_child_count()):
		var t: Label = tabs_box.get_child(i)
		var picked: bool = i == _cat
		t.text = "[%d] %s" % [i + 1, CATEGORIES[i]["name"]]
		t.add_theme_color_override("font_color", Color(1, 0.86, 0.45) if picked else Color(0.46, 0.49, 0.46))
		t.add_theme_stylebox_override("normal", _tab_pick if picked else _tab_plain)

	var list := _items()
	var item := current_item()
	left_arrow.modulate = Color(1, 1, 1, 1.0 if _index > 0 else 0.22)
	right_arrow.modulate = Color(1, 1, 1, 1.0 if _index < list.size() - 1 else 0.22)
	counter_label.text = "" if list.is_empty() else "%d / %d" % [_index + 1, list.size()]

	if item == null:
		showcase.texture = null
		name_label.text = ""
		price_label.text = ""
		desc_label.text = ""
		stats_label.text = ""
		return

	_spin_time = 0.0
	if item.spin != null:
		var names: PackedStringArray = item.spin.get_animation_names()
		if not names.is_empty():
			showcase.texture = item.spin.get_frame_texture(names[0], 0)
	else:
		showcase.texture = item.icon

	name_label.text = str(item.display_name)
	price_label.text = _price_line(item)
	price_label.add_theme_color_override("font_color",
		Color(0.55, 0.85, 0.55) if _held(item) else (Color(0.95, 0.85, 0.55) if GameState.money >= int(item.price) else Color(0.82, 0.46, 0.42)))
	desc_label.text = str(item.description)
	stats_label.text = _stats(item)

func _held(item: Resource) -> bool:
	if item is RodData or item is LineData:
		return GameState.owns(item)
	if item is BaitData:
		return GameState.bait_left(item) > 0
	if item is PeptideData:
		return GameState.peptides_held(item) > 0
	return false

func _price_line(item: Resource) -> String:
	if GameState.is_equipped(item):
		return "Equipped"
	if (item is RodData or item is LineData) and GameState.owns(item):
		return "Owned"
	if item is BaitData and GameState.bait_left(item) > 0:
		return "$%d      %d casts left" % [int(item.price), GameState.bait_left(item)]
	if item is PeptideData and GameState.peptides_held(item) > 0:
		return "$%d      %d in the pouch" % [int(item.price), GameState.peptides_held(item)]
	return "$%d" % int(item.price)

func _action_for(item: Resource) -> String:
	if item == null:
		return "none"
	if item is RodData or item is LineData:
		if GameState.is_equipped(item):
			return "none"
		return "equip" if GameState.owns(item) else "buy"
	if item is BaitData:
		if GameState.bait_left(item) > 0 and not GameState.is_equipped(item):
			return "equip"
		return "buy"
	return "buy"

func _stats(item: Resource) -> String:
	if item is RodData:
		return "Catch zone   %s\nReel power   %s\nBite speed   %s" % [
			_delta(item.catch_zone, GameState.equipped_rod, "catch_zone"),
			_delta(item.reel_power, GameState.equipped_rod, "reel_power"),
			_delta(item.bite_speed, GameState.equipped_rod, "bite_speed", true)]
	if item is LineData:
		return "Strength     %s\nSteadiness   %s" % [
			_delta(item.strength, GameState.equipped_line, "strength"),
			_delta(item.steadiness, GameState.equipped_line, "steadiness", true)]
	if item is BaitData:
		return "Rare chance  +%d%%\nCasts        %d" % [int(item.rarity_pull * 100.0), int(item.casts)]
	if item is PeptideData:
		return "Strength     x%.2f\nDuration     %d seconds" % [item.magnitude, int(item.duration)]
	return ""

func _delta(value: float, against: Resource, prop: String, lower_is_better: bool = false) -> String:
	var text := "%.2f" % value
	if against == null:
		return text
	var other: float = float(against.get(prop))
	if is_equal_approx(value, other):
		return text
	var better: bool = value < other if lower_is_better else value > other
	return text + ("   Better" if better else "   Worse")

func _activate() -> void:
	var item := current_item()
	if item == null:
		return
	match _action_for(item):
		"equip":
			GameState.equip(item)
			GameState.say("Equipped %s" % item.display_name)
			AudioManager.play_sfx(SFX_EQUIP, 1.0, -8.0)
		"buy":
			if GameState.buy(item):
				GameState.say("Bought %s for $%d" % [item.display_name, int(item.price)])
				AudioManager.play_sfx(SFX_BUY, randf_range(0.97, 1.03), -6.0)
			else:
				AudioManager.play_sfx(SFX_DENY, 1.0, -8.0)
		_:
			AudioManager.play_sfx(SFX_DENY, 1.0, -12.0)
	_paint()

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("pause"):
		close()
	elif event.is_action_pressed("slot_1"):
		_go_to_tab(0)
	elif event.is_action_pressed("slot_2"):
		_go_to_tab(1)
	elif event.is_action_pressed("slot_3"):
		_go_to_tab(2)
	elif event.is_action_pressed("slot_4"):
		_go_to_tab(3)
	elif event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
		if _index > 0:
			_index -= 1
			_paint()
	elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
		if _index < _items().size() - 1:
			_index += 1
			_paint()
	elif event.is_action_pressed("interact") or event.is_action_pressed("cast"):
		_activate()
	else:
		return
	get_viewport().set_input_as_handled()

func _go_to_tab(i: int) -> void:
	if i < 0 or i >= CATEGORIES.size() or i == _cat:
		return
	_cat = i
	_index = 0
	_paint()
