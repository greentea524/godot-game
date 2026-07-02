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
const PAUSE_MENU_SCENE := preload("res://scenes/pause_menu.tscn")
const CLOUDS_TEXTURE := preload("res://assets/clouds.png")

## Set by subclasses in _init().
var layout := ""

## Per-world theming (PG-32): World 2 levels override these for a
## darker palette without needing separate tile art.
var sky_color := Color(0.43, 0.72, 0.91)
var tile_tint := Color.WHITE
var cloud_tint := Color.WHITE

var _player: Player
var _kill_y := 0.0

@onready var tiles: TileMapLayer = $TileMapLayer


func _ready() -> void:
	RenderingServer.set_default_clear_color(sky_color)
	tiles.modulate = tile_tint
	_add_clouds()
	GameManager.register_level(scene_file_path)
	_build()
	add_child(HUD_SCENE.instantiate())
	add_child(PAUSE_MENU_SCENE.instantiate())


func _physics_process(_delta: float) -> void:
	# Falling below the level bounds kills the player (PG-16).
	if is_instance_valid(_player) and not _player.dying \
			and _player.global_position.y > _kill_y:
		_player.die()


## Two looping cloud layers at different scroll speeds and sizes give
## the background depth (PG-31).
func _add_clouds() -> void:
	var background := ParallaxBackground.new()
	for config in [
		{"speed": 0.2, "y": 10.0, "scale": 1.0, "alpha": 0.65},
		{"speed": 0.45, "y": 46.0, "scale": 1.5, "alpha": 1.0},
	]:
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(config.speed, 0.1)
		layer.motion_mirroring = Vector2(CLOUDS_TEXTURE.get_width() * config.scale, 0)
		var cloud_sprite := Sprite2D.new()
		cloud_sprite.texture = CLOUDS_TEXTURE
		cloud_sprite.centered = false
		cloud_sprite.position = Vector2(0, config.y)
		cloud_sprite.scale = Vector2(config.scale, config.scale)
		cloud_sprite.modulate = Color(cloud_tint, config.alpha)
		layer.add_child(cloud_sprite)
		background.add_child(layer)
	add_child(background)


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
