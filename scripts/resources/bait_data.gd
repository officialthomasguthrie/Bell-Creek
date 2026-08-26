class_name BaitData
extends Resource

@export var display_name: String = "Bait"
@export_multiline var description: String = ""
@export var price: int = 0
@export var icon: Texture2D
## Optional turntable animation shown in the shop. Overrides icon when set.
@export var spin: SpriteFrames

## Shifts the odds toward rarer fish. 0 = no change, 1 = strong pull.
@export var rarity_pull: float = 0.0
## How many casts one purchase covers.
@export var casts: int = 10
