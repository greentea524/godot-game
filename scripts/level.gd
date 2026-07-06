extends Node2D
## Base level: builds the TileMap and spawns entities from an ASCII layout.
##
## Legend:
##   G  grass ground tile (dirt is auto-backfilled two rows below)
##   D  dirt tile           B  block/platform tile
##   P  player start        C  coin
##   E  enemy               S  spikes
##   K  checkpoint          F  goal flag
##   L  lava (World 3)      V  bat (World 3)
##   T  stalactite (W3)     X  crumbling platform (W3)
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
const LAVA_SCENE := preload("res://scenes/lava.tscn")
const BAT_SCENE := preload("res://scenes/bat.tscn")
const STALACTITE_SCENE := preload("res://scenes/stalactite.tscn")
const CRUMBLING_SCENE := preload("res://scenes/crumbling.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/pause_menu.tscn")
const CLOUDS_TEXTURE := preload("res://assets/clouds.png")
const CRYSTALS_TEXTURE := preload("res://assets/crystals.png")

## Set by subclasses in _init().
var layout := ""

## Per-world theming (PG-32): World 2+ levels override these for a
## darker palette without needing separate tile art.
var sky_color := Color(0.43, 0.72, 0.91)
var tile_tint := Color.WHITE
var cloud_tint := Color.WHITE
## Background dressing: "clouds" (default) or "cave" — the crystal
## backdrop used by World 3 (PG-53). Worlds without a sky pass "".
var decor := "clouds"

var _player: Player
var _kill_y := 0.0

@onready var tiles: TileMapLayer = $TileMapLayer


func _ready() -> void:
	RenderingServer.set_default_clear_color(sky_color)
	tiles.modulate = tile_tint
	_add_backdrop()
	GameManager.register_level(scene_file_path)
	_build()
	add_child(HUD_SCENE.instantiate())
	add_child(PAUSE_MENU_SCENE.instantiate())


func _physics_process(_delta: float) -> void:
	# Falling below the level bounds kills the player (PG-16).
	if is_instance_valid(_player) and not _player.dying \
			and _player.global_position.y > _kill_y:
		_player.die()


## Two looping parallax layers at different scroll speeds and sizes give
## the background depth. Clouds for the surface worlds (PG-31); a
## glowing-crystal backdrop for the World 3 caves (PG-53).
func _add_backdrop() -> void:
	var texture: Texture2D
	match decor:
		"clouds":
			texture = CLOUDS_TEXTURE
		"cave":
			texture = CRYSTALS_TEXTURE
		_:
			return  # no sky backdrop for this world

	var background := ParallaxBackground.new()
	for config in [
		{"speed": 0.2, "y": 10.0, "scale": 1.0, "alpha": 0.65},
		{"speed": 0.45, "y": 46.0, "scale": 1.5, "alpha": 1.0},
	]:
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(config.speed, 0.1)
		layer.motion_mirroring = Vector2(texture.get_width() * config.scale, 0)
		var backdrop := Sprite2D.new()
		backdrop.texture = texture
		backdrop.centered = false
		backdrop.position = Vector2(0, config.y)
		backdrop.scale = Vector2(config.scale, config.scale)
		backdrop.modulate = Color(cloud_tint, config.alpha)
		layer.add_child(backdrop)
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
	_add_boundaries(width, lines.size())
	if _player == null:
		push_warning("Level layout has no player start ('P').")
		return
	var cam := _player.camera
	cam.limit_left = 0
	cam.limit_right = width * TILE
	cam.limit_bottom = (lines.size() + 2) * TILE
	cam.reset_smoothing()


## Invisible walls at both ends of the map so the player and enemies
## cannot walk out of bounds (PG-35). They reach 20 tiles above the
## level, well beyond double-jump height.
func _add_boundaries(width: int, rows: int) -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	var top := -20.0 * TILE
	var bottom := float(rows + 4) * TILE
	for x in [-TILE / 2.0, width * TILE + TILE / 2.0]:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE, bottom - top)
		shape.shape = rect
		shape.position = Vector2(x, (top + bottom) / 2.0)
		walls.add_child(shape)
	add_child(walls)


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
		"L":
			_spawn(LAVA_SCENE, pos)
		"V":
			_spawn(BAT_SCENE, pos)
		"T":
			_spawn(STALACTITE_SCENE, pos)
		"X":
			# Crumbling platform is its own solid body, so no tile here.
			_spawn(CRUMBLING_SCENE, pos)
		"P":
			_player = PLAYER_SCENE.instantiate()
			_player.position = pos
			add_child(_player)
			GameManager.set_checkpoint(pos)


func _spawn(scene: PackedScene, pos: Vector2) -> void:
	var node := scene.instantiate() as Node2D
	node.position = pos
	add_child(node)
