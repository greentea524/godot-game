extends Node
## Autoloaded singleton owning run state (coins, lives, current level,
## avatar choice) and all scene transitions.

signal coins_changed(count: int)
signal lives_changed(count: int)

## Levels grouped by world; the HUD shows "world-stage" (1-1 ... 2-3).
## Adding a new world or stage here is all that's needed — labels and
## win-screen placement adapt automatically (PG-22).
const WORLDS: Array = [
	[
		"res://levels/level_1.tscn",
		"res://levels/level_2.tscn",
		"res://levels/level_3.tscn",
	],
	[
		"res://levels/level_2_1.tscn",
		"res://levels/level_2_2.tscn",
		"res://levels/level_2_3.tscn",
	],
	[
		"res://levels/level_3_1.tscn",
		"res://levels/level_3_2.tscn",
		"res://levels/level_3_3.tscn",
	],
	[
		"res://levels/level_4_1.tscn",
		"res://levels/level_4_2.tscn",
		"res://levels/level_4_3.tscn",
	],
	[
		"res://levels/level_5_1.tscn",
		"res://levels/level_5_2.tscn",
		"res://levels/level_5_3.tscn",
	],
	[
		"res://levels/level_6_1.tscn",
		"res://levels/level_6_2.tscn",
		"res://levels/level_6_3.tscn",
	],
]
const START_LIVES := 3

## Player avatars selectable from the main menu (PG-30). The choice
## persists for the whole session, including level restarts.
const AVATAR_SHEETS: Array[String] = [
	"res://assets/player.png",
	"res://assets/player2.png",
	"res://assets/player3.png",
	"res://assets/player4.png",
	"res://assets/player5.png",
	"res://assets/player6.png",
]
const AVATAR_NAMES: Array[String] = ["Blue", "Green", "Orange", "Yellow", "Purple", "Pink"]

var coins := 0
var lives := START_LIVES
var current_level := 0
var respawn_position := Vector2.ZERO
var selected_avatar := 0
## Number of consecutively completed levels; drives the world map (PG-37).
var levels_completed := 0
## Gravity multiplier for the current level; World 4 uses 0.55 for
## floaty low-gravity jumps (PG-54). Each level sets this on load.
var gravity_scale := 1.0
## Ice physics flag (World 5). Each level sets this on load.
var ice_physics := false

var _level_paths: Array[String] = []
var _level_labels: Array[String] = []
var _level_world: Array[int] = []


func _init() -> void:
	for world in WORLDS.size():
		for stage in WORLDS[world].size():
			_level_paths.append(WORLDS[world][stage])
			_level_labels.append("%d-%d" % [world + 1, stage + 1])
			_level_world.append(world)


func start_game() -> void:
	coins = 0
	lives = START_LIVES
	levels_completed = 0
	coins_changed.emit(coins)
	lives_changed.emit(lives)
	goto_level(0)


func goto_level(index: int) -> void:
	current_level = clampi(index, 0, _level_paths.size() - 1)
	_change_scene(_level_paths[current_level])


func next_level() -> void:
	goto_level(current_level + 1)


func retry_level() -> void:
	lives = START_LIVES
	lives_changed.emit(lives)
	goto_level(current_level)


func main_menu() -> void:
	_change_scene("res://scenes/main_menu.tscn")


func world_map() -> void:
	_change_scene("res://scenes/world_map.tscn")


func open_multiplayer() -> void:
	_change_scene("res://scenes/multiplayer_lobby.tscn")


## World-stage label for the HUD, e.g. "1-2" (PG-22).
func level_label() -> String:
	return _level_labels[current_level]


func level_count() -> int:
	return _level_paths.size()


func flat_index(world: int, stage: int) -> int:
	var index := 0
	for w in world:
		index += WORLDS[w].size()
	return index + stage


func world_of(index: int) -> int:
	return _level_world[index]


func is_completed(index: int) -> bool:
	return index < levels_completed


func is_last_in_world(index: int) -> bool:
	return index == _level_paths.size() - 1 \
			or _level_world[index] != _level_world[index + 1]


func avatar_sheet() -> String:
	return AVATAR_SHEETS[selected_avatar]


## Levels call this on load so running a level scene directly from the
## editor still keeps progression consistent.
func register_level(scene_path: String) -> void:
	var index := _level_paths.find(scene_path)
	if index != -1:
		current_level = index


func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)


## Deducts a life. Returns true when the run is out of lives.
func lose_life() -> bool:
	lives -= 1
	lives_changed.emit(lives)
	return lives <= 0


func set_checkpoint(pos: Vector2) -> void:
	respawn_position = pos


func level_complete() -> void:
	levels_completed = maxi(levels_completed, current_level + 1)
	# Finishing a world's last stage shows the world map (PG-37);
	# mid-world stages keep the regular level-complete screen.
	if is_last_in_world(current_level):
		_change_scene("res://scenes/world_map.tscn")
	else:
		_change_scene("res://scenes/level_complete.tscn")


## Continue from the world map: next unfinished level, or the win
## screen once everything is done.
func continue_from_world_map() -> void:
	if levels_completed >= _level_paths.size():
		_change_scene("res://scenes/win_screen.tscn")
	else:
		goto_level(levels_completed)


func trigger_game_over(delay := 1.0) -> void:
	await get_tree().create_timer(delay).timeout
	_change_scene("res://scenes/game_over.tscn")


func _change_scene(path: String) -> void:
	# Deferred: transitions are triggered from physics callbacks.
	get_tree().change_scene_to_file.call_deferred(path)
