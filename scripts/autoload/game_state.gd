extends Node

signal money_changed(total: int)
signal inventory_changed()
signal gear_changed()
signal notice(text: String)
signal effects_changed()

const STARTER_ROD := "res://data/rods/bamboo_rod.tres"
const STARTER_LINE := "res://data/lines/frayed_twine.tres"

var money: int = 0
var capacity: int = 8
var backpack: Array = []
var has_ticket: bool = false
var dialogue_open: bool = false

var owned_rods: Array = []
var owned_lines: Array = []
var equipped_rod: Resource = null
var equipped_line: Resource = null

var bait_stock: Dictionary = {}
var equipped_bait: Resource = null
var peptide_stock: Dictionary = {}
var active_effects: Dictionary = {}

func _ready() -> void:
	var rod := load(STARTER_ROD)
	var line := load(STARTER_LINE)
	if rod != null:
		owned_rods.append(rod)
		equipped_rod = rod
	if line != null:
		owned_lines.append(line)
		equipped_line = line

func _process(delta: float) -> void:
	if active_effects.is_empty():
		return
	for kind in active_effects.keys():
		var slot: Dictionary = active_effects[kind]
		slot["left"] = float(slot["left"]) - delta
		if float(slot["left"]) <= 0.0:
			notice.emit("%s wore off" % str(slot["name"]))
			active_effects.erase(kind)
			effects_changed.emit()


func use_peptide(item: Resource) -> bool:
	if peptides_held(item) <= 0:
		return false
	var left := peptides_held(item) - 1
	if left <= 0:
		peptide_stock.erase(item)
	else:
		peptide_stock[item] = left
	active_effects[int(item.effect)] = {
		"mult": float(item.magnitude),
		"left": float(item.duration),
		"total": float(item.duration),
		"name": str(item.display_name),
	}
	inventory_changed.emit()
	effects_changed.emit()
	notice.emit("%s  -  %ds" % [item.display_name, int(item.duration)])
	return true


func effect(kind: int) -> float:
	if active_effects.has(kind):
		return float(active_effects[kind]["mult"])
	return 1.0


func held_peptides() -> Array:
	var out: Array = []
	for k in peptide_stock.keys():
		out.append(k)
	out.sort_custom(func(a, b): return int(a.price) < int(b.price))
	return out


func add_fish(fish: Resource) -> bool:
	if backpack.size() >= capacity:
		return false
	backpack.append(fish)
	inventory_changed.emit()
	return true

func backpack_value() -> int:
	var total := 0
	for f in backpack:
		total += int(f.value)
	return total

func sell_all() -> int:
	var total := int(round(float(backpack_value()) * effect(PeptideData.Effect.DOUBLE_VALUE)))
	backpack.clear()
	money += total
	inventory_changed.emit()
	money_changed.emit(money)
	return total

func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true

func owns(item: Resource) -> bool:
	if item is RodData:
		return owned_rods.has(item)
	if item is LineData:
		return owned_lines.has(item)
	return false

func is_equipped(item: Resource) -> bool:
	return item == equipped_rod or item == equipped_line or item == equipped_bait

func buy(item: Resource) -> bool:
	var cost := int(item.price)
	if money < cost:
		notice.emit("Not enough money")
		return false
	if (item is RodData or item is LineData) and owns(item):
		notice.emit("You already own that")
		return false
	if not spend(cost):
		return false
	if item is RodData:
		owned_rods.append(item)
		equip(item)
	elif item is LineData:
		owned_lines.append(item)
		equip(item)
	elif item is BaitData:
		bait_stock[item] = int(bait_stock.get(item, 0)) + int(item.casts)
		if equipped_bait == null:
			equipped_bait = item
	elif item is PeptideData:
		peptide_stock[item] = int(peptide_stock.get(item, 0)) + 1
	inventory_changed.emit()
	gear_changed.emit()
	return true

func equip(item: Resource) -> void:
	if item is RodData and owned_rods.has(item):
		equipped_rod = item
	elif item is LineData and owned_lines.has(item):
		equipped_line = item
	elif item is BaitData and int(bait_stock.get(item, 0)) > 0:
		equipped_bait = item
	else:
		return
	gear_changed.emit()

func consume_bait() -> void:
	if equipped_bait == null:
		return
	var left := int(bait_stock.get(equipped_bait, 0)) - 1
	if left <= 0:
		bait_stock.erase(equipped_bait)
		notice.emit("Out of %s" % equipped_bait.display_name)
		equipped_bait = null
	else:
		bait_stock[equipped_bait] = left
	inventory_changed.emit()

func bait_left(item: Resource) -> int:
	return int(bait_stock.get(item, 0))

func peptides_held(item: Resource) -> int:
	return int(peptide_stock.get(item, 0))

func say(text: String) -> void:
	notice.emit(text)
