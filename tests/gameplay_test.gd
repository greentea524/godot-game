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

	# --- Level labels (PG-22) ---
	_check(GameManager.level_label() == "1-1", "first level is labeled 1-1")
	_check(GameManager._level_labels.size() == 6, "six levels are registered")
	_check(GameManager._level_labels[5] == "2-3", "last level is labeled 2-3")

	# --- Taller goal flag (PG-36) ---
	_check(load("res://assets/flag.png").get_height() == 32, "goal flag art is two tiles tall")

	# --- World map logic and screen (PG-37) ---
	_check(GameManager.is_last_in_world(2), "1-3 is the last stage of world 1")
	_check(not GameManager.is_last_in_world(3), "2-1 is not the last stage of a world")
	_check(GameManager.is_last_in_world(5), "2-3 is the last stage of world 2")
	GameManager.levels_completed = 3
	GameManager.current_level = 2
	var map: Control = load("res://scenes/world_map.tscn").instantiate()
	add_child(map)
	await _wait_process_frames(2)
	var map_box: VBoxContainer = map.get_node("%MapBox")
	_check(map_box.get_child_count() == 2, "world map has a row per world")
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
	var player: Player = level.get_node("Player")

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
