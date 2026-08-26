class_name PeptideData
extends Resource

enum Effect { WIDE_ZONE, SLOW_MARKER, DOUBLE_VALUE, FAST_BITE }

@export var display_name: String = "Peptide"
@export_multiline var description: String = ""
@export var price: int = 0
@export var icon: Texture2D
## Optional turntable animation shown in the shop. Overrides icon when set.
@export var spin: SpriteFrames

@export var effect: Effect = Effect.WIDE_ZONE
@export var magnitude: float = 1.5
@export var duration: float = 60.0
