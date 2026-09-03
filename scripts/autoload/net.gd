extends Node

const PORT := 7717
const BEACON := 7718
const TAG := "BELLCREEK"
# no I/L/O/U so nobody misreads there code down the phone
const ALPHA := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const GHOST := preload("res://scenes/player/Player.tscn")
const RATE := 1.0 / 15.0

var online: bool = false
var found: Dictionary = {}

var _ghosts: Dictionary = {}
var _clock: float = 0.0
var _udp: PacketPeerUDP = null
var _shouting: bool = false
var _shout_to: String = ""
var _beat: float = 0.0


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_drop)
	multiplayer.connection_failed.connect(func(): _stop("Could not reach that host"))
	multiplayer.server_disconnected.connect(func(): _stop("The host left"))


func host() -> bool:
	var peer := ENetMultiplayerPeer.new()
	return _use(peer, peer.create_server(PORT, 3))


func join(ip: String) -> bool:
	if ip == "":
		GameState.say("That code doesnt look right")
		return false
	var peer := ENetMultiplayerPeer.new()
	return _use(peer, peer.create_client(ip, PORT))


## Shout on the local network so the join screen can list us.
func shout() -> void:
	_udp = PacketPeerUDP.new()
	_udp.bind(0)  # has to be bound befor broadcast is allowed through
	_udp.set_broadcast_enabled(true)
	var lan := _lan_ip()
	# 255.255.255.255 gets swallowed on mac, the subnet one gets through
	_shout_to = "255.255.255.255" if lan == "" else lan.rsplit(".", true, 1)[0] + ".255"
	_shouting = true


func browse(on: bool) -> void:
	found.clear()
	if _shouting:
		return
	if _udp != null:
		_udp.close()
		_udp = null
	if on:
		_udp = PacketPeerUDP.new()
		_udp.bind(BEACON)


func code_for(ip: String) -> String:
	var n := 0
	for part in ip.split("."):
		n = n * 256 + int(part)
	var out := ""
	for i in 7:
		out = ALPHA[n % 32] + out
		n /= 32
	return out


func ip_from(code: String) -> String:
	var text := code.strip_edges().to_upper()
	if text.length() != 7:
		return ""
	var n := 0
	for c in text:
		var i := ALPHA.find(c)
		if i < 0:
			return ""
		n = n * 32 + i
	return "%d.%d.%d.%d" % [(n >> 24) & 255, (n >> 16) & 255, (n >> 8) & 255, n & 255]


## Our own code, for reading out to whoever wants in.
func my_code() -> String:
	var ip := _lan_ip()
	return "" if ip == "" else code_for(ip)


func _lan_ip() -> String:
	var spare := ""  # vpn and the like, only if theres no proper wifi one
	for a in IP.get_local_addresses():
		if a.begins_with("192.168."):
			return a
		if spare == "" and (a.begins_with("10.") or a.begins_with("172.")):
			spare = a
	return spare


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
	_pulse(delta)
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


func _pulse(delta: float) -> void:
	if _udp == null:
		return
	if _shouting:
		_beat -= delta
		if _beat <= 0.0:
			_beat = 1.0
			var pkt := TAG.to_utf8_buffer()
			_udp.set_dest_address(_shout_to, BEACON)
			_udp.put_packet(pkt)
			_udp.set_dest_address("127.0.0.1", BEACON)  # so one pc can test itself
			_udp.put_packet(pkt)
		return
	while _udp.get_available_packet_count() > 0:
		if _udp.get_packet().get_string_from_utf8() == TAG:
			found[_udp.get_packet_ip()] = 3.0
	for ip in found.keys():  # forget hosts that went quiet
		found[ip] = float(found[ip]) - delta
		if float(found[ip]) <= 0.0:
			found.erase(ip)


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
