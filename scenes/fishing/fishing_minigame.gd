extends CanvasLayer

signal finished(success: bool)

const TARGET := 3.0

@onready var bar: ColorRect = $Root/Bar
@onready var zone: ColorRect = $Root/Bar/Zone
@onready var core: ColorRect = $Root/Bar/Core
@onready var marker: ColorRect = $Root/Bar/Marker
@onready var label: Label = $Root/Label

var _pos := 0.0
var _dir := 1.0
var _speed := 0.9
var _zone_centre := 0.5
var _zone_half := 0.16
var _progress := 0.0
var _power := 1.0
var _active := false

func setup(fish: Resource, rod: Resource = null, line: Resource = null) -> void:
	var d: float = float(fish.difficulty)
	var steady: float = 1.0 if line == null else float(line.steadiness)
	var zone_mult: float = 1.0 if rod == null else float(rod.catch_zone)
	_power = 1.0 if rod == null else float(rod.reel_power)
	_speed = (0.70 + 0.40 * d) * steady * GameState.effect(PeptideData.Effect.SLOW_MARKER)
	_zone_half = clampf((0.20 - 0.045 * d) * zone_mult * GameState.effect(PeptideData.Effect.WIDE_ZONE), 0.06, 0.34)
	_zone_centre = randf_range(0.25, 0.75)
	_progress = 0.0
	_active = true
	_refresh()

func _process(delta: float) -> void:
	if not _active:
		return
	_pos += _dir * _speed * delta
	if _pos >= 1.0:
		_pos = 1.0
		_dir = -1.0
	elif _pos <= 0.0:
		_pos = 0.0
		_dir = 1.0
	_refresh()

func attempt() -> void:
	if not _active:
		return
	AudioManager.play_reel_turn()
	var offset := absf(_pos - _zone_centre)
	if offset <= _zone_half * 0.4:
		_land(true)
	elif offset <= _zone_half:
		_land(false)
	else:
		_finish(false)

func _land(perfect: bool) -> void:
	_progress += _power if perfect else _power * 0.6
	if _progress >= TARGET:
		_finish(true)
		return
	_speed *= 1.18
	if not perfect:
		_zone_half = maxf(_zone_half * 0.85, 0.05)
	_zone_centre = randf_range(0.22, 0.78)
	_refresh()

func _finish(success: bool) -> void:
	_active = false
	if not success:
		AudioManager.play_line_snap()
		AudioManager.play_rod_drop(0.2)
	finished.emit(success)
	queue_free()

func _refresh() -> void:
	var w := bar.size.x
	zone.position.x = (_zone_centre - _zone_half) * w
	zone.size.x = _zone_half * 2.0 * w
	core.position.x = (_zone_centre - _zone_half * 0.4) * w
	core.size.x = _zone_half * 0.8 * w
	marker.position.x = _pos * w - marker.size.x * 0.5
	label.text = "%d%%" % int(clampf(_progress / TARGET, 0.0, 1.0) * 100.0)
