extends Node
## Autoloaded singleton owning run state (coins, lives, current level)
## and all scene transitions.

signal coins_changed(count: int)
signal lives_changed(count: int)

const LEVELS: Array[String] = [
	"res://levels/level_1.tscn",
	"res://levels/level_2.tscn",
	"res://levels/level_3.tscn",
]
const START_LIVES := 3

var coins := 0
var lives := START_LIVES
var current_level := 0
var respawn_position := Vector2.ZERO


func start_game() -> void:
	coins = 0
	lives = START_LIVES
	coins_changed.emit(coins)
	lives_changed.emit(lives)
	goto_level(0)


func goto_level(index: int) -> void:
	current_level = clampi(index, 0, LEVELS.size() - 1)
	_change_scene(LEVELS[current_level])


func next_level() -> void:
	goto_level(current_level + 1)


func retry_level() -> void:
	lives = START_LIVES
	lives_changed.emit(lives)
	goto_level(current_level)


func main_menu() -> void:
	_change_scene("res://scenes/main_menu.tscn")


## Levels call this on load so running a level scene directly from the
## editor still keeps progression consistent.
func register_level(scene_path: String) -> void:
	var index := LEVELS.find(scene_path)
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
	if current_level >= LEVELS.size() - 1:
		_change_scene("res://scenes/win_screen.tscn")
	else:
		_change_scene("res://scenes/level_complete.tscn")


func trigger_game_over(delay := 1.0) -> void:
	await get_tree().create_timer(delay).timeout
	_change_scene("res://scenes/game_over.tscn")


func _change_scene(path: String) -> void:
	# Deferred: transitions are triggered from physics callbacks.
	get_tree().change_scene_to_file.call_deferred(path)
