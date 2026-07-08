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
##   A  alien (World 4)     M  moving platform (World 4)
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
const ALIEN_SCENE := preload("res://scenes/alien.tscn")
const MOVING_PLATFORM_SCENE := preload("res://scenes/moving_platform.tscn")
const METEOR_SCENE := preload("res://scenes/meteor.tscn")
const FREEZING_WATER_SCENE := preload("res://scenes/freezing_water.tscn")
const YETI_SCENE := preload("res://scenes/yeti.tscn")
const DRONE_SCENE := preload("res://scenes/drone.tscn")
const LASER_SCENE := preload("res://scenes/laser.tscn")
const CONVEYOR_SCENE := preload("res://scenes/conveyor.tscn")
const HUD_SCENE := preload("res://scenes/hud.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/pause_menu.tscn")
const GHOST_SCENE := preload("res://scenes/ghost.tscn")
const CLOUDS_TEXTURE := preload("res://assets/clouds.png")
const CRYSTALS_TEXTURE := preload("res://assets/crystals.png")
const STARS_TEXTURE := preload("res://assets/stars.png")

const METEOR_MIN_GAP := 0.7
const METEOR_MAX_GAP := 1.8

## Set by subclasses in _init().
var layout := ""

## Per-world theming (PG-32): World 2+ levels override these for a
## darker palette without needing separate tile art.
var sky_color := Color(0.43, 0.72, 0.91)
var tile_tint := Color.WHITE
var cloud_tint := Color.WHITE
## Background dressing: "clouds" (default), "cave" — the World 3 crystal
## backdrop (PG-53), or "space" — the World 4 starfield (PG-54).
var decor := "clouds"
## World 4 low gravity (PG-54): 1.0 normal, 0.55 for floaty space jumps.
var gravity_scale := 1.0
## World 4 meteor shower (PG-54): drops meteors from above on the later
## space stages.
var meteors := false
## Ground scenery for the surface worlds (PG-55): "grassland" (World 1),
## "forest" (World 2), or "" for none. Purely decorative, behind tiles.
var ground_decor := ""
## Ice level flag (World 5). Changes player friction.
var ice := false

var _player: Player
var _kill_y := 0.0
var _width := 0
var _meteor_timer := 1.2
## peer_id -> Ghost node, in multiplayer races (PG-51).
var _ghosts := {}

@onready var tiles: TileMapLayer = $TileMapLayer


func _ready() -> void:
	RenderingServer.set_default_clear_color(sky_color)
	GameManager.gravity_scale = gravity_scale
	GameManager.ice_physics = ice
	tiles.modulate = tile_tint
	_add_backdrop()
	GameManager.register_level(scene_file_path)
	_build()
	add_child(HUD_SCENE.instantiate())
	add_child(PAUSE_MENU_SCENE.instantiate())


func _physics_process(delta: float) -> void:
	# Falling below the level bounds kills the player (PG-16).
	if is_instance_valid(_player) and not _player.dying \
			and _player.global_position.y > _kill_y:
		_player.die()
	if meteors:
		_meteor_timer -= delta
		if _meteor_timer <= 0.0:
			_meteor_timer = randf_range(METEOR_MIN_GAP, METEOR_MAX_GAP)
			_spawn_meteor()


## World 4 meteor shower (PG-54): drop a meteor from above the player at
## a random x across the level; the meteor falls and frees itself past
## the kill plane.
func _spawn_meteor() -> void:
	if not is_instance_valid(_player):
		return
	var meteor := METEOR_SCENE.instantiate()
	meteor.fall_limit = _kill_y + 64.0
	var x := randf() * _width * TILE
	var y := _player.global_position.y - 120.0
	meteor.position = Vector2(x, y)
	add_child(meteor)


## Two looping parallax layers at different scroll speeds and sizes give
## the background depth. Clouds for the surface worlds (PG-31); a
## glowing-crystal backdrop for the World 3 caves (PG-53).
func _add_backdrop() -> void:
	if decor == "space":
		_add_space_backdrop()
		return
		
	var texture: Texture2D
	match decor:
		"clouds", "ice":
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

func _add_space_backdrop() -> void:
	var background := ParallaxBackground.new()
	
	# Stars (slowest)
	var layer_stars := ParallaxLayer.new()
	layer_stars.motion_scale = Vector2(0.1, 0.1)
	layer_stars.motion_mirroring = Vector2(1000, 800)
	var stars = load("res://scripts/space_decor.gd").new()
	stars.kind = "stars"
	layer_stars.add_child(stars)
	background.add_child(layer_stars)

	# Planets (mid)
	var layer_planets := ParallaxLayer.new()
	layer_planets.motion_scale = Vector2(0.3, 0.3)
	layer_planets.motion_mirroring = Vector2(1000, 800)
	var planets = load("res://scripts/space_decor.gd").new()
	planets.kind = "planets"
	layer_planets.add_child(planets)
	background.add_child(layer_planets)

	# Debris (fastest)
	var layer_debris := ParallaxLayer.new()
	layer_debris.motion_scale = Vector2(0.6, 0.6)
	layer_debris.motion_mirroring = Vector2(1000, 800)
	var debris = load("res://scripts/space_decor.gd").new()
	debris.kind = "debris"
	layer_debris.add_child(debris)
	background.add_child(layer_debris)
	
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

	_width = width
	_kill_y = (lines.size() + 4) * TILE
	_add_boundaries(width, lines.size())
	if ground_decor != "":
		_add_ground_decor(width, lines.size())
	if decor == "cave":
		_add_cave_decor(width, lines.size())
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


## Renders remote racers as ghosts each frame (PG-51). Ghosts have no
## collision, so the local simulation is unchanged; they simply follow
## the interpolated snapshots relayed through Net.
func _process(_delta: float) -> void:
	if not Net.active:
		return
	var peers := Net.remote_peers()
	for peer_id in peers:
		var ghost: Ghost = _ghosts.get(peer_id)
		if ghost == null or not is_instance_valid(ghost):
			ghost = GHOST_SCENE.instantiate()
			var entry: Dictionary = Net.roster.get(peer_id, {})
			ghost.setup(entry.get("avatar", 0), entry.get("name", "Player"))
			add_child(ghost)
			_ghosts[peer_id] = ghost
		ghost.apply_view(Net.ghost_view(peer_id))
	# Drop ghosts for peers that have left.
	for peer_id in _ghosts.keys():
		if not peers.has(peer_id):
			if is_instance_valid(_ghosts[peer_id]):
				_ghosts[peer_id].queue_free()
			_ghosts.erase(peer_id)


## Surface-world ground scenery (PG-55): a single _draw node placed
## behind the tilemap. Purely visual — no collision, no gameplay impact.
func _add_ground_decor(width: int, rows: int) -> void:
	var decor := GroundDecor.new()
	decor.kind = ground_decor
	decor.width_px = width * TILE
	decor.ground_row = rows - 1
	decor.tiles = tiles
	decor.z_index = -1
	add_child(decor)
	decor.queue_redraw()

func _add_cave_decor(width: int, rows: int) -> void:
	var cave = load("res://scripts/cave_decor.gd").new()
	cave.width_tiles = width
	cave.height_tiles = rows
	cave.tiles = tiles
	cave.z_index = -1
	add_child(cave)
	cave.queue_redraw()


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
			_spawn(COIN_SCENE, pos, "Coin", cell)
		"E":
			_spawn(ENEMY_SCENE, pos, "Enemy", cell)
		"S":
			_spawn(SPIKES_SCENE, pos, "Spikes", cell)
		"F":
			_spawn(FLAG_SCENE, pos, "Flag", cell)
		"K":
			_spawn(CHECKPOINT_SCENE, pos, "Checkpoint", cell)
		"L":
			_spawn(LAVA_SCENE, pos, "Lava", cell)
		"V":
			_spawn(BAT_SCENE, pos, "Bat", cell)
		"T":
			_spawn(STALACTITE_SCENE, pos, "Stalactite", cell)
		"X":
			# Crumbling platform is its own solid body, so no tile here.
			_spawn(CRUMBLING_SCENE, pos, "Crumbling", cell)
		"A":
			_spawn(ALIEN_SCENE, pos, "Alien", cell)
		"M":
			_spawn(MOVING_PLATFORM_SCENE, pos, "MovingPlatform", cell)
		"I":
			tiles.set_cell(cell, 0, GRASS)
			tiles.set_cell(cell + Vector2i(0, 1), 0, DIRT)
			tiles.set_cell(cell + Vector2i(0, 2), 0, DIRT)
		"W":
			_spawn(FREEZING_WATER_SCENE, pos, "FreezingWater", cell)
		"Y":
			_spawn(YETI_SCENE, pos, "Yeti", cell)
		"Z":
			_spawn(LASER_SCENE, pos, "Laser", cell)
		"R":
			_spawn(DRONE_SCENE, pos, "Drone", cell)
		">":
			tiles.set_cell(cell, 0, BLOCK)
			var node := CONVEYOR_SCENE.instantiate() as Node2D
			node.dir = 1
			node.name = "ConveyorR_%d_%d" % [cell.x, cell.y]
			node.position = pos
			add_child(node)
		"<":
			tiles.set_cell(cell, 0, BLOCK)
			var node := CONVEYOR_SCENE.instantiate() as Node2D
			node.dir = -1
			node.name = "ConveyorL_%d_%d" % [cell.x, cell.y]
			node.position = pos
			add_child(node)
		"P":
			_player = PLAYER_SCENE.instantiate()
			_player.position = pos
			_player.name = "Player_Local"
			add_child(_player)
			GameManager.set_checkpoint(pos)
			# In a race, this is the local avatar we broadcast (PG-51).
			if Net.active:
				Net.local_player = _player


func _spawn(scene: PackedScene, pos: Vector2, node_prefix: String, cell: Vector2i) -> void:
	var node := scene.instantiate() as Node2D
	node.name = "%s_%d_%d" % [node_prefix, cell.x, cell.y]
	node.position = pos
	add_child(node)
