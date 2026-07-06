extends Control
## Multiplayer lobby (PG-51): Host Game / Join Game, a live roster with
## avatars, and a host-only Start button. Ghost-race over LAN — see
## scripts/net.gd. QR join is deferred (PG-52); joiners type the host's
## IP shown on the host screen.


func _ready() -> void:
	%HostButton.pressed.connect(_on_host)
	%JoinButton.pressed.connect(func() -> void: %JoinRow.visible = true; %IPEdit.grab_focus())
	%ConnectButton.pressed.connect(_on_connect)
	%StartButton.pressed.connect(Net.start_race)
	%BackButton.pressed.connect(_on_back)
	Net.roster_changed.connect(_rebuild_roster)
	Net.race_started.connect(GameManager.start_game)
	Net.connection_failed.connect(func() -> void: _set_status("Connection failed."); _unlock())
	Net.server_disconnected.connect(func() -> void: _set_status("Host disconnected."))
	Net.local_name = "Player %d" % (randi() % 900 + 100)
	%JoinRow.visible = false
	%StartButton.visible = false
	_set_status("Host a game, or join one on your LAN.")


func _on_host() -> void:
	if Net.host_game():
		_set_status("Hosting on  %s : %d  — waiting for players…" % [Net.local_ip(), Net.PORT])
		_lock()
		%StartButton.visible = true
	else:
		_set_status("Could not start host (port already in use?).")


func _on_connect() -> void:
	var ip: String = %IPEdit.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	if Net.join_game(ip):
		_set_status("Connecting to %s …" % ip)
		_lock()
	else:
		_set_status("Invalid address.")


func _on_back() -> void:
	Net.leave()
	GameManager.main_menu()


func _rebuild_roster(roster: Dictionary) -> void:
	for child in %RosterBox.get_children():
		child.queue_free()
	var self_id := multiplayer.get_unique_id()
	for peer_id in roster:
		var entry: Dictionary = roster[peer_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var frame := AtlasTexture.new()
		frame.atlas = load(GameManager.AVATAR_SHEETS[clampi(entry.get("avatar", 0), 0, 2)])
		frame.region = Rect2(0, 0, 16, 16)
		icon.texture = frame
		row.add_child(icon)
		var label := Label.new()
		var tags := ""
		if peer_id == 1:
			tags += "  (host)"
		if peer_id == self_id:
			tags += "  ← you"
		label.text = str(entry.get("name", "Player")) + tags
		row.add_child(label)
		%RosterBox.add_child(row)


func _set_status(text: String) -> void:
	%Status.text = text


func _lock() -> void:
	%HostButton.disabled = true
	%JoinButton.disabled = true
	%ConnectButton.disabled = true


func _unlock() -> void:
	%HostButton.disabled = false
	%JoinButton.disabled = false
	%ConnectButton.disabled = false
