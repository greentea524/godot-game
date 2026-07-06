extends Node
## Ghost-race LAN multiplayer (PG-50/51), autoloaded as "Net".
##
## Model (ported from the JS platformer): one player HOSTS an ENet
## server (peer id 1); others JOIN by IP. Every client keeps running its
## own full local simulation — remote players are drawn as non-colliding
## ghosts from broadcast snapshots. The host is only a coordinator
## (roster + race start); it is NOT authoritative over movement, so
## single-player behaviour is byte-for-byte unchanged when inactive.

signal roster_changed(roster: Dictionary)
signal race_started()
signal connection_failed()
signal server_disconnected()

const PORT := 24555
const MAX_PLAYERS := 6
const SEND_INTERVAL := 1.0 / 15.0  # 15 Hz, decoupled from the 60 Hz sim

## True once a session is live (host up, or client connected).
var active := false
## peer_id -> {name, avatar, slot, finished, time_ms}
var roster := {}
## The local CharacterBody2D whose state we broadcast (set by the level).
var local_player: Node = null
var local_name := "Player"

## peer_id -> Array of ghost snapshots (see GhostInterp).
var _snapshots := {}
var _send_accum := 0.0
var _wired := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_host() -> bool:
	return active and multiplayer.multiplayer_peer != null and multiplayer.is_server()


# --- Session lifecycle ------------------------------------------------

func host_game() -> bool:
	_wire()
	var peer := ENetMultiplayerPeer.new()
	if peer.create_server(PORT, MAX_PLAYERS) != OK:
		return false
	multiplayer.multiplayer_peer = peer
	active = true
	roster = {1: _entry(local_name, GameManager.selected_avatar, 0)}
	roster_changed.emit(roster)
	return true


func join_game(ip: String) -> bool:
	_wire()
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client(ip, PORT) != OK:
		return false
	multiplayer.multiplayer_peer = peer
	return true


func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	active = false
	roster.clear()
	_snapshots.clear()
	local_player = null


func start_race() -> void:
	if is_host():
		_start_race.rpc()


## A LAN IPv4 address to show joiners, or 127.0.0.1 as a fallback.
func local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10.") \
				or addr.begins_with("172."):
			return addr
	return "127.0.0.1"


# --- Per-frame state broadcast ---------------------------------------

func _process(delta: float) -> void:
	if not active or not is_instance_valid(local_player):
		return
	_send_accum += delta
	if _send_accum < SEND_INTERVAL:
		return
	_send_accum = 0.0
	var sprite: AnimatedSprite2D = local_player.sprite
	_push_state.rpc({
		"x": local_player.global_position.x,
		"y": local_player.global_position.y,
		"vx": local_player.velocity.x,
		"facing": -1 if sprite.flip_h else 1,
		"anim": sprite.animation,
		"lvl": GameManager.current_level,
	})


## Interpolated view of a remote peer for the ghost renderer, or {} if
## no snapshots have arrived yet.
func ghost_view(peer_id: int) -> Dictionary:
	if not _snapshots.has(peer_id):
		return {}
	return GhostInterp.sample(_snapshots[peer_id], Time.get_ticks_msec())


func remote_peers() -> Array:
	var out := []
	var self_id := multiplayer.get_unique_id()
	for peer_id in roster:
		if peer_id != self_id:
			out.append(peer_id)
	return out


# --- Internals --------------------------------------------------------

func _wire() -> void:
	if _wired:
		return
	_wired = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _entry(pname: String, avatar: int, slot: int) -> Dictionary:
	return {"name": pname, "avatar": avatar, "slot": slot, "finished": false, "time_ms": 0}


func _on_peer_connected(_id: int) -> void:
	pass  # the joiner registers itself (below), which adds it to the roster


func _on_peer_disconnected(id: int) -> void:
	_snapshots.erase(id)
	if is_host() and roster.erase(id):
		_sync_roster.rpc(roster)


func _on_connected_to_server() -> void:
	active = true
	_register.rpc_id(1, local_name, GameManager.selected_avatar)


func _on_connection_failed() -> void:
	active = false
	connection_failed.emit()


func _on_server_disconnected() -> void:
	active = false
	roster.clear()
	server_disconnected.emit()


## Client -> host: announce name and avatar; the host slots it into the
## roster and rebroadcasts.
@rpc("any_peer", "reliable")
func _register(pname: String, avatar: int) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	roster[id] = _entry(pname, avatar, roster.size())
	_sync_roster.rpc(roster)


## Host -> everyone: the authoritative roster.
@rpc("authority", "call_local", "reliable")
func _sync_roster(new_roster: Dictionary) -> void:
	roster = new_roster
	roster_changed.emit(roster)


## Host -> everyone: begin the race together.
@rpc("authority", "call_local", "reliable")
func _start_race() -> void:
	race_started.emit()


## Any client -> others (relayed by the host): a movement snapshot.
@rpc("any_peer", "unreliable_ordered")
func _push_state(snap: Dictionary) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender == multiplayer.get_unique_id():
		return
	if not _snapshots.has(sender):
		_snapshots[sender] = []
	GhostInterp.push(_snapshots[sender], snap, Time.get_ticks_msec())
