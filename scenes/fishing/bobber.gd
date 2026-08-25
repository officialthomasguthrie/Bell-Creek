extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var _t := 0.0
var _dipping := false

func _process(delta: float) -> void:
	_t += delta
	if _dipping:
		sprite.position.y = sin(_t * 34.0) * 3.0
	else:
		sprite.position.y = sin(_t * 3.0) * 1.5

func dip() -> void:
	_dipping = true
	_t = 0.0

func settle() -> void:
	_dipping = false
