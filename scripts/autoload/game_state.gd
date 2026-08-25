extends Node

signal money_changed(total: int)
signal inventory_changed()
signal notice(text: String)

var money: int = 0
var capacity: int = 8
var backpack: Array = []

func add_fish(fish: Resource) -> bool:
	if backpack.size() >= capacity:
		return false
	backpack.append(fish)
	inventory_changed.emit()
	return true

func sell_all() -> int:
	var total := 0
	for f in backpack:
		total += int(f.value)
	backpack.clear()
	money += total
	inventory_changed.emit()
	money_changed.emit(money)
	return total

func say(text: String) -> void:
	notice.emit(text)
