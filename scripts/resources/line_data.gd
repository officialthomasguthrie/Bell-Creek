class_name LineData
extends Resource

@export var display_name: String = "Line"
@export_multiline var description: String = ""
@export var price: int = 0
@export var tier: int = 0
@export var icon: Texture2D
## Optional turntable animation shown in the shop. Overrides icon when set.
@export var spin: SpriteFrames

## Highest fish difficulty this line can land without snapping.
@export var strength: float = 1.0
## Multiplies the marker speed. Lower is calmer.
@export var steadiness: float = 1.0
