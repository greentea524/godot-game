extends Node
## Headless gameplay regression test. Run with:
##   godot --headless --path . res://tests/gameplay_test.tscn
## Prints PASS/FAIL per check and exits non-zero on any failure.
## Covers the interaction wiring that a scene-load smoke test misses:
## coin pickup, enemy stomp, and spike death.

var _failures := 0


func _ready() -> void:
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


func _find_by_scene(root: Node, scene_path: String) -> Node:
	for child in root.get_children():
		if child.scene_file_path == scene_path:
			return child
	return null


func _wait_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
