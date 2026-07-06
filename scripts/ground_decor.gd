class_name GroundDecor
extends Node2D
## Grassland (World 1) / dusk-forest (World 2) background scenery — the
## Godot port of the JS platformer's PG-46 decor (PG-55). World-anchored
## decorative props drawn behind the tilemap (z_index -1), only over
## solid ground, and placed by a stable per-column hash so they never
## jitter or repeat. Purely visual: no nodes, no collision.

const TILE := 16
const STEP := 34.0

## "grassland" (World 1) or "forest" (World 2). Set by the level.
var kind := "grassland"
var width_px := 0.0
var ground_row := 0
## The level's TileMapLayer, for the solid-ground query.
var tiles: TileMapLayer


## Stable per-column pseudo-random in [0, 1). A clean 32-bit integer hash
## matching the JS decor's parameters (STEP, thresholds, prop mix) so the
## two ports read as the same scene; exact pixel positions differ.
func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = (h ^ (h >> 16)) & 0xFFFFFFFF
	return float(h) / 4294967296.0


func _solid_ground(tx: int) -> bool:
	return tiles != null and tiles.get_cell_source_id(Vector2i(tx, ground_row)) != -1


func _draw() -> void:
	var forest := kind == "forest"
	var ground_y := float(ground_row * TILE)
	var gx_max := int(width_px / STEP) + 2

	# Forest vines hang from the top of the level (independent of ground).
	if forest:
		for gx in range(0, gx_max):
			if _hash(gx, 999) < 0.72:
				continue
			var vx := gx * STEP + _hash(gx, 5) * STEP
			var vlen: float = 22.0 + floor(_hash(gx, 8) * 40.0)
			draw_line(Vector2(vx, 0.0), Vector2(vx, vlen), Color(0.23, 0.36, 0.23, 0.55), 2.0)
			draw_circle(Vector2(vx, vlen), 3.0, Color(0.27, 0.43, 0.27, 0.55))

	for gx in range(0, gx_max):
		if _hash(gx, 41 if forest else 17) < 0.45:
			continue  # sparse scatter
		var wx := gx * STEP + _hash(gx, 3) * (STEP - 10.0)
		if not _solid_ground(int(wx / TILE)):
			continue
		var pos := Vector2(wx, ground_y)
		var pick := _hash(gx, 71 if forest else 29)
		if forest:
			if pick < 0.42: _tall_tree(pos)
			elif pick < 0.68: _mushroom(pos)
			else: _log(pos)
		else:
			if pick < 0.4: _tree(pos)
			elif pick < 0.62: _bush(pos)
			elif pick < 0.82: _flowers(pos)
			else: _fence(pos)


# --- World 1 (grassland) props ---------------------------------------

func _tree(p: Vector2) -> void:
	draw_rect(Rect2(p.x - 2, p.y - 14, 4, 14), Color("#7a5230"))
	for leaf in [[0, -20, 9], [-6, -15, 7], [6, -15, 7]]:
		draw_circle(Vector2(p.x + leaf[0], p.y + leaf[1]), leaf[2], Color("#4a9e3a"))
	draw_circle(Vector2(p.x - 3, p.y - 22), 4, Color("#57b046"))


func _bush(p: Vector2) -> void:
	for b in [[-5, 5], [0, 7], [5, 5]]:
		draw_circle(Vector2(p.x + b[0], p.y - 4), b[1], Color("#5aa845"))


func _flowers(p: Vector2) -> void:
	var cols := [Color("#ff5d73"), Color("#ffd93b"), Color("#ff9ff3")]
	for i in 3:
		var fx := p.x + (i - 1) * 5.0
		draw_line(Vector2(fx, p.y), Vector2(fx, p.y - 8), Color("#3f8f38"), 1.0)
		draw_circle(Vector2(fx, p.y - 9), 2.0, cols[i])


func _fence(p: Vector2) -> void:
	var c := Color("#e8dcc0")
	draw_rect(Rect2(p.x - 7, p.y - 10, 2, 10), c)
	draw_rect(Rect2(p.x + 5, p.y - 10, 2, 10), c)
	draw_rect(Rect2(p.x - 8, p.y - 8, 15, 2), c)
	draw_rect(Rect2(p.x - 8, p.y - 4, 15, 2), c)


# --- World 2 (dusk forest) props -------------------------------------

func _tall_tree(p: Vector2) -> void:
	draw_rect(Rect2(p.x - 2, p.y - 22, 3, 22), Color("#3a2b1f"))
	var leaf := Color("#243a28")
	draw_colored_polygon(PackedVector2Array([
		Vector2(p.x - 8, p.y - 20), Vector2(p.x + 8, p.y - 20), Vector2(p.x, p.y - 36)]), leaf)
	draw_colored_polygon(PackedVector2Array([
		Vector2(p.x - 7, p.y - 27), Vector2(p.x + 7, p.y - 27), Vector2(p.x, p.y - 41)]), leaf)


func _mushroom(p: Vector2) -> void:
	draw_rect(Rect2(p.x - 1, p.y - 6, 3, 6), Color("#e6dcc8"))
	# Cap: an upward half-ellipse.
	var cap := PackedVector2Array()
	for i in range(9):
		var t := PI + PI * float(i) / 8.0
		cap.append(Vector2(p.x + cos(t) * 5.0, (p.y - 6) + sin(t) * 3.0))
	draw_colored_polygon(cap, Color("#b0455a"))
	draw_rect(Rect2(p.x - 2, p.y - 7, 1, 1), Color(1, 1, 1, 0.7))
	draw_rect(Rect2(p.x + 1, p.y - 8, 1, 1), Color(1, 1, 1, 0.7))


func _log(p: Vector2) -> void:
	draw_colored_polygon(_ellipse(Vector2(p.x, p.y - 3), 10.0, 3.5), Color("#5b3a24"))
	draw_colored_polygon(_ellipse(Vector2(p.x - 9, p.y - 3), 2.5, 3.0), Color("#3f2817"))
	draw_line(Vector2(p.x - 6, p.y - 4), Vector2(p.x + 8, p.y - 4), Color("#7a4e30"), 1.0)


func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(16):
		var t := TAU * float(i) / 16.0
		pts.append(center + Vector2(cos(t) * rx, sin(t) * ry))
	return pts
