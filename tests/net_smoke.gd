extends Node
## Two-instance ENet connectivity smoke test for the ghost-race net code
## (PG-51). Launch one instance as host and one as client (see the
## orchestration in the commit / README). Each writes a one-line result
## to user://net_<role>.txt. Not part of the single-process suite since
## real networking needs two processes.
##
##   godot --headless --path . res://tests/net_smoke.tscn -- host
##   godot --headless --path . res://tests/net_smoke.tscn -- client


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var role: String = args[0] if args.size() > 0 else "host"
	if role == "host":
		await _run_host()
	else:
		await _run_client()


func _run_host() -> void:
	Net.host_game()
	var got := false
	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		if Net.roster.size() >= 2 and not Net._snapshots.is_empty():
			got = true
			break
	# Linger so the client can observe the full roster before we drop it.
	await get_tree().create_timer(1.5).timeout
	_write("host", "peers=%d got_snapshot=%s" % [Net.roster.size(), got])
	get_tree().quit()


func _run_client() -> void:
	Net.join_game("127.0.0.1")
	var max_roster := 0
	var connected := false
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		if Net.active:
			connected = true
			Net._push_state.rpc({"x": 5.0, "y": 6.0, "vx": 0.0, "facing": 1, "anim": "idle", "lvl": 0})
		max_roster = maxi(max_roster, Net.roster.size())
	_write("client", "connected=%s max_roster=%d" % [connected, max_roster])
	get_tree().quit()


func _write(role: String, msg: String) -> void:
	var f := FileAccess.open("user://net_%s.txt" % role, FileAccess.WRITE)
	f.store_string(msg)
	f.close()
