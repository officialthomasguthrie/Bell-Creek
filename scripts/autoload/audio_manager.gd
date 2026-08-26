extends Node

const TRACKS := [
	{"file": "ambient_01.mp3", "title": "Ethereal Reverie",   "gain":  0.1},
	{"file": "ambient_02.mp3", "title": "Serenity's Embrace", "gain": -0.7},
	{"file": "ambient_03.mp3", "title": "Distant Echoes",     "gain":  0.5},
	{"file": "ambient_04.mp3", "title": "Celestial Serenade", "gain": -2.3},
	{"file": "ambient_05.mp3", "title": "Infinite Skies",     "gain": -0.3},
	{"file": "ambient_06.mp3", "title": "Whispering Forest",  "gain": -0.7},
	{"file": "ambient_07.mp3", "title": "Shimmering Mirage",  "gain":  1.8},
	{"file": "ambient_08.mp3", "title": "Lost in Time",       "gain": -3.4},
	{"file": "ambient_09.mp3", "title": "Mystic Dreamscape",  "gain": -1.8},
	{"file": "ambient_10.mp3", "title": "Enchanted Horizons", "gain": -0.6},
]

const LINE_SNAP := preload("res://assets/audio/sfx/line_snap.wav")
const CAST_WHOOSH := preload("res://assets/audio/sfx/cast_whoosh.wav")
const WATER_SPLASH := preload("res://assets/audio/sfx/water_splash.wav")
const REEL_TURN := preload("res://assets/audio/sfx/reel_turn.wav")
const ROD_DROP := preload("res://assets/audio/sfx/rod_drop.wav")
const WATER_LOOP := preload("res://assets/audio/sfx/water_loop.wav")

## Footstep banks keyed by surface. Every clip is loudness-matched to the others,
## so the surfaces stay level with each other and only the material changes.
const STEPS := {
	&"grass": {
		&"walk": [preload("res://assets/audio/sfx/steps/grass_walk_1.wav")],
		&"run": [
			preload("res://assets/audio/sfx/steps/grass_run_1.wav"),
			preload("res://assets/audio/sfx/steps/grass_run_2.wav"),
			preload("res://assets/audio/sfx/steps/grass_run_3.wav"),
		],
	},
	&"wood": {
		&"walk": [
			preload("res://assets/audio/sfx/steps/wood_walk_1.wav"),
			preload("res://assets/audio/sfx/steps/wood_walk_2.wav"),
			preload("res://assets/audio/sfx/steps/wood_walk_3.wav"),
			preload("res://assets/audio/sfx/steps/wood_walk_4.wav"),
		],
		&"run": [
			preload("res://assets/audio/sfx/steps/wood_run_1.wav"),
			preload("res://assets/audio/sfx/steps/wood_run_2.wav"),
			preload("res://assets/audio/sfx/steps/wood_run_3.wav"),
			preload("res://assets/audio/sfx/steps/wood_run_4.wav"),
		],
	},
}

@export var music_db: float = -9.0
@export var line_snap_db: float = -6.0
@export var walk_step_db: float = -18.0
@export var run_step_db: float = -14.0
@export var cast_whoosh_db: float = -14.0
@export var water_splash_db: float = -12.0
@export var reel_turn_db: float = -16.0
@export var rod_drop_db: float = -10.0
@export var water_loop_db: float = -7.0
@export var water_fade: float = 0.6
@export var fade_in: float = 2.5
@export var gap: float = 1.5

var _music: AudioStreamPlayer
var _water: AudioStreamPlayer
var _water_tween: Tween
var _sfx: Array[AudioStreamPlayer] = []
var _order: Array = []
var _at: int = 0
var _waiting: float = 0.0

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_music.finished.connect(_on_track_finished)
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx.append(p)
	_water = AudioStreamPlayer.new()
	_water.bus = "SFX"
	_water.stream = WATER_LOOP
	add_child(_water)
	_reshuffle()
	_play_current()

func _process(delta: float) -> void:
	if _waiting <= 0.0:
		return
	_waiting -= delta
	if _waiting <= 0.0:
		_play_current()

func current_title() -> String:
	if _order.is_empty():
		return ""
	return str(TRACKS[_order[_at]]["title"])

func play_sfx(stream: AudioStream, pitch: float = 1.0, db: float = 0.0) -> void:
	if stream == null:
		return
	for p in _sfx:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.volume_db = db
			p.play()
			return

func play_line_snap() -> void:
	play_sfx(LINE_SNAP, 1.0, line_snap_db)

func play_footstep(running: bool, surface: StringName = &"grass") -> void:
	var bank: Dictionary = STEPS.get(surface, STEPS[&"grass"])
	var clips: Array = bank[&"run" if running else &"walk"]
	if clips.is_empty():
		return
	var pitch := randf_range(0.94, 1.06) if running else randf_range(0.92, 1.08)
	play_sfx(clips[randi() % clips.size()], pitch, run_step_db if running else walk_step_db)


func play_cast_whoosh() -> void:
	play_sfx(CAST_WHOOSH, randf_range(0.97, 1.03), cast_whoosh_db)


func play_water_splash() -> void:
	play_sfx(WATER_SPLASH, randf_range(0.97, 1.03), water_splash_db)


func play_reel_turn() -> void:
	play_sfx(REEL_TURN, randf_range(0.95, 1.05), reel_turn_db)


func play_rod_drop(delay: float = 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	play_sfx(ROD_DROP, randf_range(0.97, 1.03), rod_drop_db)


func start_water_loop() -> void:
	if _water == null or _water.playing:
		return
	_kill_water_tween()
	_water.volume_db = water_loop_db - 18.0
	_water.play()
	_water_tween = create_tween()
	_water_tween.tween_property(_water, "volume_db", water_loop_db, water_fade)


func stop_water_loop() -> void:
	if _water == null or not _water.playing:
		return
	_kill_water_tween()
	_water_tween = create_tween()
	_water_tween.tween_property(_water, "volume_db", water_loop_db - 24.0, water_fade)
	_water_tween.tween_callback(_water.stop)


func _kill_water_tween() -> void:
	if _water_tween != null and _water_tween.is_valid():
		_water_tween.kill()
	_water_tween = null

func skip() -> void:
	_music.stop()
	_on_track_finished()

func _on_track_finished() -> void:
	_at += 1
	if _at >= _order.size():
		_reshuffle()
		_at = 0
	_waiting = gap

func _reshuffle() -> void:
	_order = range(TRACKS.size())
	_order.shuffle()

func _play_current() -> void:
	var track: Dictionary = TRACKS[_order[_at]]
	var stream := load("res://assets/audio/music/" + str(track["file"]))
	if stream == null:
		return
	_music.stream = stream
	_music.volume_db = music_db + float(track["gain"]) - 24.0
	_music.play()
	var target: float = music_db + float(track["gain"])
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", target, fade_in)
