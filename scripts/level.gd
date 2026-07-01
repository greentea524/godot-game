extends Node2D
## Base level: builds the TileMap and spawns entities from an ASCII layout.
##
## Legend:
##   G  grass ground tile (dirt is auto-backfilled two rows below)
##   D  dirt tile           B  block/platform tile
##   P  player start        C  coin
##   E  enemy               S  spikes
##   K  checkpoint          F  goal flag
##   .  empty

const TILE := 16
const GRASS := Vector2i(0, 0)
const DIRT := Vector2i(1, 0)
const BLOCK := Vector2i(2, 0)

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const COIN_SCENE := preload("res://scenes/coin.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const SPIKES_SCENE := preload("res://scenes/spikes.tscn")
const FLAG_SCENE := preload("res://scenes/flag.tscn")
const CHECKPOINT_SCENE := preload("res://scenes/checkpoint.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")

## Set by subclasses in _init().
var layout := ""

var _player: Player
var _kill_y := 0.0

@onready var tiles: TileMapLayer = $TileMapLayer


func _ready() -> void:
	GameManager.register_level(scene_file_path)
	_build()
	add_child(HUD_SCENE.instantiate())


func _physics_process(_delta: float) -> void:
	# Falling below the level bounds kills the player (PG-16).
	if is_instance_valid(_player) and not _player.dying \
			and _player.global_position.y > _kill_y:
		_player.die()


func _build() -> void:
	var lines := layout.replace("\r", "").split("\n")
	while not lines.is_empty() and lines[0].strip_edges().is_empty():
		lines.remove_at(0)
	while not lines.is_empty() and lines[lines.size() - 1].strip_edges().is_empty():
		lines.remove_at(lines.size() - 1)

	var width := 0
	for y in lines.size():
		var line := lines[y]
		width = maxi(width, line.length())
		for x in line.length():
			_place(line[x], Vector2i(x, y))

	_kill_y = (lines.size() + 4) * TILE
	if _player == null:
		push_warning("Level layout has no player start ('P').")
		return
	var cam := _player.camera
	cam.limit_left = 0
	cam.limit_right = width * TILE
	cam.limit_bottom = (lines.size() + 2) * TILE
	cam.reset_smoothing()


func _place(ch: String, cell: Vector2i) -> void:
	var pos := Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
	match ch:
		"G":
			tiles.set_cell(cell, 0, GRASS)
			tiles.set_cell(cell + Vector2i(0, 1), 0, DIRT)
			tiles.set_cell(cell + Vector2i(0, 2), 0, DIRT)
		"D":
			tiles.set_cell(cell, 0, DIRT)
		"B":
			tiles.set_cell(cell, 0, BLOCK)
		"C":
			_spawn(COIN_SCENE, pos)
		"E":
			_spawn(ENEMY_SCENE, pos)
		"S":
			_spawn(SPIKES_SCENE, pos)
		"F":
			_spawn(FLAG_SCENE, pos)
		"K":
			_spawn(CHECKPOINT_SCENE, pos)
		"P":
			_player = PLAYER_SCENE.instantiate()
			_player.position = pos
			add_child(_player)
			GameManager.set_checkpoint(pos)


func _spawn(scene: PackedScene, pos: Vector2) -> void:
	var node := scene.instantiate() as Node2D
	node.position = pos
	add_child(node)
