extends Node

signal money_changed(total: int)
signal inventory_changed()
signal notice(text: String)

var money: int = 0
var capacity: int = 8
var backpack: Array = []
var has_ticket: bool = false
var dialogue_open: bool = false

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

func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true


func say(text: String) -> void:
	notice.emit(text)
