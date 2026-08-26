class_name RodData
extends Resource

@export var display_name: String = "Rod"
@export_multiline var description: String = ""
@export var price: int = 0
@export var tier: int = 0
@export var icon: Texture2D
## Optional turntable animation shown in the shop. Overrides icon when set.
@export var spin: SpriteFrames

## Multiplies the width of the catch zone in the minigame. Higher is easier.
@export var catch_zone: float = 1.0
## Multiplies how much progress each successful hit adds.
@export var reel_power: float = 1.0
## Multiplies the wait before a bite. Lower means fish bite sooner.
@export var bite_speed: float = 1.0
