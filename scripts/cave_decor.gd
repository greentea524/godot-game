extends Node2D
## Procedurally generated cave decorations for World 3 (stalactites, crystals, torches, skulls).

const TILE := 16

var width_tiles := 0
var height_tiles := 0
var tiles: TileMapLayer

func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = (h ^ (h >> 16)) & 0xFFFFFFFF
	return float(h) / 4294967296.0

func _is_solid(tx: int, ty: int) -> bool:
	if tiles == null: return false
	return tiles.get_cell_source_id(Vector2i(tx, ty)) != -1

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	# Continuous redraw for torch flickering
	queue_redraw()

func _draw() -> void:
	for x in range(width_tiles):
		for y in range(height_tiles):
			var pos := Vector2(x * TILE, y * TILE)
			var h := _hash(x, y)
			
			# Check for floor (solid below, empty here)
			if _is_solid(x, y + 1) and not _is_solid(x, y):
				if h < 0.15:
					_stalagmite(pos + Vector2(TILE/2.0, TILE))
				elif h < 0.25:
					_crystals(pos + Vector2(TILE/2.0, TILE), h)
				elif h < 0.30:
					_skull_pile(pos + Vector2(TILE/2.0, TILE))
			
			# Check for ceiling (solid above, empty here)
			if _is_solid(x, y - 1) and not _is_solid(x, y):
				if h < 0.25:
					_stalactite(pos + Vector2(TILE/2.0, 0))
					
			# Check for walls (solid left/right, empty here, not floor/ceiling)
			if not _is_solid(x, y) and not _is_solid(x, y+1) and not _is_solid(x, y-1):
				if _is_solid(x - 1, y) and h < 0.05:
					_torch(pos + Vector2(0, TILE/2.0), 1, h)
				elif _is_solid(x + 1, y) and h < 0.10 and h >= 0.05:
					_torch(pos + Vector2(TILE, TILE/2.0), -1, h)

func _stalagmite(p: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(p.x - 6, p.y), Vector2(p.x + 6, p.y), Vector2(p.x, p.y - 12 - (_hash(int(p.x), int(p.y)) * 10))
	]), Color(0.3, 0.25, 0.35))
	draw_colored_polygon(PackedVector2Array([
		Vector2(p.x - 2, p.y), Vector2(p.x + 3, p.y), Vector2(p.x + 1, p.y - 8 - (_hash(int(p.x), int(p.y)) * 5))
	]), Color(0.4, 0.35, 0.45))

func _stalactite(p: Vector2) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(p.x - 5, p.y), Vector2(p.x + 5, p.y), Vector2(p.x, p.y + 12 + (_hash(int(p.x), int(p.y)) * 12))
	]), Color(0.3, 0.25, 0.35))
	draw_colored_polygon(PackedVector2Array([
		Vector2(p.x - 2, p.y), Vector2(p.x + 2, p.y), Vector2(p.x, p.y + 7 + (_hash(int(p.x), int(p.y)) * 6))
	]), Color(0.2, 0.15, 0.25))

func _crystals(p: Vector2, seed_val: float) -> void:
	var c := Color(0.4, 0.8, 1.0)
	if seed_val < 0.2: c = Color(1.0, 0.4, 0.8) # Pink/purple variation
	
	for i in range(3):
		var h = 6.0 + (_hash(int(p.x), i) * 6.0)
		var w = 2.0 + (_hash(int(p.y), i) * 2.0)
		var offset = (i - 1) * 4.0
		var pts = PackedVector2Array([
			Vector2(p.x + offset - w, p.y),
			Vector2(p.x + offset + w, p.y),
			Vector2(p.x + offset, p.y - h)
		])
		draw_colored_polygon(pts, c.darkened(0.2))
		
		# Highlight
		var h_pts = PackedVector2Array([
			Vector2(p.x + offset - w/2, p.y),
			Vector2(p.x + offset, p.y),
			Vector2(p.x + offset, p.y - h + 1)
		])
		draw_colored_polygon(h_pts, c.lightened(0.2))

func _skull_pile(p: Vector2) -> void:
	# Base skulls
	draw_circle(Vector2(p.x - 3, p.y - 3), 3, Color(0.8, 0.8, 0.75))
	draw_circle(Vector2(p.x + 3, p.y - 3), 3, Color(0.8, 0.8, 0.75))
	# Top skull
	draw_circle(Vector2(p.x, p.y - 7), 3.5, Color(0.9, 0.9, 0.85))
	# Eyes for top skull
	draw_circle(Vector2(p.x - 1.5, p.y - 7.5), 1, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(p.x + 1.5, p.y - 7.5), 1, Color(0.1, 0.1, 0.1))

func _torch(p: Vector2, dir: int, seed_val: float) -> void:
	# Bracket
	draw_rect(Rect2(p.x + (dir * 2) - (2 if dir<0 else 0), p.y - 2, 2, 4), Color(0.4, 0.4, 0.4))
	# Stick
	draw_line(Vector2(p.x, p.y), Vector2(p.x + (dir * 6), p.y - 6), Color(0.4, 0.2, 0.1), 2.0)
	
	# Flame (flickers over time using Time.get_ticks_msec())
	var time = Time.get_ticks_msec() / 1000.0
	var flicker = sin(time * 10.0 + seed_val * 100.0) * 1.5
	var fx = p.x + (dir * 6)
	var fy = p.y - 8
	
	draw_circle(Vector2(fx, fy), 4.0 + flicker * 0.5, Color(1.0, 0.6, 0.1, 0.6)) # Outer glow
	draw_circle(Vector2(fx, fy), 2.5 + flicker * 0.3, Color(1.0, 0.8, 0.2))       # Inner flame
