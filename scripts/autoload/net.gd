extends Node

const PORT := 7717
const GHOST := preload("res://scenes/player/Player.tscn")
const RATE := 1.0 / 15.0

var online: bool = false

var _ghosts: Dictionary = {}
var _clock: float = 0.0


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_drop)
	multiplayer.connection_failed.connect(func(): _stop("Could not reach that host"))
	multiplayer.server_disconnected.connect(func(): _stop("The host left"))


func host() -> bool:
	var peer := ENetMultiplayerPeer.new()
	return _use(peer, peer.create_server(PORT, 3))


func join(ip: String) -> bool:
	var peer := ENetMultiplayerPeer.new()
	return _use(peer, peer.create_client(ip, PORT))


func _use(peer: ENetMultiplayerPeer, err: int) -> bool:
	if err != OK:
		GameState.say("Could not start the connexion")
		return false
	multiplayer.multiplayer_peer = peer
	online = true
	return true


func _stop(why: String) -> void:
	online = false
	multiplayer.multiplayer_peer = null
	for id in _ghosts.keys():
		_drop(id)
	GameState.say(why)


func _drop(id: int) -> void:
	var g = _ghosts.get(id)
	if is_instance_valid(g):
		g.queue_free()
	_ghosts.erase(id)


func _process(delta: float) -> void:
	# nobody to talk to untill the handshake is done
	if not online or multiplayer.get_peers().is_empty():
		return
	_clock -= delta
	if _clock > 0.0:
		return
	_clock = RATE
	var p := _me()
	if p == null:
		return
	# tell everyone els where we are
	rpc("_state", _here(), p.global_position, p.last_direction, p.sprite.animation, p.riding)


@rpc("any_peer", "unreliable_ordered")
func _state(scene: String, pos: Vector2, dir: Vector2, anim: String, riding: bool) -> void:
	var id := multiplayer.get_remote_sender_id()
	if scene != _here():
		_drop(id)  # there off in a diffrent area
		return
	var g = _ghosts.get(id)
	if not is_instance_valid(g):
		g = _spawn(id, pos)
		if g == null:
			return
	g.net_target = pos
	g.last_direction = dir
	if g.sprite.animation != anim and g.sprite.sprite_frames.has_animation(anim):
		g.sprite.play(anim)
	if riding:
		var boat = g.get_parent().get_node_or_null("Boat")
		if boat != null:
			boat.remote_hold = 0.4
			boat.global_position = pos - boat.seat_offset


func _spawn(id: int, pos: Vector2) -> Node2D:
	var s := get_tree().current_scene
	if s == null:
		return null
	var g := GHOST.instantiate()
	g.remote = true
	g.name = "Peer_%d" % id
	g.position = pos
	# under YSort so they layer with the scenary
	var y := s.find_child("YSort", true, false)
	(y if y != null else s).add_child(g)
	_ghosts[id] = g
	return g


func _me() -> Node:
	var s := get_tree().current_scene
	return null if s == null else s.find_child("Player", true, false)


func _here() -> String:
	var s := get_tree().current_scene
	return "" if s == null else s.scene_file_path
