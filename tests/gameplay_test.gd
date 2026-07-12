extends Node
## Headless gameplay regression test. Run with:
##   godot --headless --path . res://tests/gameplay_test.tscn
## Prints PASS/FAIL per check and exits non-zero on any failure.
## Covers the interaction wiring that a scene-load smoke test misses:
## coin pickup, enemy stomp, spike death, double jump, level labels,
## avatar selection, and pause.

var _failures := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# --- Ghost interpolation (PG-51, ported from ghosts.js) ---
	_check(GhostInterp.sample([], 0.0).is_empty(), "ghost sample is empty with no data")
	var buf: Array = []
	GhostInterp.push(buf, {"x": 0.0, "y": 0.0}, 0.0)
	GhostInterp.push(buf, {"x": 100.0, "y": 0.0}, 100.0)
	var mid := GhostInterp.sample(buf, 150.0, 100.0)  # render_t = 50 → halfway
	_check(is_equal_approx(mid["x"], 50.0), "ghost interpolates between snapshots")
	var ext_buf: Array = []
	GhostInterp.push(ext_buf, {"x": 0.0, "y": 0.0, "vx": 100.0}, 0.0)
	GhostInterp.push(ext_buf, {"x": 10.0, "y": 0.0, "vx": 100.0}, 100.0)
	# render_t = 300, past newest → extrapolate 200 ms (capped): 10 + 100*0.2
	var ext := GhostInterp.sample(ext_buf, 400.0, 100.0)
	_check(is_equal_approx(ext["x"], 30.0), "ghost extrapolates along last velocity")
	var cap_buf: Array = []
	for i in 25:
		GhostInterp.push(cap_buf, {"x": float(i), "y": 0.0}, float(i))
	_check(cap_buf.size() == GhostInterp.MAX_SNAPSHOTS, "ghost buffer is capped")

	# --- Level labels (PG-22, PG-53, PG-54) ---
	_check(GameManager.level_label() == "1-1", "first level is labeled 1-1")
	_check(GameManager._level_labels.size() == 18, "eighteen levels are registered")
	_check(GameManager._level_labels[17] == "6-3", "last level is labeled 6-3")

	# --- Taller goal flag (PG-36) ---
	_check(load("res://assets/flag.png").get_height() == 32, "goal flag art is two tiles tall")

	# --- World map logic and screen (PG-37, PG-53, PG-54) ---
	_check(GameManager.is_last_in_world(2), "1-3 is the last stage of world 1")
	_check(not GameManager.is_last_in_world(3), "2-1 is not the last stage of a world")
	_check(GameManager.is_last_in_world(5), "2-3 is the last stage of world 2")
	_check(GameManager.is_last_in_world(8), "3-3 is the last stage of world 3")
	_check(GameManager.is_last_in_world(11), "4-3 is the last stage of world 4")
	GameManager.levels_completed = 3
	GameManager.current_level = 2
	var map: Control = load("res://scenes/world_map.tscn").instantiate()
	add_child(map)
	await _wait_process_frames(2)
	var map_box: VBoxContainer = map.get_node("%MapBox")
	_check(map_box.get_child_count() == 6, "world map has a row per world")
	_check(map_box.get_child(0).get_child_count() == 4, "world row lists its three stages")
	map.queue_free()
	GameManager.levels_completed = 0
	GameManager.current_level = 0

	# --- Avatar selection (PG-30) ---
	GameManager.selected_avatar = 1
	var avatar_player: Player = load("res://scenes/player.tscn").instantiate()
	add_child(avatar_player)
	var idle_atlas: AtlasTexture = avatar_player.sprite.sprite_frames.get_frame_texture("idle", 0)
	_check(idle_atlas.atlas.resource_path.ends_with("player2.png"),
			"selected avatar sheet is applied to the player")
	avatar_player.queue_free()
	GameManager.selected_avatar = 0

	var level: Node2D = load("res://levels/level_1.tscn").instantiate()
	add_child(level)
	await _wait_frames(5)
	var player: Player = level.get_node("Player_Local")

	# --- Double-jump tutorial in 1-1 (PG-65) ---
	var tutorial: TutorialPrompt = _find_tutorial(level)
	_check(tutorial != null, "level 1-1 has a double-jump tutorial prompt")
	_check(not level._tutorial_shown, "tutorial hidden before the trigger point")
	player.global_position.x = 300.0  # past TUTORIAL_TRIGGER_X (280)
	await _wait_frames(3)
	_check(level._tutorial_shown and tutorial != null \
			and tutorial.label.text.contains("Double Jump"),
			"double-jump tutorial appears past the trigger point")

	# --- Ground decor (PG-55) ---
	var decor := _find_decor(level)
	_check(decor != null, "world 1 level has grassland ground decor")
	if decor != null:
		_check(decor.z_index < 0, "ground decor draws behind the tilemap")
		_check(decor.get_child_count() == 0, "ground decor has no collision nodes")
		_check(decor.kind == "grassland", "world 1 decor is grassland")
		var h1: float = decor._hash(5, 17)
		_check(decor._hash(5, 17) == h1, "decor placement hash is deterministic")
	var forest_level: Node2D = load("res://levels/level_2_1.tscn").instantiate()
	add_child(forest_level)
	await _wait_frames(2)
	var forest_decor := _find_decor(forest_level)
	_check(forest_decor != null and forest_decor.kind == "forest",
			"world 2 level has forest ground decor")
	forest_level.queue_free()
	var cave_level: Node2D = load("res://levels/level_3_1.tscn").instantiate()
	add_child(cave_level)
	await _wait_frames(2)
	_check(_find_decor(cave_level) == null, "world 3 cave level has no ground decor")
	cave_level.queue_free()

	# --- Coin pickup (PG-11/PG-18 wiring) ---
	var coin := _find_by_scene(level, "res://scenes/coin.tscn")
	_check(coin != null, "level 1 contains coins")
	var coins_before := GameManager.coins
	player.global_position = coin.global_position
	player.velocity = Vector2.ZERO
	await _wait_frames(10)
	_check(GameManager.coins >= coins_before + 1, "touching a coin collects it")

	# --- Level boundaries (PG-35) ---
	player.global_position = Vector2(12, 104)
	player.velocity = Vector2.ZERO
	Input.action_press("move_left")
	await _wait_frames(40)
	Input.action_release("move_left")
	_check(player.global_position.x > 0.0, "left boundary stops the player")
	player.global_position = Vector2(1012, 104)
	player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	await _wait_frames(40)
	Input.action_release("move_right")
	_check(player.global_position.x < 1024.0, "right boundary stops the player")

	# --- Double jump (PG-21) ---
	player.global_position = Vector2(520, 104)  # empty, flat spot in level 1
	player.velocity = Vector2.ZERO
	await _wait_frames(5)
	Input.action_press("jump")
	await _wait_frames(2)
	Input.action_release("jump")
	_check(player.velocity.y < 0.0, "ground jump launches the player")
	await _wait_frames(12)  # well into the air
	Input.action_press("jump")
	await _wait_frames(2)
	_check(player.velocity.y < -200.0, "double jump gives a second mid-air boost")
	Input.action_release("jump")
	await _wait_frames(2)
	var vel_before_third := player.velocity.y
	Input.action_press("jump")
	await _wait_frames(2)
	Input.action_release("jump")
	_check(player.velocity.y > vel_before_third, "third jump in one airtime is not allowed")
	await _wait_frames(40)  # land

	# --- Stomp (PG-15) ---
	var enemy: CharacterBody2D = load("res://scenes/enemy.tscn").instantiate()
	enemy.global_position = Vector2(320, 104)  # empty, flat spot in level 1
	level.add_child(enemy)
	await _wait_frames(2)
	player.global_position = enemy.global_position + Vector2(0, -14)
	player.velocity = Vector2(0, 80)
	await _wait_frames(30)
	_check(not is_instance_valid(enemy), "stomping removes the enemy")
	_check(not player.dying, "player survives a stomp")

	# --- Pause (PG-29) ---
	_press_action("pause")
	await _wait_process_frames(3)
	_check(get_tree().paused, "ESC pauses the game")
	_press_action("pause")
	await _wait_process_frames(3)
	_check(not get_tree().paused, "ESC again resumes the game")

	# --- World 3 mechanics (PG-53) ---
	# Keep hazard deaths from depleting lives into a game-over scene change.
	GameManager.lives = 99

	# Bat: flying patrol reverses at its span and bobs vertically. Placed
	# in open space (isolated coords) with no walls, so it turns at ±span.
	var bat: CharacterBody2D = load("res://scenes/bat.tscn").instantiate()
	bat.position = Vector2(2000, 200)
	add_child(bat)
	await _wait_frames(2)
	var bat_dir0: int = bat.direction
	var bat_min_y := bat.global_position.y
	var bat_max_y := bat.global_position.y
	var bat_turned := false
	for i in 140:
		await get_tree().physics_frame
		if bat.direction != bat_dir0:
			bat_turned = true
		bat_min_y = minf(bat_min_y, bat.global_position.y)
		bat_max_y = maxf(bat_max_y, bat.global_position.y)
	_check(bat_turned, "bat reverses at its patrol span")
	_check(bat_max_y - bat_min_y > 4.0, "bat bobs vertically")

	# Lava kills on contact.
	_check(await _hazard_kills("res://scenes/lava.tscn", Vector2(2100, 300)),
			"lava kills the player on contact")

	# Stalactite drops once the player passes beneath its tip.
	var stal: Area2D = load("res://scenes/stalactite.tscn").instantiate()
	stal.position = Vector2(2200, 200)
	add_child(stal)
	var under: Player = load("res://scenes/player.tscn").instantiate()
	under.position = Vector2(2200, 260)  # below the tip, inside the drop zone
	add_child(under)
	await _wait_frames(6)
	_check(stal._falling, "stalactite drops when the player passes beneath")

	# Stalactite kills on contact.
	_check(await _hazard_kills("res://scenes/stalactite.tscn", Vector2(2300, 300)),
			"stalactite kills the player on contact")

	# Volcano erupts, lobbing lava rocks (PG-62).
	var volcano: Node2D = load("res://scenes/volcano.tscn").instantiate()
	volcano.position = Vector2(2500, 300)
	add_child(volcano)
	volcano._timer = 0.02  # force an eruption on the next frame
	await _wait_frames(4)
	var rocks := 0
	for child in get_children():
		if child.scene_file_path == "res://scenes/lava_rock.tscn":
			rocks += 1
	_check(rocks >= 2, "volcano erupts lava rocks")
	volcano.queue_free()

	# Lava rock kills on contact.
	var rock: Area2D = load("res://scenes/lava_rock.tscn").instantiate()
	rock.position = Vector2(2650, 300)
	rock.start_y = 300.0  # so it does not cull before reaching the player
	add_child(rock)
	var rock_victim: Player = load("res://scenes/player.tscn").instantiate()
	rock_victim.position = Vector2(2650, 300)
	add_child(rock_victim)
	await _wait_frames(6)
	_check(rock_victim.dying, "lava rock kills the player on contact")

	# Crumbling platform: solid, then collapses after being stood on.
	var crumble: StaticBody2D = load("res://scenes/crumbling.tscn").instantiate()
	crumble.position = Vector2(2400, 300)
	add_child(crumble)
	await _wait_frames(2)
	_check(not crumble.col.disabled, "crumbling platform starts solid")
	var stander: Player = load("res://scenes/player.tscn").instantiate()
	stander.position = Vector2(2400, 284)  # one tile above; falls onto it
	add_child(stander)
	await _wait_frames(55)  # land + shake (0.4s) + collapse
	_check(crumble.col.disabled, "crumbling platform collapses after being stood on")

	# --- World 4 mechanics (PG-54) ---
	# Low gravity: the same airtime accumulates less downward speed.
	var gp_full: Player = load("res://scenes/player.tscn").instantiate()
	gp_full.position = Vector2(2600, 100)  # open space, no floor
	add_child(gp_full)
	GameManager.gravity_scale = 1.0
	await _wait_frames(10)
	var vy_full := gp_full.velocity.y
	var gp_low: Player = load("res://scenes/player.tscn").instantiate()
	gp_low.position = Vector2(2650, 100)
	add_child(gp_low)
	GameManager.gravity_scale = 0.55
	await _wait_frames(10)
	var vy_low := gp_low.velocity.y
	_check(vy_low > 0.0 and vy_low < vy_full, "low gravity falls slower than normal")

	# Alien reuses the walker enemy with a space skin.
	var alien: CharacterBody2D = load("res://scenes/alien.tscn").instantiate()
	add_child(alien)
	var alien_tex: AtlasTexture = alien.get_node("AnimatedSprite2D").sprite_frames.get_frame_texture("walk", 0)
	_check(alien_tex.atlas.resource_path.ends_with("alien.png"),
			"alien wears the alien skin on the walker enemy")

	# Meteor kills on contact.
	GameManager.gravity_scale = 1.0
	_check(await _hazard_kills("res://scenes/meteor.tscn", Vector2(2700, 300)),
			"meteor kills the player on contact")

	# Moving platform drifts and carries a rider standing on it.
	var plat: AnimatableBody2D = load("res://scenes/moving_platform.tscn").instantiate()
	plat.position = Vector2(2820, 320)
	add_child(plat)
	plat._t = 0.0  # deterministic phase: starts centered so the rider lands on it
	var rider: Player = load("res://scenes/player.tscn").instantiate()
	rider.position = Vector2(2820, 300)  # above the platform; falls onto it
	add_child(rider)
	await _wait_frames(24)  # land on the platform
	# Track the platform's span and how far the rider ever strays from it,
	# over a window wide enough to capture drift at any starting phase.
	var pmin := plat.global_position.x
	var pmax := plat.global_position.x
	var max_gap := 0.0
	for i in 120:
		await get_tree().physics_frame
		pmin = minf(pmin, plat.global_position.x)
		pmax = maxf(pmax, plat.global_position.x)
		max_gap = maxf(max_gap, absf(rider.global_position.x - plat.global_position.x))
	_check(pmax - pmin > 3.0, "moving platform drifts horizontally")
	_check(max_gap < 10.0, "moving platform carries the rider along")

	# --- Spike death (PG-16/PG-10) ---
	var spikes: Area2D = load("res://scenes/spikes.tscn").instantiate()
	spikes.position = Vector2(480, 104)  # empty, flat spot in level 1
	level.add_child(spikes)
	var lives_before := GameManager.lives
	player.global_position = spikes.global_position
	player.velocity = Vector2.ZERO
	await _wait_frames(10)
	_check(player.dying, "spikes kill the player")
	_check(GameManager.lives == lives_before - 1, "death deducts a life")

	if _failures == 0:
		print("ALL TESTS PASSED")
	else:
		print("%d TEST(S) FAILED" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _check(condition: bool, name: String) -> void:
	if condition:
		print("PASS: " + name)
	else:
		_failures += 1
		print("FAIL: " + name)


## Sends the action through the input pipeline (press + release) so
## _unhandled_input handlers see it — Input.action_press alone only
## updates polled state.
func _press_action(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)


## Spawns a hazard scene and a fresh player overlapping it; returns
## whether contact put the player into its dying state. Nodes are left
## in the tree (their death coroutines hold references), which is fine
## for a short-lived headless run at isolated coordinates.
func _hazard_kills(scene_path: String, pos: Vector2) -> bool:
	var hazard := load(scene_path).instantiate() as Node2D
	hazard.position = pos
	add_child(hazard)
	var victim: Player = load("res://scenes/player.tscn").instantiate()
	victim.position = pos
	add_child(victim)
	await _wait_frames(8)
	return victim.dying


func _find_tutorial(level: Node) -> TutorialPrompt:
	for child in level.get_children():
		if child is TutorialPrompt:
			return child
	return null


func _find_decor(level: Node) -> GroundDecor:
	for child in level.get_children():
		if child is GroundDecor:
			return child
	return null


func _find_by_scene(root: Node, scene_path: String) -> Node:
	for child in root.get_children():
		if child.scene_file_path == scene_path:
			return child
	return null


func _wait_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _wait_process_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
