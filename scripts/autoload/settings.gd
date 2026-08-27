extends Node

const PATH := "user://settings.cfg"

signal changed()

var music: float = 0.75
var sfx: float = 0.85
var fullscreen: bool = false

func _ready() -> void:
	_load()
	apply()

func set_music(value: float) -> void:
	music = clampf(value, 0.0, 1.0)
	_apply_bus("Music", music)
	_save()
	changed.emit()

func set_sfx(value: float) -> void:
	sfx = clampf(value, 0.0, 1.0)
	_apply_bus("SFX", sfx)
	_save()
	changed.emit()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_window()
	_save()
	changed.emit()

func apply() -> void:
	_apply_bus("Music", music)
	_apply_bus("SFX", sfx)
	_apply_window()

func _apply_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, value <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.001)))

func _apply_window() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	music = clampf(float(cfg.get_value("audio", "music", music)), 0.0, 1.0)
	sfx = clampf(float(cfg.get_value("audio", "sfx", sfx)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("video", "fullscreen", fullscreen))

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.save(PATH)
